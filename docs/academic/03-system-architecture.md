# System Architecture

## GridTokenX Technical Architecture Documentation

> *April 2026 Edition - Production Architecture*  
> **Version:** 3.0.0

---

> **Related Documentation:**  
> - [Data Flow Diagrams](./04-data-flow-diagrams.md) - System DFD Level 0-2  
> - [Security Analysis](./07-security-analysis.md) - Threat model and security controls  
> - [Process Flows](./06-process-flows.md) - End-to-end process swimlanes  

---

## 1. Architecture Overview

### 1.1 Design Principles

GridTokenX architecture follows six core design principles:

| Principle | Description | Rationale |
|-----------|-------------|-----------|
| **Separation of Concerns** | Business logic isolated from blockchain code | Maintainability, testability, upgrade flexibility |
| **API Gateway Orchestration** | Gateway handles routing only (NO blockchain) | Security boundary, clear responsibility |
| **Service-Owned Blockchain** | Each microservice manages its own blockchain state | Decoupled deployments, fault isolation |
| **Event-Driven Communication** | Kafka, RabbitMQ, Redis for async messaging | Scalability, resilience, replayability |
| **Permissioned Access** | KYC verification required for network participation | Regulatory compliance, grid stability |
| **Defense in Depth** | Multiple security layers at each boundary | Zero-trust architecture |

### 1.2 System Context Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SYSTEM CONTEXT                               │
└─────────────────────────────────────────────────────────────────────┘

    Prosumers           Consumers           Grid Operators       Regulators
    (Solar)             (Buyers)            (B2B)                (Audit)
       │                   │                    │                   │
       │    HTTPS/WSS      │    HTTPS/WSS       │    REST API       │    REST API
       ▼                   ▼                    ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                        GRIDTOKENX PLATFORM                              │
│                                                                         │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐              │
│  │  Trading UI   │  │   Explorer    │  │    Portal     │              │
│  │  (Next.js)    │  │  (Next.js)    │  │  (Next.js)    │              │
│  │  :3000        │  │  :3001        │  │  :3002        │              │
│  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘              │
│          │                  │                  │                       │
│          └──────────────────┼──────────────────┘                       │
│                             │ HTTPS                                   │
│                             ▼                                         │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                    API SERVICES                                │    │
│  │              (gridtokenx-api :4000)                           │    │
│  │         Orchestration & Routing (NO Blockchain)               │    │
│  └───┬──────────────┬──────────────┬────────────────────────────┘    │
│      │ gRPC         │ gRPC         │ gRPC                            │
│      ▼              ▼              ▼                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                          │
│  │   IAM    │  │ Trading  │  │  Oracle  │                          │
│  │ Service  │  │ Service  │  │  Bridge  │                          │
│  │ :50052   │  │ :50053   │  │ :4010    │                          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                          │
│       │              │            │                                   │
│       └──────────────┴────────────┘                                   │
│                      │ Solana RPC                                     │
│                      ▼                                                │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              SOLANA BLOCKCHAIN (PoA)                         │    │
│  │  Programs: Registry, Energy Token, Trading, Oracle, Gov      │    │
│  │  Validator: :8899 (RPC), :8900 (WS)                         │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────┘
          │                    │                    │
          ▼                    ▼                    ▼
    Smart Meters         PostgreSQL           External APIs
    (Simulation)         :5434                (Price feeds, etc.)
```

---

## 2. Layered Architecture

### 2.1 Four-Layer Model

```
┌────────────────────────────────────────────────────────────┐
│                 LAYERED ARCHITECTURE                        │
└────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  LAYER 1: PRESENTATION                                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐         │
│  │ Trading UI │  │ Explorer   │  │ Portal     │         │
│  │ (Next.js)  │  │ (Next.js)  │  │ (Next.js)  │         │
│  └────────────┘  └────────────┘  └────────────┘         │
│  Responsibility: User interaction, state management       │
└──────────────────────────┬───────────────────────────────┘
                           │ HTTPS/WSS
                           ▼
