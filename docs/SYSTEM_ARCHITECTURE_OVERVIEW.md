# GridTokenX Platform - System Architecture Overview

**Version:** 1.0  
**Last Updated:** 3 April 2026  
**Status:** Living Document

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Four-Layer Architecture](#2-four-layer-architecture)
3. [Microservices Architecture](#3-microservices-architecture)
4. [Smart Contract Architecture](#4-smart-contract-architecture)
5. [Dual-Path Data Flow](#5-dual-path-data-flow)
6. [P2P Trading Flow](#6-p2p-trading-flow)
7. [Token Economics](#7-token-economics)
8. [Data Layer](#8-data-layer)
9. [Infrastructure](#9-infrastructure)
10. [Performance Targets](#10-performance-targets)
11. [Technology Stack](#11-technology-stack)
12. [Key Design Principles](#12-key-design-principles)
13. [Security Architecture](#13-security-architecture)
14. [Observability](#14-observability)

---

## 1. System Overview

GridTokenX is a blockchain-powered Peer-to-Peer (P2P) energy trading platform built on Solana Private Proof-of-Authority (PoA). It enables decentralized energy trading between prosumers (producers) and consumers using smart contracts for trustless settlement.

### Core Concepts

| Concept | Description |
|---------|-------------|
| **Virtual Power Plants (VPP)** | Aggregated distributed energy resources |
| **Renewable Energy Certificates (RECs)** | Tokenized green energy credentials |
| **Recurring Orders (DCA)** | Automated periodic energy purchases |
| **Automated Market Clearing** | Real-time order matching and settlement |
| **Elastic Token Supply** | 1 GRX = 1 kWh verified renewable energy |

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     GRIDTOKENX PLATFORM                              │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│  Web Client  │          │  Mobile App  │          │  Smart Meter Simulator │
│  (Next.js)   │          │  (Future)    │          │  (IoT/Edge)  │
└──────┬───────┘          └──────┬───────┘          └──────┬───────┘
       │                         │                         │
       └─────────────────────────┼─────────────────────────┘
                                 │
       ┌─────────────────────────▼─────────────────────────┐
       │              API GATEWAY (Rust/Axum)               │
       │         Port 4000/4001 | O(1) Latency              │
       └─────────────────────────┬─────────────────────────┘
                                 │
       ┌─────────────────────────▼─────────────────────────┐
       │              BACKEND SERVICES                      │
       │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
       │  │ IAM Svc  │ │Trading   │ │ Oracle Bridge    │   │
       │  │ (gRPC)   │ │ Service  │ │ (IoT Gateway)    │   │
       │  │ :8080    │ │ :8092    │ │ :4010            │   │
       │  └──────────┘ └──────────┘ └──────────────────┘   │
       └─────────────────────────┬─────────────────────────┘
                                 │
       ┌─────────────────────────▼─────────────────────────┐
       │                  DATA LAYER                        │
       │  ┌──────────┐ ┌────────┐ ┌──────────┐ ┌────────┐ │
       │  │PostgreSQL│ │ Redis  │ │InfluxDB  │ │ Kafka  │ │
       │  │  :5434   │ │ :6379  │ │  :8086   │ │ :9092  │ │
       │  └──────────┘ └────────┘ └──────────┘ └────────┘ │
       └─────────────────────────┬─────────────────────────┘
                                 │
       ┌─────────────────────────▼─────────────────────────┐
       │           SOLANA PRIVATE PoA NETWORK               │
       │         7 Validators | 400ms Block Time            │
       │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
       │  │ Registry │ │ Energy   │ │ Trading Program  │   │
       │  │ Program  │ │ Token    │ │ (Order/Match)    │   │
       │  └──────────┘ └──────────┘ └──────────────────┘   │
       │  ┌──────────┐ ┌──────────┐                         │
       │  │ Oracle   │ │Governance│                         │
       │  │ Program  │ │ Program  │                         │
       │  └──────────┘ └──────────┘                         │
       └─────────────────────────────────────────────────────┘
```

---

## 2. Four-Layer Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    LAYERED ARCHITECTURE                        │
└────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                         │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐        │
│  │  Trading UI │   │  Explorer   │   │   Portal    │        │
│  │  (Next.js)  │   │  (Next.js)  │   │  (Next.js)  │        │
│  └─────────────┘   └─────────────┘   └─────────────┘        │
│  Responsibilities: UI rendering, form validation, API calls  │
└────────────────────────────────┬─────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                          │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐        │
│  │  API Gateway│   │  IAM Service│   │  Trading    │        │
│  │  (Axum)     │   │  (gRPC)     │   │  Service    │        │
│  └─────────────┘   └─────────────┘   └─────────────┘        │
│  ┌─────────────┐   ┌─────────────┐                           │
│  │Oracle Bridge│   │Smart Meter  │                           │
│  │(IoT Gateway)│   │Simulator    │                           │
│  └─────────────┘   └─────────────┘                           │
│  Responsibilities: Request handling, auth, business logic     │
└────────────────────────────────┬─────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────┐
│                      DATA LAYER                               │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐        │
│  │ PostgreSQL  │   │    Redis    │   │  InfluxDB   │        │
│  │  (RDBMS)    │   │   (Cache)   │   │ (Time-Series)        │
│  └─────────────┘   └─────────────┘   └─────────────┘        │
│  ┌─────────────┐   ┌─────────────┐                           │
│  │   Kafka     │   │  Mailpit    │                           │
│  │ (Messaging) │   │  (SMTP)     │                           │
│  └─────────────┘   └─────────────┘                           │
│  Responsibilities: Persistence, caching, streaming, telemetry │
└────────────────────────────────┬─────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────┐
│                   BLOCKCHAIN LAYER                            │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐        │
│  │   Anchor    │   │ SPL Token   │   │  System     │        │
│  │  Programs   │   │  Program    │   │  Programs   │        │
│  └─────────────┘   └─────────────┘   └─────────────┘        │
│  Responsibilities: Smart contracts, token management, state   │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Microservices Architecture

### Service Overview

| Service | Directory | Role | Tech Stack | Port |
|---------|-----------|------|------------|------|
| **API Gateway** | `gridtokenx-api/` | Primary Gateway & Orchestrator | Rust (Axum) | 4000/4001 |
| **IAM Service** | `gridtokenx-iam-service/` | Identity & Access Management | Rust (gRPC) | 8080/8090 |
| **Trading Service** | `gridtokenx-trading-service/` | High-frequency Trading Engine | Rust | 8092/8093 |
| **Oracle Bridge** | `gridtokenx-oracle-bridge/` | IoT/Smart Meter Gateway | Rust | 4010 |
| **Smart Meter Sim** | `gridtokenx-smartmeter-simulator/` | IoT Device Simulation | Python (FastAPI) | 8082 |

### Frontend Applications

| Application | Directory | Description | Port |
|-------------|-----------|-------------|------|
| **Trading UI** | `gridtokenx-trading/` | Main user trading interface | 3000 |
| **Explorer** | `gridtokenx-explorer/` | Blockchain explorer | 3001 |
| **Portal** | `gridtokenx-portal/` | Administrative dashboard | 3002 |
| **Simulator UI** | `gridtokenx-smartmeter-simulator/ui` | Smart meter control panel | 5173 |

### API Gateway Structure

```
gridtokenx-api/src/
├── main.rs           # Application entry point
├── startup.rs        # Service initialization & DI
├── lib.rs
├── api/              # HTTP route handlers
├── core/             # Configuration, errors, types
├── domain/           # Business logic
│   ├── trading/      # Trading domain (orders, matching, clearing)
│   ├── identity/     # User management, auth
│   ├── energy/       # Energy tokenization, RECs
│   └── events/       # Domain events
├── infra/            # Infrastructure adapters
│   ├── blockchain/   # Solana RPC, Anchor client
│   ├── database/     # SQLx repositories
│   ├── cache/        # Redis operations
│   └── messaging/    # Kafka producers/consumers
├── services/         # Application services
└── utils/            # Shared utilities
```

---

## 4. Smart Contract Architecture

### Program Overview

| Program | Purpose | Avg CU | Throughput |
|---------|---------|--------|------------|
| **Registry** | User/meter identity, reading storage, REC tracking | 6,000 | 19,350/sec |
| **Energy Token** | GRX token (1 kWh = 1 GRX), elastic supply | 18,000 | 6,665/sec |
| **Trading** | Order book, matching, escrow, settlement | 12,000 | 8,000/sec |
| **Oracle** | Meter data validation, BFT consensus | 8,000 | 15,000/sec |
| **Governance** | ERC certificates, PoA config, voting | 6,200 | 18,460/sec |

### Program Relationship Diagram

```
                        ┌─────────────────┐
                        │   GOVERNANCE    │
                        │   (ERC/PoA)     │
                        └────────┬────────┘
                                 │ Validates ERC for Trading
                                 ▼
┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│  REGISTRY    │─────────►│   TRADING    │◄─────────│   ORACLE     │
│  (Identity)  │          │  (Matching)  │          │  (Data Feed) │
└──────┬───────┘          └──────┬───────┘          └──────────────┘
       │                         │
       │ CPI: Mint Request       │ CPI: Token Transfer
       ▼                         ▼
        ┌──────────────────────────────┐
        │     ENERGY TOKEN (GRX)       │
        │   1 kWh = 1 GRX (Elastic)    │
        └──────────────────────────────┘
```

### PDA Account Hierarchy

```
Registry Program
├── Registry PDA          Seeds: ["registry"]
│   └── Global state (authority, counters)
├── User PDAs             Seeds: ["user", wallet_pubkey]
│   └── User profile, type, status
└── Meter PDAs            Seeds: ["meter", meter_id]
    └── Dual high-water marks (settled_net_gen, claimed_erc_gen)

Energy Token Program
├── Token Info PDA        Seeds: ["token_info_2022"]
│   └── Mint authority, total_supply
├── GRX Token Mint (Token-2022)
│   └── SPL Token-2022 with Metaplex metadata
└── User Token Accounts   Seeds: ["user_token_account", wallet]

Oracle Program
├── Oracle Data PDA       Seeds: ["oracle_data"]
│   └── Validation stats, clearing timestamps
├── Oracle Authority PDA  Seeds: ["oracle_authority"]
│   └── Primary oracle authority
└── Backup Oracle PDAs    Seeds: ["backup_oracle", pubkey]
    └── BFT consensus (max 3)

Trading Program
├── Market PDA            Seeds: ["market"]
│   └── Volume, price stats, fee config
├── Order PDAs            Seeds: ["order", user_pubkey, counter]
│   └── Order state, amount, price, status
└── Escrow PDAs           Seeds: ["escrow", order_id]
    └── Locked tokens for pending trades

Governance Program
├── PoA Config PDA        Seeds: ["poa_config"]
│   └── Authority, multi-sig config
└── ERC Certificate PDAs  Seeds: ["erc_certificate", cert_id]
    └── Energy amount, source, status
```

### Key Account Structures

#### MeterAccount (Registry Program)

```rust
pub struct MeterAccount {
    pub owner: Pubkey,                  // Owner's wallet address
    pub meter_id: [u8; 32],             // Meter serial number
    pub meter_type: MeterType,          // Residential, Commercial, Industrial
    pub is_verified: bool,              // Admin verified
    pub total_generated: u64,           // Lifetime generation (Wh)
    pub total_consumed: u64,            // Lifetime consumption (Wh)
    pub settled_net_generation: u64,    // Financial: already-minted amount
    pub claimed_erc_generation: u64,    // Financial: already-certified amount
    pub last_reading_at: i64,           // Last reading timestamp
    pub created_at: i64,                // Registration timestamp
}
```

**Dual High-Water Marks** prevent double-spending:
- `settled_net_generation`: Tracks GRX tokens minted
- `claimed_erc_generation`: Tracks ERC certificates issued

---

## 5. Dual-Path Data Flow

### Path Separation Rationale

| Requirement | Path A (Operational) | Path B (Settlement) |
|-------------|---------------------|---------------------|
| **Latency** | Sub-second (real-time dispatch) | 15-minute intervals (batch settlement) |
| **Data Granularity** | 15-second telemetry | 15-minute aggregated attestations |
| **Privacy** | Internal use (VPP optimization) | Public blockchain (ZK-proofs only) |
| **Destination** | VPP Platform (Redis/Kafka) | Solana PoA (verifier contract) |
| **Volume** | ~33,000 readings/sec (500k meters) | ~556 attestations/sec |

### Flow Diagram

```
┌──────────────────┐
│   Edge Devices   │
│ (Smart Meters,   │
│  EV Chargers,    │
│  BESS, PV)       │
└────────┬─────────┘
         │
┌────────▼────────┐
│  Oracle Bridge  │
│  (Port 4010)    │
└────────┬────────┘
         │
┌────────┴────────┐
│     Router      │
│ (Zone Assignment)│
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
PATH A      PATH B
(Telemetry) (Attestation)
    │         │
    ▼         ▼
VPP       ZK Aggregator
Platform  - Plonky2 Proofs
- Forecast  - Merkle Trees
- Dispatch  - Ed25519 Signing
    │         │
    ▼         ▼
Real-time  Solana PoA
Grid Ops   - REC Issuance
           - P2P Settlement
           - Token Minting
```

### Data Transformation Pipeline

| Stage | Input | Transformation | Output |
|-------|-------|----------------|--------|
| **Ingestion** | Device payload (JSON/Protobuf) | Protocol adapter parsing | Normalized `DeviceReading` |
| **Routing** | `DeviceReading` | Zone hash assignment | Redis stream key |
| **Processing** | Redis stream entry | Event deserialization | `MeterReadingPayload` |
| **Batching** | Individual readings | Accumulation (50 or 100ms) | `TelemetryBatchRequest` |
| **Forwarding** | Batch request | gRPC serialization | `TelemetryBatchResponse` |
| **Aggregation** | Per-reading data | 15-minute window sum | `WindowedStats` |
| **Attestation** | `WindowedStats` | Ed25519 signing | `AttestationRequest` |

---

## 6. P2P Trading Flow

### 4-Phase Trading Lifecycle

| Phase | Description | Latency |
|-------|-------------|---------|
| **1. Order Creation** | User submits buy/sell order with HMAC-SHA256 signature | ~350ms |
| **2. Order Matching** | Price-time priority matching engine (sharded by zone) | ~350ms |
| **3. On-Chain Settlement** | Atomic escrow via Anchor programs (3 transactions) | ~950ms |
| **4. Post-Settlement** | Balance updates, trade history, notifications | ~50ms |

**Total Flow Time: ~1.6 seconds**

### Order Creation Flow

```
User Submits Order
       │
       ▼
Validate HMAC-SHA256 Signature (< 5ms)
       │
       ▼
Validate Order Parameters (< 10ms)
       │
       ▼
Auto-Detect User Zone from Meter (5-20ms)
       │
       ▼
MarketClearingService: Check balance, lock funds (50-200ms)
       │
       ▼
Insert Order into Database (10-30ms)
       │
       ▼
Add to In-Memory Order Book (Sharded) (< 1ms)
       │
       ▼
Trigger Matching Engine (10-100ms)
       │
       ▼
Return Order Creation Response (~100-300ms total)
```

### Matching Algorithm

```
Price-Time Priority:
1. Best price gets priority
2. Same price → Earlier order gets priority
3. Match quantity = min(sell_qty, buy_qty)
4. Match price = (sell_price + buy_price) / 2  (Mid-price)

Example:
- SELL: 10 kWh @ 3.8 THB
- BUY:  8 kWh @ 4.0 THB
→ Match: 8 kWh @ 3.9 THB (mid-price)
→ SELL remaining: 2 kWh (still in order book)
→ BUY filled: 100% (order complete)
```

### P2P Cost Calculation

```
Cost Components:
1. Energy Cost = match_quantity × match_price
2. Wheeling Charge = distance_km × wheeling_rate × quantity
3. Loss Cost = energy_cost × loss_factor
4. Total Cost = energy_cost + wheeling_charge + loss_cost

Loss Allocation: Socialized model (Split 50/50 between buyer and seller)
```

### On-Chain Settlement Flow

```
1. Create Escrow PDA
   Seeds: ["escrow", order_id]

2. Lock Buyer's Funds → Escrow (Transaction #1)
   Program: Trading
   Instruction: lock_to_escrow
   Latency: 100-300ms

3. Transfer Energy Tokens: Seller → Buyer (Transaction #2)
   Program: Energy Token
   Instruction: transfer
   Latency: 100-300ms

4. Release Escrow → Seller (Transaction #3)
   Program: Trading
   Instruction: release_escrow
   Latency: 100-300ms

5. Update Database (status = 'completed')
   Latency: 10-30ms

6. Broadcast WebSocket Update
   Latency: < 10ms
```

---

## 7. Token Economics

### GRX Token Specification

| Property | Value |
|----------|-------|
| **Name** | GridTokenX Energy Token |
| **Symbol** | GRX |
| **Standard** | SPL Token-2022 |
| **Decimals** | 9 |
| **Supply** | Elastic (minted/burned based on energy) |
| **Mint Authority** | PDA (seeds: `["token_info_2022"]`) |
| **Freeze Authority** | None (freely transferable) |
| **Burn Authority** | Token holder + Energy Token Program |
| **REC Validators** | Max 10 authorized validators (governance-managed) |
| **Metaplex Support** | Yes (on-chain metadata) |

### Core Value Proposition

```
1 GRX Token = 1 kWh of Verified Renewable Energy
(Backed by Oracle-validated meter readings with BFT consensus)
```

### Token Value Components

```
              ┌─────────────────────────┐
              │     GRX TOKEN           │
              └───────────┬─────────────┘
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│  INTRINSIC    │ │   UTILITY     │ │   SCARCITY    │
│   VALUE       │ │   VALUE       │ │   VALUE       │
│               │ │               │ │               │
│ Backed by     │ │ Required for  │ │ Supply tied   │
│ BFT-validated │ │ P2P trading   │ │ to Oracle-    │
│ meter data    │ │ (4 modalities)│ │ verified      │
│ (3f+1 oracle  │ │               │ │ production    │
│ consensus)    │ │               │ │               │
└───────────────┘ └───────────────┘ └───────────────┘
```

### Elastic Supply Mechanism

```
Energy Production (Physical)          Token Supply (Digital)

┌─────────────────┐                   ┌─────────────────┐
│  Solar Panels   │                   │                 │
│  Production     │    MINT           │   Total         │
│  (kWh)          │ ────────────────► │   Supply        │
│                 │    1 kWh → 1 GRX  │                 │
└─────────────────┘                   └─────────────────┘

┌─────────────────┐                   ┌─────────────────┐
│  Energy Use     │                   │                 │
│  Consumption    │    BURN           │   Total         │
│  (kWh)          │ ────────────────► │   Supply        │
│                 │    (Optional)     │                 │
└─────────────────┘                   └─────────────────┘

Supply = Cumulative(Minted) - Cumulative(Burned)
```

### Token Flow Model

```
1. METER READING:   Oracle validates reading (8k CU, BFT consensus)
2. SETTLEMENT:      Registry calculates net generation (3.5k CU)
3. MINTING:         Registry → Energy Token CPI (18k CU mint)
                    ↳ PDA authority signs, 1:1 kWh:GRX ratio
4. ESCROW:          Prosumer Wallet → Trading Order Escrow (7.5k CU)
5. MATCHING:        Trading program matches orders (15k CU)
6. SETTLEMENT:      Trading → Token transfer (15.2k CU)
                    ↳ Atomic 6-way settlement for complex trades (28k CU)
7. ERC ISSUANCE:    Governance verifies unclaimed energy (11.2k CU w/ CPI)
                    ↳ Dual high-water mark check via Registry
8. BURN:            Token holder → Void (14k CU, optional tracking)
9. TRANSFER:        Wallet → Wallet (15.2k CU, peer transfer)
```

### Supply Growth Projection

| Quarter | Prosumers | Monthly Mint | Cumulative Supply |
|---------|-----------|--------------|-------------------|
| Year 1 Q1 | 100 | 50,000 GRX | 150,000 GRX |
| Year 1 Q2 | 125 | 62,500 GRX | 337,500 GRX |
| Year 1 Q3 | 156 | 78,000 GRX | 571,500 GRX |
| Year 1 Q4 | 195 | 97,500 GRX | 864,000 GRX |
| Year 2 Q1 | 244 | 122,000 GRX | 1,230,000 GRX |
| Year 2 Q2 | 305 | 152,500 GRX | 1,687,500 GRX |

**Assumptions:** 25% quarterly growth, 500 kWh/month average surplus per prosumer

---

## 8. Data Layer

### Database Architecture

| Database | Purpose | Port | Key Data |
|----------|---------|------|----------|
| **PostgreSQL** | Primary relational database | 5434 | Users, orders, trades, meters |
| **Redis** | Caching, session management, streams | 6379 | Order books, sessions, zone streams |
| **InfluxDB** | Time-series meter readings | 8086 | Smart meter telemetry data |
| **Kafka** | Event streaming, messaging | 9092 | Telemetry events, trade events |

### Replication Architecture

```
PostgreSQL Primary (:5434) ──────► PostgreSQL Replica (:5433)
       │                                    │
       ▼                                    ▼
   Writes                              Read-only
   Orders                              Queries
   Trades                              Analytics
   Users                               Reports

Redis Primary (:6379) ──────────► Redis Replica (:6380)
       │                                    │
       ▼                                    ▼
   Cache Writes                        Cache Reads
   Session State                       Order Book
   Zone Streams                        Rate Limiting
```

### Key Database Schemas

#### Trading Tables

```sql
-- Trading Orders
CREATE TABLE trading_orders (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    side VARCHAR(4) NOT NULL,           -- 'buy' or 'sell'
    order_type VARCHAR(10) NOT NULL,    -- 'limit' or 'market'
    energy_amount DECIMAL(18,9) NOT NULL,
    price_per_kwh DECIMAL(18,9) NOT NULL,
    zone_id INTEGER NOT NULL,
    meter_id UUID,
    status VARCHAR(20) DEFAULT 'pending',
    filled_amount DECIMAL(18,9) DEFAULT 0,
    locked_amount DECIMAL(18,9) DEFAULT 0,
    expiry_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Order Matches
CREATE TABLE order_matches (
    id UUID PRIMARY KEY,
    buy_order_id UUID NOT NULL,
    sell_order_id UUID NOT NULL,
    matched_quantity DECIMAL(18,9) NOT NULL,
    match_price DECIMAL(18,9) NOT NULL,
    total_value DECIMAL(18,9) NOT NULL,
    zone_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    settlement_tx_signature TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    settled_at TIMESTAMP
);

-- Trade History
CREATE TABLE trade_history (
    id UUID PRIMARY KEY,
    buyer_id UUID NOT NULL,
    seller_id UUID NOT NULL,
    match_id UUID NOT NULL,
    energy_amount DECIMAL(18,9) NOT NULL,
    price_per_kwh DECIMAL(18,9) NOT NULL,
    total_value DECIMAL(18,9) NOT NULL,
    zone_id INTEGER NOT NULL,
    settlement_signature TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 9. Infrastructure

### Infrastructure Services

| Service | Port | Purpose |
|---------|------|---------|
| **PostgreSQL** | 5434 | Primary relational database (replica: 5433) |
| **Redis** | 6379 | Caching layer (replica: 6380) |
| **InfluxDB** | 8086 | Time-series data for meter readings |
| **Kafka** | 9092 | Event streaming and messaging |
| **Kong** | 4000 | API Gateway management |
| **Prometheus** | 9090 | Metrics collection |
| **Grafana** | 3001 | Visualization dashboards |
| **SigNoz** | 3030 | OpenTelemetry-native observability |
| **Mailpit** | 8025 | Email testing (SMTP: 1025) |
| **Solana RPC** | 8899 | Local validator (WS: 8900) |

### Solana Private PoA Network

| Property | Value |
|----------|-------|
| **Consensus** | Proof-of-Authority (PoA) |
| **Validator Nodes** | 7 (minimum 4f+1 for BFT) |
| **Block Time** | 400ms |
| **Throughput** | 15,000 TPS capacity |
| **Infrastructure Cost** | ~$800/month |
| **Cost Reduction** | 95%+ vs public Solana |

### Docker Compose Architecture

```yaml
# Service Groups
services:
  # Core Backend
  - gridtokenx-api              # API Gateway
  - gridtokenx-iam-service      # Identity Management
  - gridtokenx-trading-service  # Trading Engine
  - gridtokenx-oracle-bridge    # IoT Gateway

  # Databases
  - postgres                    # Primary DB + Replica
  - redis                       # Cache + Replica
  - influxdb                    # Time-series
  - kafka                       # Event streaming

  # Blockchain
  - solana-validator            # Local PoA validator

  # Frontend
  - gridtokenx-trading          # Trading UI
  - gridtokenx-explorer         # Blockchain Explorer
  - gridtokenx-portal           # Admin Portal

  # Observability
  - prometheus                  # Metrics
  - grafana                     # Dashboards
  - signoz                      # OpenTelemetry
  - otel-collector              # OTLP collector
```

---

## 10. Performance Targets

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| API Response Time | < 50ms | ~30ms | ✅ |
| Blockchain Send Time | < 500ms | ~320ms | ✅ |
| Order Matching | < 500ms | ~350ms | ✅ |
| Settlement | < 1.5s | ~950ms | ✅ |
| Throughput | 1000+ req/s | 1000+ | ✅ |
| Oracle Throughput | 15,000 readings/sec | 15,000 | ✅ |
| Token Minting | 6,665 GRX/sec | 6,665 | ✅ |

### Latency Budget Breakdown

| Operation | Latency | Component |
|-----------|---------|-----------|
| JSON Parsing | ~0.5ms | API Gateway |
| HMAC Validation | ~0.1ms | API Gateway |
| Zone Routing | ~0.05ms | Oracle Bridge |
| Redis XADD | ~2ms | Oracle Bridge |
| Batch Forwarding | ~0.4ms (amortized) | Oracle Bridge |
| Order DB Insert | 10-30ms | API Gateway |
| Matching Engine | 10-100ms | Trading Service |
| Solana Transaction | 100-300ms | Blockchain Layer |

---

## 11. Technology Stack

### Backend (Rust)

| Component | Technology | Version |
|-----------|------------|---------|
| Web Framework | Axum | 0.8 |
| Database ORM | SQLx | 0.8 |
| Caching | Redis (Tokio-based) | 0.32 |
| gRPC | Tonic + ConnectRPC | 0.2.1 |
| Error Handling | anyhow | - |
| Validation | Validator | 0.19/0.20 |

### Blockchain (Solana)

| Component | Technology | Version |
|-----------|------------|---------|
| Smart Contracts | Anchor Framework | 0.32.1 |
| Token Standard | SPL Token | 8.0.0 |
| Token Extensions | SPL Token-2022 | - |
| SDK | solana-sdk | 2.3.1 |
| Client | anchor-client | - |

### Frontend

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Next.js | 16 |
| Language | TypeScript | - |
| Styling | TailwindCSS | - |
| Maps | Mapbox GL | - |
| Runtime | Bun | - |

### IoT/Simulation

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | FastAPI | - |
| Language | Python | - |
| Runtime | uv | - |

### Infrastructure

| Component | Technology | Version |
|-----------|------------|---------|
| Containerization | Docker | - |
| Orchestration | Docker Compose | - |
| API Gateway | Kong | - |
| Reverse Proxy | Nginx | - |

---

## 12. Key Design Principles

### 1. O(1) API Latency
- Blockchain operations are async/non-blocking
- Database persist-before-async pattern
- Immediate response to user, background processing for blockchain

### 2. Database-First Architecture
- All state persisted to PostgreSQL before blockchain submission
- Ensures durability even if blockchain transaction fails
- Enables reconciliation and audit trails

### 3. Event-Driven Architecture
- Kafka for telemetry and inter-service communication
- WebSocket for real-time user notifications
- Redis Streams for zone-based event processing

### 4. Hybrid Architecture
- Off-chain orchestration for complex business logic
- On-chain settlement for trustless execution
- Best of both worlds: flexibility + security

### 5. Security by Design
- **Password Hashing:** Argon2id (64MB memory, 3 iterations)
- **JWT Secret:** 256-bit random key
- **Wallet Encryption:** AES-256-GCM with secret sharding
- **Order Signatures:** HMAC-SHA256
- **Meter Attestations:** Ed25519 hardware signatures

### 6. Scalability
- **Zone-Based Sharding:** Orders distributed across shards by zone_id
- **Connection Pooling:** SQLx connection pools for database efficiency
- **Redis Caching:** Hot data cached for sub-millisecond access
- **Batch Processing:** 50 readings per 100ms batch for gRPC amortization

### 7. Dual High-Water Marks
- Prevents double-spending between token minting and ERC certification
- `settled_net_generation`: Tracks GRX tokens minted from energy
- `claimed_erc_generation`: Tracks ERC certificates issued for same energy

---

## 13. Security Architecture

### Authentication & Authorization

| Method | Use Case | Mechanism |
|--------|----------|-----------|
| **JWT (HS256)** | Standard user authentication | 24h expiry, role-based claims |
| **API Key (HMAC-SHA256)** | Smart meter/AMI authentication | Per-device key, signature validation |
| **Engineering Key** | Debugging/impersonation | Admin override capability |

### Role-Based Access Control (RBAC)

| Role | Permissions |
|------|-------------|
| **Admin** | Full system access, user management, governance |
| **User** | Trading, meter management, portfolio viewing |
| **AMI** | Meter reading submission, telemetry only |

### Cryptographic Security

```
Password Security:
├── Algorithm: Argon2id
├── Memory Cost: 64 MB
├── Iterations: 3
└── Parallelism: 1

Wallet Security:
├── Encryption: AES-256-GCM
├── Key Management: Secret sharding
└── Storage: Encrypted at rest

Order Security:
├── Signature: HMAC-SHA256
├── Message Format: "{side}:{amount}:{price}:{timestamp}"
└── Replay Protection: 5-minute timestamp window

Meter Attestation:
├── Hardware: ATECC608B Secure Element
├── Signature: Ed25519
├── Interval: 15-minute attestations
└── Validation: Oracle program (range, anomaly, monotonic)
```

### Privacy Compliance

- **PDPA Compliance:** Raw household data never reaches blockchain
- **ZK-Proofs:** Only aggregated, zero-knowledge proofs submitted on-chain
- **Data Minimization:** Only necessary data stored on-chain
- **Consent Management:** User-controlled data sharing via governance

---

## 14. Observability

### Monitoring Stack

| Tool | URL | Purpose | Credentials |
|------|-----|---------|-------------|
| **Grafana** | http://localhost:3001 | Visualization dashboards | admin / admin |
| **Prometheus** | http://localhost:9090 | Metrics collection | - |
| **SigNoz** | http://localhost:3030 | OpenTelemetry-native observability | - |
| **Mailpit** | http://localhost:8025 | Email testing | - |

### Metrics Endpoints

| Service | Endpoint |
|---------|----------|
| API Gateway | http://localhost:4001/metrics |
| PostgreSQL Exporter | http://localhost:9187 |
| Redis Exporter | http://localhost:9121 |
| Kafka Exporter | http://localhost:9308 |
| Node Exporter | http://localhost:9100 |
| cAdvisor | http://localhost:8080 |

### OpenTelemetry Integration

```bash
# Environment Variables for OTLP Export
OTEL_ENABLED=true
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_SERVICE_NAME=gridtokenx-api
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=development
OTEL_TRACES_SAMPLER=always_on
```

### Pre-Configured Dashboards

| Dashboard | Description |
|-----------|-------------|
| **Platform Overview** | Service health, requests, latency, errors |
| **API Performance** | Endpoint metrics, latency heatmaps, HTTP stats |
| **Trading Operations** | Orders, matching, settlement metrics |
| **Blockchain Monitor** | Solana transactions, program calls, RPC |
| **Infrastructure** | PostgreSQL, Redis, Kafka, containers |

### Alerting Rules

| Category | Alerts |
|----------|--------|
| **Service Health** | Service down, high error rate |
| **Performance** | High latency (P95/P99), slow endpoints |
| **Trading** | Trading errors, settlement failures, matching latency |
| **Blockchain** | Transaction failures, high priority fees, RPC errors |
| **Infrastructure** | DB connections, Redis memory, Kafka lag, container resources |
| **Security** | Auth failures, rate limiting triggered |

---

## Appendix A: Program IDs (Localnet)

| Program | Program ID |
|---------|------------|
| Registry | `FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c` |
| Energy Token | `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` |
| Trading | `69dGpKu9a8EZiZ7orgf6CoGj9DeQHHkHBF2exSr8na` |
| Oracle | `JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop` |
| Governance | `DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4` |

---

## Appendix B: Key File Paths

| Component | Path |
|-----------|------|
| API Gateway Entry | `gridtokenx-api/src/main.rs` |
| Startup & DI | `gridtokenx-api/src/startup.rs` |
| Configuration | `gridtokenx-api/src/core/config.rs` |
| Trading Domain | `gridtokenx-api/src/domain/trading/` |
| Blockchain Adapter | `gridtokenx-api/src/infra/blockchain/` |
| Reconciliation Service | `gridtokenx-api/src/services/reconciliation.rs` |
| Oracle Bridge Core | `gridtokenx-oracle-bridge/src/` |
| Data Flow Protocol | `gridtokenx-oracle-bridge/DATA_FLOW_AND_PROTOCOL.md` |
| Anchor Programs | `gridtokenx-anchor/programs/` |
| Database Migrations | `gridtokenx-api/migrations/` |

---

## Appendix C: Quick Start Commands

```bash
# Start all services
./scripts/app.sh start

# Check service health
./scripts/app.sh status

# Initialize blockchain & deploy programs
./scripts/app.sh init

# Register admin user
./scripts/app.sh register

# Seed database with test users
./scripts/app.sh seed

# Run all tests
just test

# Run migrations
just migrate

# View service logs
./scripts/app.sh logs api

# System diagnostics
./scripts/app.sh doctor
```

---

## Appendix D: Related Documentation

| Document | Location |
|----------|----------|
| User Registration Workflow | `docs/architecture/user-registration-workflow.md` |
| Data Flow: Simulator to Blockchain | `docs/architecture/data-flow-simulator-to-blockchain.md` |
| P2P Trading Flow | `docs/architecture/p2p-trading-flow.md` |
| Authentication & JWT Design | `docs/architecture/authentication-jwt-design.md` |
| Smart Contract Architecture | `docs/architecture/smart-contract-architecture.md` |
| Token Economics | `gridtokenx-anchor/docs/academic/05-token-economics.md` |
| System Architecture (Academic) | `gridtokenx-anchor/docs/academic/03-system-architecture.md` |
| Oracle Bridge Core | `gridtokenx-oracle-bridge/docs/core.md` |
| Business Model | `gridtokenx-anchor/docs/academic/02-business-model.md` |

---

**Last Reviewed:** 3 April 2026  
**Maintained By:** GridTokenX Engineering Team  
**Status:** Living Document - Updated as architecture evolves