┌──────────────────────────────────────────────────────────┐
│  LAYER 2: ORCHESTRATION                                   │
│  ┌──────────────────────────────────────────────────┐   │
│  │           API Gateway (Axum, :4000)               │   │
│  │  • JWT validation    • Rate limiting             │   │
│  │  • Request routing   • Response aggregation      │   │
│  │  • Metrics           • NO blockchain code        │   │
│  └──────────────────────────────────────────────────┘   │
│  Responsibility: Request handling, routing, orchestration│
└──────────────────────────┬───────────────────────────────┘
                           │ gRPC (ConnectRPC)
                           ▼
┌──────────────────────────────────────────────────────────┐
│  LAYER 3: BUSINESS SERVICES                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │   IAM    │  │ Trading  │  │  Oracle  │              │
│  │ Service  │  │ Service  │  │ Bridge   │              │
│  │ :50052   │  │ :50053   │  │ :4010    │              │
│  └──────────┘  └──────────┘  └──────────┘              │
│  Responsibility: Business logic, blockchain interaction  │
└──────────────────────────┬───────────────────────────────┘
                           │ Solana RPC
                           ▼
┌──────────────────────────────────────────────────────────┐
│  LAYER 4: BLOCKCHAIN                                      │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Solana Validator (PoA Consensus)                │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │    │
│  │  │ Registry │  │ Energy   │  │ Trading  │      │    │
│  │  │ Program  │  │ Token    │  │ Program  │      │    │
│  │  └──────────┘  └──────────┘  └──────────┘      │    │
│  │  ┌──────────┐  ┌──────────┐                    │    │
│  │  │ Oracle   │  │Governance│                    │    │
│  │  │ Program  │  │ Program  │                    │    │
│  │  └──────────┘  └──────────┘                    │    │
│  └─────────────────────────────────────────────────┘    │
│  Responsibility: Trustless settlement, token transfers   │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Microservices Architecture

### 3.1 Service Map

```
┌────────────────────────────────────────────────────────────┐
│                   MICROSERVICE BOUNDARIES                   │
└────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  API SERVICES (gridtokenx-api)                             │
│  Port: 4000 (HTTP) / 4001 (Metrics)                      │
│  Technology: Rust + Axum + ConnectRPC                    │
│  Database: PostgreSQL (user cache, sessions)             │
│                                                          │
│  Responsibilities:                                        │
│  ├─ HTTP request/response handling                       │
│  ├─ JWT token validation                                 │
│  ├─ Route to microservices via gRPC                      │
│  ├─ Aggregate responses                                  │
│  ├─ Rate limiting and throttling                         │
│  └─ Metrics collection (Prometheus)                      │
│                                                          │
│  DOES NOT:                                                │
│  ✗ Sign blockchain transactions                          │
│  ✗ Hold private keys                                     │
│  ✗ Call Solana RPC directly                              │
└──────────────────────────────────────────────────────────┘
         │                    │                    │
         │ gRPC               │ gRPC               │ gRPC
         ▼                    ▼                    ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  IAM SERVICE     │ │ TRADING SERVICE  │ │ ORACLE BRIDGE    │
│  Port: 50052     │ │ Port: 50053      │ │ Port: 4010/50051 │
│                  │ │                  │ │                  │
│  Blockchain: YES │ │ Blockchain: YES  │ │ Blockchain: NO   │
│  ├─ Registry     │ │ ├─ Trading       │ │ (signs for API)  │
│  ├─ Governance   │ │ └─ Energy Token  │ │                  │
│                  │ │                  │ │ Responsibilities:│
│  Responsibilities:│ │ Responsibilities:│ │ ├─ Ed25519 verify│
│  ├─ User identity│ │ ├─ Order book    │ │ ├─ Aggregate     │
│  ├─ KYC flow     │ │ ├─ Matching      │ │ │   telemetry    │
│  ├─ Wallet mgmt  │ │ ├─ Settlement    │ │ ├─ Sign payloads │
│  └─ On-chain reg │ │ └─ Trade records │ │ └─ Submit to     │
│                  │ │                  │ │   Oracle Svc     │
│  Messaging:      │ │ Messaging:       │ │                  │
│  ├─ Kafka        │ │ ├─ Kafka         │ │ Messaging:       │
│  └─ RabbitMQ     │ │ └─ RabbitMQ      │ │ ├─ Kafka         │
│                  │ │                  │ │ └─ RabbitMQ      │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

### 3.2 Service Responsibility Matrix

| Operation | API Gateway | IAM Service | Trading Service | Oracle Bridge |
|-----------|:-----------:|:-----------:|:---------------:|:-------------:|
| User Registration | Route | ✅ Execute | — | — |
| KYC Verification | Route | ✅ Execute | — | — |
| Wallet Creation | Route | ✅ Execute | — | — |
| On-chain User Reg | — | ✅ Execute | — | — |
| Order Creation | Route | — | ✅ Execute | — |
| Order Matching | — | — | ✅ Execute | — |
| Trade Settlement | — | — | ✅ Execute | — |
| Meter Reading Submit | Route | — | — | ✅ Validate |
| Price Feed Update | — | — | — | ✅ Execute |
| ERC Certificate Issue | Route | — | — | ✅ Via Oracle Svc |
| Blockchain TX | ✗ NO | ✅ YES | ✅ YES | ✗ NO (signs only) |

### 3.3 API Gateway Internals

```
┌────────────────────────────────────────────────────────────┐
│                API SERVICES INTERNALS                        │
└────────────────────────────────────────────────────────────┘

Incoming HTTP Request
        │
        ▼
┌───────────────────┐
│  Middleware Stack  │
│  ┌─────────────┐  │
│  │ CORS        │  │
│  ├─────────────┤  │
│  │ Rate Limit  │  │
│  ├─────────────┤  │
│  │ JWT Auth    │  │
│  ├─────────────┤  │
│  │ Tracing     │  │
│  └─────────────┘  │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│  Route Handler    │
│  ┌─────────────┐  │
│  │ Validate    │  │
│  │ Request     │  │
│  ├─────────────┤  │
│  │ Select      │  │
│  │ gRPC Client │  │
│  ├─────────────┤  │
│  │ Forward     │  │
│  │ Request     │  │
│  ├─────────────┤  │
│  │ Aggregate   │  │
│  │ Response    │  │
│  └─────────────┘  │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│  gRPC Connection   │
│  Pool (8 conns)    │
│  ┌─────────────┐  │
│  │ Round-Robin │  │
│  │ Load Balance│  │
│  └─────────────┘  │
└───────────────────┘
```

**gRPC Client Configuration:**

```rust
// Connection pool per microservice
pub struct GrpcClientConfig {
    pub max_connections: usize,        // Default: 8
    pub connection_timeout: Duration,  // Default: 5s
    pub request_timeout: Duration,     // Default: 30s
    pub retry_attempts: u32,          // Default: 3
    pub retry_backoff_ms: u64,        // Default: 100ms
}
```

---

## 4. Smart Contract Architecture

### 4.1 Program Relationship Diagram

```
┌────────────────────────────────────────────────────────────┐
│              SMART CONTRACT PROGRAM RELATIONSHIPS           │
└────────────────────────────────────────────────────────────┘

                        ┌─────────────────────┐
                        │   GOVERNANCE         │
                        │   PROGRAM            │
                        │                      │
                        │ • ERC Certificates   │
                        │ • PoA Config         │
                        │ • Voting             │
                        └──────────┬───────────┘
                                   │
                                   │ Validates ERC for trading
                                   ▼
┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
│   REGISTRY          │   │    TRADING          │   │   ORACLE            │
│   PROGRAM           │   │    PROGRAM          │   │   PROGRAM           │
│                     │   │                     │   │                     │
│ • User Registration │   │ • Order Management  │   │ • Price Feeds       │
│ • Meter Management  │──►│ • Order Matching    │◄──│ • Rate Updates      │
│ • Reading Storage   │   │ • Settlement        │   │ • External Data     │
│ • Balance Settle    │   │ • Escrow Control    │   │                     │
└──────────┬──────────┘   └──────────┬──────────┘   └─────────────────────┘
           │                         │
           │ CPI: Mint Request       │ CPI: Token Transfer
           ▼                         ▼
        ┌───────────────────────────────────────────────┐
        │              ENERGY TOKEN PROGRAM             │
        │                                               │
        │   • GRID Token-2022 Mint                     │
        │   • Token Transfers                           │
        │   • Burn Operations                           │
        │   • REC Validator Management                  │
        │                                               │
        │   Uses SPL Token-2022 (system program)        │
        └───────────────────────────────────────────────┘


Legend:
──►  CPI (Cross-Program Invocation)
──   Data/State Dependency
```

### 4.2 Program Specifications

| Program | ID | Purpose | Key Instructions | Avg CU | Throughput |
|---------|----|---------|-----------------|---------|-----------|
| **Registry** | `FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c` | Identity & Device Mgmt | `register_user` (5.5k), `register_meter` (6.2k), `settle_energy` (12k w/ CPI) | 6,000 CU | 19,350/sec |
| **Energy Token** | `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` | GRX Token-2022 Wrapper | `mint_tokens_direct` (18k), `burn_tokens` (14k), `transfer_tokens` (15.2k) | 18,000 CU | 6,665/sec |
| **Oracle** | `JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop` | Meter Data Validation | `submit_meter_reading` (8k), `trigger_market_clearing` (2.5k) | 8,000 CU | 15,000/sec |
| **Trading** | `69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na` | Multi-Modal Marketplace | `create_buy_order` (7.2k), `match_orders` (15k), `atomic_settlement` (28k) | 12,000 CU | 8,000/sec |
| **Governance** | `DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4` | ERC Certificates & PoA | `issue_erc` (6.5k), `validate_erc` (4.8k), `issue_erc_with_verification` (11.2k w/ CPI) | 6,200 CU | 18,460/sec |

**Performance Notes:**
- All CU values measured from January 2026 comprehensive benchmarks
- Throughput = (48M CU/block × 2.5 blocks/sec) ÷ Avg CU
- CPI instructions include cross-program overhead (~3-6k CU)
- Post-optimization average: 12,000 CU/tx (45.5% reduction from 22k CU)

### 4.3 Account Model (PDA Structure)

```
Registry Program (FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c)
├── Registry PDA
│   Seeds: ["registry"]
│   └── Global state (authority, counters, total_users, total_meters)
│
├── User PDAs
│   Seeds: ["user", wallet_pubkey]
│   └── User profile, type, status, registration timestamp
│
└── Meter PDAs
    Seeds: ["meter", meter_id]
    └── total_production, total_consumption, settled_net_generation,
        claimed_erc_generation (dual high-water marks), last_reading_at

Energy Token Program (n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk)
├── Token Info PDA (Mint Authority)
│   Seeds: ["token_info_2022"]
│   └── Controls token minting, stores registry_program_id,
│       total_supply, rec_validator list (max 10)
│
├── GRX Token Mint (Token-2022)
│   └── SPL Token-2022 mint account with Metaplex metadata
│
└── User Token Account PDAs
    Seeds: ["user_token_account", wallet_pubkey]
    └── Associated token accounts for each user

Oracle Program (JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop)
├── Oracle Data PDA
│   Seeds: ["oracle_data"]
│   └── total_valid_readings, total_rejected_readings,
│       last_clearing_timestamp, is_active
│
├── Oracle Authority PDA
│   Seeds: ["oracle_authority"]
│   └── Primary oracle authority (API gateway wallet)
│
└── Backup Oracle PDAs
    Seeds: ["backup_oracle", oracle_pubkey]
    └── Backup oracle list for BFT consensus (max 3)

Trading Program (69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na)
├── Market PDA
│   Seeds: ["market"]
│   └── total_orders, matched_orders, total_volume,
│       volume_weighted_price (avg), last_clearing_price
│
├── Order PDAs
│   Seeds: ["order", user_pubkey, order_counter]
│   └── order_type (Bilateral/CDA),
│       amount, filled_amount, price_per_kwh, status,
│       erc_certificate_id (optional), created_at, expires_at
│
└── Escrow PDAs
    Seeds: ["escrow", order_id]
    └── Locked GRX tokens for pending orders

Governance Program (DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4)
├── PoA Config PDA
│   Seeds: ["poa_config"]
│   └── authority, pending_authority, transfer_initiated_at,
│       required_signers (multi-sig)
│
└── ERC Certificate PDAs
    Seeds: ["erc_certificate", certificate_id]
    └── energy_amount, energy_source (Solar/Wind/Hydro),
        status (Pending/Active/Retired/Revoked),
        issued_at, validated_at, retired_at
```

---

## 5. Messaging Architecture

### 5.1 Hybrid Messaging Pattern

```
┌────────────────────────────────────────────────────────────┐
│               HYBRID MESSAGING LAYER                        │
└────────────────────────────────────────────────────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Kafka      │  │    Redis     │  │   RabbitMQ   │
│   :9092      │  │    :6379     │  │   :5672      │
│              │  │              │  │   Mgmt:15672 │
├──────────────┤  ├──────────────┤  ├──────────────┤
│ Event        │  │ Cache +      │  │ Task Queues  │
│ Streaming    │  │ Real-time    │  │ + RPC        │
│              │  │              │  │              │
│ • Orders     │  │ • WebSocket  │  │ • Email      │
│ • Trades     │  │   broadcast  │  │   notifications│
│ • Meter      │  │ • Session    │  │ • Settlement │
│   readings   │  │   cache      │  │   retries    │
│ • Audit log  │  │ • Market data│  │ • Batch jobs │
└──────────────┘  └──────────────┘  └──────────────┘
     │                 │                 │
     └─────────────────┼─────────────────┘
                       │
            Event Routing Logic:
            ├─ Replayable events → Kafka
            ├─ Real-time updates → Redis
            └─ Guaranteed delivery → RabbitMQ
```

### 5.2 Messaging Decision Matrix

| Use Case | Technology | Pattern | Why |
|----------|-----------|---------|-----|
| Order events | Kafka | Event sourcing | Multiple consumers, replayable |
| Trade confirmations | Kafka | Event sourcing | Audit trail, compliance |
| Meter reading stream | Kafka | High-throughput stream | Partitioning, ordering |
| WebSocket broadcasts | Redis | Pub/Sub | Ultra-low latency (<10ms) |
| Session cache | Redis | Hash storage | Sub-millisecond access |
| Market data feed | Redis | Pub/Sub | Real-time price updates |
| Email notifications | RabbitMQ | Task queue | Guaranteed delivery, DLQ |
| Settlement retries | RabbitMQ | Priority queue | Exponential backoff |
| Batch jobs | RabbitMQ | Work queue | Fair dispatch, prefetch |

---

## 6. Data Architecture

### 6.1 Database Schema Overview

```
PostgreSQL (:5434)
├── users
│   └── id, email, password_hash, kyc_status, wallet_address
├── orders
│   └── id, user_id, order_type, price, quantity, status, onchain_sig
├── trades
│   └── id, buy_order_id, sell_order_id, quantity, price, tx_signature
├── meter_readings
│   └── id, meter_id, produced, consumed, timestamp, signature_hash
└── settlements
    └── id, meter_id, amount, tx_signature, settled_at

Redis (:6379)
├── Session cache (user sessions, JWT blacklist)
├── Real-time data (order book snapshot, last price)
└── Rate limiting (sliding window counters)

InfluxDB (:8086)
└── Meter reading time-series (high-frequency telemetry)
```

### 6.2 Blockchain State vs Database State

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| User identity | Database + Blockchain PDA | Fast queries, on-chain verification |
| Order book | Database (active) + Blockchain PDA (escrow) | Performance + security |
| Trade records | Database (history) + Blockchain events | Query efficiency + immutability |
| Meter readings | Database + InfluxDB + Blockchain PDA | Time-series + settlement state |
| Token balances | Blockchain (source of truth) + Database cache | On-chain is authoritative |
| ERC certificates | Blockchain PDA (lifecycle) + Database metadata | Immutable status + queries |

---

## 7. Integration Architecture

### 7.1 External System Integration

```
┌────────────────────────────────────────────────────────────┐
│                INTEGRATION ARCHITECTURE                      │
└────────────────────────────────────────────────────────────┘

                    ┌─────────────────────┐
                    │   GRIDTOKENX        │
                    │   CORE PLATFORM     │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  SMART METER  │     │  THAI BAHT    │     │    GRID       │
│  SIMULATOR    │     │    CHAIN      │     │  OPERATORS    │
│               │     │               │     │               │
│ Protocol:     │     │ Protocol:     │     │ Protocol:     │
│ HTTPS/Ed25519 │     │ Cross-chain   │     │ REST API      │
│               │     │ Bridge        │     │               │
└───────┬───────┘     └───────┬───────┘     └───────┬───────┘
        │                     │                     │
        ▼                     ▼                     ▼
  Reading Flow:         Payment Flow:         Data Flow:
  Meter → Sign →        User sends THB →      Platform reports
  HTTP POST →           Bridge locks →        generation →
  API validates →       Proof to Solana →     Grid operator
  Store + Mint          Release tokens        receives data
```

### 7.2 Smart Meter Integration Protocol

```
Smart Meter Device                    Oracle Bridge                    Blockchain
────────────────                      ─────────────                    ──────────

┌────────────────┐
│ 1. Generate    │
│    Reading     │
│    {meter_id,  │
│     prod,      │
│     cons,      │
│     ts}        │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ 2. Sign with   │
│    Ed25519     │
│    Private Key │
└───────┬────────┘
        │
        │  HTTP POST /api/meters/submit
        │  {data, signature, public_key}
        ▼
                               ┌────────────────┐
                               │ 3. Verify      │
                               │    Signature   │
                               │ (< 10ms)       │
                               └───────┬────────┘
                                       │
                                       ▼
                               ┌────────────────┐
                               │ 4. Check Meter │
                               │    Registered  │
                               └───────┬────────┘
                                       │
                                       ▼
                               ┌────────────────┐
                               │ 5. Validate    │
                               │    Reading     │
                               │ • Timestamp ≤5s│
                               │ • Rate limit   │
                               │ • No duplicates│
                               └───────┬────────┘
                                       │
                                       ▼
                               ┌────────────────┐
                               │ 6. Forward to  │
                               │    Oracle Svc  │
                               └───────┬────────┘
                                       │
                                       ▼
                                                              ┌────────────────┐
                                                              │ 7. Submit to  │
                                                              │    Blockchain  │
                                                              │    Oracle Prg  │
                                                              └───────┬────────┘
                                                                      │
                                                                      ▼
                                                              ┌────────────────┐
                                                              │ 8. Update     │
                                                              │    Meter PDA   │
                                                              └───────┬────────┘
                                                                      │
                                       ┌────────────────┐             │
                                       │ 9. Return TX   │◄────────────┘
                                       │    Signature   │
                                       └───────┬────────┘
                                               │
        ┌────────────────┐                     │
        │ 10. 200 OK +   │◄────────────────────┘
        │     TX Sig     │
        └────────────────┘
```

---

## 8. Deployment Architecture

### 8.1 Infrastructure Overview

```
┌────────────────────────────────────────────────────────────┐
│               DEPLOYMENT ARCHITECTURE                       │
└────────────────────────────────────────────────────────────┘

                    Production Environment
                    ┌─────────────────────┐
                    │   Load Balancer     │
                    │   (nginx/HAProxy)   │
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
                    ▼                     ▼
          ┌───────────────┐     ┌───────────────┐
          │  API Gateway  │     │  API Gateway  │
          │  Instance 1   │     │  Instance 2   │
          └───────┬───────┘     └───────┬───────┘
                  │                     │
                  └──────────┬──────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
     ┌────────────┐ ┌────────────┐ ┌────────────┐
     │    IAM     │ │  Trading   │ │   Oracle   │
     │  Service   │ │  Service   │ │   Bridge   │
     │ (2 instances)│ (2 instances)│ (2 instances)│
     └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
           │              │              │
           └──────────────┼──────────────┘
                          │
               ┌──────────┴──────────┐
               │                     │
               ▼                     ▼
     ┌───────────────┐     ┌───────────────┐
     │  PostgreSQL   │     │    Redis      │
     │  (Primary +   │     │  (Primary +   │
     │   Replica)    │     │   Replica)    │
     └───────────────┘     └───────────────┘

     ┌───────────────┐     ┌───────────────┐
     │    Kafka      │     │   RabbitMQ    │
     │  (3 brokers)  │     │  (2 nodes)    │
     └───────────────┘     └───────────────┘

     ┌───────────────────────────────────────────┐
     │        Solana Validators (PoA)            │
     │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐       │
     │  │ V1  │ │ V2  │ │ V3  │ │ V4  │ ...   │
     │  └─────┘ └─────┘ └─────┘ └─────┘       │
     │  (7 validators for BFT consensus)        │
     └───────────────────────────────────────────┘
```

### 8.2 Resource Requirements

| Component | CPU | Memory | Storage | Network |
|-----------|-----|--------|---------|---------|
| API Gateway (per instance) | 2 cores | 4 GB | 20 GB | 1 Gbps |
| IAM Service (per instance) | 4 cores | 8 GB | 50 GB | 1 Gbps |
| Trading Service (per instance) | 4 cores | 8 GB | 50 GB | 1 Gbps |
| Oracle Bridge (per instance) | 2 cores | 4 GB | 20 GB | 1 Gbps |
| PostgreSQL (Primary) | 8 cores | 32 GB | 500 GB SSD | 10 Gbps |
| Redis (Primary) | 4 cores | 16 GB | 100 GB | 10 Gbps |
| Kafka (per broker) | 8 cores | 16 GB | 1 TB SSD | 10 Gbps |
| Solana Validator (PoA) | 16 cores | 128 GB | 2 TB NVMe | 10 Gbps |

**Total Infrastructure (Production):**
- Compute: ~200 CPU cores, ~800 GB RAM
- Storage: ~4 TB (SSD/NVMe)
- Network: 10 Gbps backbone
- Estimated cost: ~$800/month (PoA validators + supporting infra)

---

## 9. Observability

### 9.1 Monitoring Stack

```
┌────────────────────────────────────────────────────────────┐
│                   OBSERVABILITY STACK                        │
└────────────────────────────────────────────────────────────┘

Metrics                    Logs                       Traces
┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│  Prometheus  │          │  Loki/ELK    │          │  SigNoz      │
│  :9090       │          │  (TBD)       │          │  :3030       │
│              │          │              │          │              │
│  • Service   │          │  • App logs  │          │  • Distributed│
│    metrics   │          │  • Access    │          │    traces    │
│  • Business │          │  • Error     │          │  • Span       │
│    KPIs     │          │  • Audit     │          │    analytics │
│  • Infra    │          │              │          │  • Error     │
│    metrics  │          │              │          │    tracking  │
└──────┬───────┘          └──────┬───────┘          └──────┬───────┘
       │                         │                         │
       └─────────────────────────┼─────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────┐
                    │     Grafana        │
                    │     :3001          │
                    │                    │
                    │  • Dashboards      │
                    │  • Alerts          │
                    │  • Reporting       │
                    └────────────────────┘
```

### 9.2 Key Metrics

**Service-Level Metrics (per service):**
- Request rate (req/s)
- Error rate (5xx responses)
- Latency (p50, p95, p99)
- gRPC call duration
- Database query duration
- Cache hit rate

**Business Metrics:**
- Active users (DAU, MAU)
- Order book depth
- Trade volume (hourly, daily)
- Token minting rate
- Settlement success rate

**Infrastructure Metrics:**
- CPU/Memory utilization
- Disk I/O (PostgreSQL, Kafka)
- Network throughput
- Solana validator health (slot progression, epoch progress)

---

**Document Information:**

| Field | Value |
|-------|-------|
| **Version** | 3.0.0 |
| **Last Updated** | April 2026 |
| **Status** | Production-Ready |
| **Authors** | GridTokenX Research Team |
