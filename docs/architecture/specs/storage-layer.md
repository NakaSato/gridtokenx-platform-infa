# Storage Layer: On-Chain & Off-Chain State Management

**Version:** 2.0 (Diagram-Focused)  
**Last Updated:** April 6, 2026  
**Status:** ✅ Implemented (Dual-Write Pattern)

---

## Overview

GridTokenX implements a **hybrid storage architecture** combining Solana's on-chain state with off-chain databases to achieve optimal balance between **trustlessness** and **performance**.

This document explains what data is stored where, how layers synchronize, and design patterns enabling scalable P2P energy trading.

---

## 1. Storage Architecture Overview

### 1.1 Three-Tier Storage Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│           TIER 1: ON-CHAIN (SOLANA)                         │
│                                                              │
│  Purpose: Canonical, immutable, financial state             │
│                                                              │
│  What's stored:                                              │
│  • User & meter identity (PDAs)                             │
│  • Orders & trades (escrow, settlement records)             │
│  • Token balances (SPL Token accounts)                      │
│  • ERC certificates (energy provenance)                     │
│  • Market state (current epoch, price history)              │
│                                                              │
│  Trust:      ✅ Decentralized consensus                     │
│  Cost:       💰💰💰 High (rent + transaction fees)           │
│  Speed:      ⚡ ~400ms finality                              │
│  Capacity:   ~1-10 MB per user                              │
└─────────────────────────────────────────────────────────────┘
                          ↓ Synchronization
┌─────────────────────────────────────────────────────────────┐
│        TIER 2: OFF-CHAIN (POSTGRESQL)                       │
│                                                              │
│  Purpose: Transactional data, indexing, history             │
│                                                              │
│  What's stored:                                              │
│  • User profiles (email, password, preferences)             │
│  • Order history (complete lifecycle)                       │
│  • Trade logs & settlements                                 │
│  • Market epochs & clearing prices                          │
│  • Meter readings (relational queries)                      │
│  • Blockchain events (indexed from on-chain logs)           │
│  • Audit trails & compliance data                           │
│                                                              │
│  Trust:      ⚠️ Centralized (verifiable via on-chain)       │
│  Cost:       💰 Low (commodity database)                    │
│  Speed:      ⚡⚡ ~10-50ms queries                            │
│  Capacity:   TB scale (unlimited growth)                    │
└─────────────────────────────────────────────────────────────┘
                          ↓ Time-series data
┌─────────────────────────────────────────────────────────────┐
│        TIER 3: OFF-CHAIN (REDIS / CACHE)                    │
│                                                              │
│  Purpose: Real-time access, event bus, caching              │
│                                                              │
│  What's stored:                                              │
│  • Market data cache (current epoch, stats)                 │
│  • Order book snapshots                                     │
│  • WebSocket pub/sub channels                               │
│  • Session management & rate limiting                       │
│  • Token balance cache (short-lived)                        │
│  • Event bus (Redis Streams for async processing)           │
│                                                              │
│  Trust:      ⚠️ Centralized (ephemeral cache)               │
│  Cost:       💰 Low (in-memory, commodity hardware)          │
│  Speed:      ⚡⚡⚡ ~1-5ms (Redis)                             │
│  Capacity:   Limited by RAM (eviction policies)             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Storage Decision Framework

```
┌─────────────────────────────────────────────────────────────┐
│              WHERE SHOULD DATA BE STORED?                    │
├────────────────────────┬─────────┬──────────┬──────────────┤
│ Criterion              │ On-Chain│ Postgres │ Redis/Cache  │
├────────────────────────┼─────────┼──────────┼──────────────┤
│ Financial impact       │ ✅ Yes  │ ✅ Audit │ ❌ No        │
│ Needs decentralization │ ✅ Yes  │ ❌ No    │ ❌ No        │
│ Query complexity       │ ❌Simple│ ✅Joins  │ ❌ Lookups   │
│ Data volume            │ ❌Small │ ✅ Large │ ❌ Ephemeral │
│ Update frequency       │ ❌ Low  │ ✅ High  │ ⚡ Very high │
│ Historical analysis    │ ❌Expens│ ✅ SQL   │ ❌ Not persist│
│ Real-time access       │ ❌ 400ms│ ✅ 50ms  │ ⚡ 5ms       │
└────────────────────────┴─────────┴──────────┴──────────────┘
```

---

## 2. On-Chain Storage (Solana Accounts)

### 2.1 What's Stored On-Chain

```
┌─────────────────────────────────────────────────────────────┐
│              SOLANA STORAGE ENGINE: AccountsDB               │
│                                                              │
│  Architecture:                                               │
│  ┌───────────────────────────────────────────────┐         │
│  │  AccountsDB (In-Memory/Disk Key-Value Store)  │         │
│  │                                                │         │
│  │  • Maps 32-byte Base58 addresses → data       │         │
│  │  • Massive hashmap structure                  │         │
│  │  • Stored on disk, cached in memory           │         │
│  │  • Flushed to disk after consensus votes      │         │
│  └───────────────────────────────────────────────┘         │
│                                                              │
│  Account Properties:                                        │
│  ┌───────────────────────────────────────────────┐         │
│  │ • Must hold rent-exempt SOL balance           │         │
│  │   (proportional to data size)                 │         │
│  │ • Write access restricted to owning program   │         │
│  │ • Lamport (SOL) increases always allowed      │         │
│  │ • Closing account refunds rent to owner       │         │
│  │ • Owned by specific program (enforced)        │         │
│  └───────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────┐
│              ON-CHAIN ACCOUNT INVENTORY                      │
│                                                              │
│  REGISTRY PROGRAM (User & Meter Identity)                   │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Registry (Singleton PDA)                        │      │
│  │  • Seeds: ["registry"]                           │      │
│  │  • Total user count                              │      │
│  │  • Total meter count                             │      │
│  │  • Authority pubkeys                             │      │
│  │                                                  │      │
│  │  UserAccount (Per User PDA)                      │      │
│  │  • Seeds: ["user", authority_pubkey]             │      │
│  │  • User's wallet address                         │      │
│  │  • User type (Prosumer/Consumer)                 │      │
│  │  • Geolocation (lat/long, H3 zone)               │      │
│  │  • Status (Active/Suspended/Pending)             │      │
│  │  • Shard assignment                              │      │
│  │  • GRX tokens staked                             │      │
│  │                                                  │      │
│  │  MeterAccount (Per Meter PDA)                    │      │
│  │  • Seeds: ["meter", meter_id]                    │      │
│  │  • Meter ID (unique identifier)                  │      │
│  │  • Owner wallet                                  │      │
│  │  • Meter type (Solar/Wind/Battery/Grid)          │      │
│  │  • Status                                        │      │
│  │  • Total generation/consumption                  │      │
│  │  • Settled net generation                        │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
│  TRADING PROGRAM (Order Book & Settlement)                  │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Market (Singleton PDA)                          │      │
│  │  • Seeds: ["market"]                             │      │
│  │  • Total volume traded                           │      │
│  │  • Last clearing price                           │      │
│  │  • Volume-weighted average price (VWAP)          │      │
│  │  • Active order count                            │      │
│  │  • Price history (24-entry ring buffer)          │      │
│  │  • Market fee (basis points)                     │      │
│  │                                                  │      │
│  │  Order (Per Order PDA)                           │      │
│  │  • Seeds: ["order", authority, index]            │      │
│  │  • Order ID (unique)                             │      │
│  │  • Seller/Buyer wallet                           │      │
│  │  • Amount (kWh)                                  │      │
│  │  • Price per kWh                                 │      │
│  │  • Order type & side                             │      │
│  │  • Status (Active/Matched/Settled/Cancelled)     │      │
│  │  • Zone ID & shard assignment                    │      │
│  │                                                  │      │
│  │  TradeRecord (Immutable PDA)                     │      │
│  │  • Buy & sell order references                   │      │
│  │  • Executed amount & price                       │      │
│  │  • Fee amount                                    │      │
│  │  • Settlement tx signature                       │      │
│  │                                                  │      │
│  │  ZoneMarket (Per Geographic Zone PDA)            │      │
│  │  • Seeds: ["zone_market", market, zone_id]       │      │
│  │  • Order book depth (32 price levels each side)  │      │
│  │  • Zone-specific volume/trades                   │      │
│  │                                                  │      │
│  │  MarketShard (Per Shard PDA, 16 total)           │      │
│  │  • Seeds: ["market_shard", market, shard_id]     │      │
│  │  • Shard volume & active orders                  │      │
│  │  • Reduces write contention                      │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
│  ENERGY TOKEN PROGRAM (GRID Token Management)               │
│  ┌──────────────────────────────────────────────────┐      │
│  │  TokenInfo (PDA)                                 │      │
│  │  • Mint authority                                │      │
│  │  • Total supply minted                           │      │
│  │  • Authorized validators                         │      │
│  │                                                  │      │
│  │  MeterReading (Snapshot PDA)                     │      │
│  │  • Energy generated/consumed                     │      │
│  │  • Timestamp, voltage, current                   │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
│  ORACLE PROGRAM (Data Verification)                         │
│  ┌──────────────────────────────────────────────────┐      │
│  │  OracleData (Global Config PDA)                  │      │
│  │  • Seeds: ["oracle_data"]                        │      │
│  │  • Authority & API gateway                       │      │
│  │  • Quality score threshold                       │      │
│  │  • Anomaly detection settings                    │      │
│  │                                                  │      │
│  │  MeterState (Per Meter PDA)                      │      │
│  │  • Seeds: ["meter", meter_id]                    │      │
│  │  • Zone ID                                       │      │
│  │  • Cumulative energy produced/consumed           │      │
│  │  • Quality score (0-100)                         │      │
│  │  • Anomaly flags                                 │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
│  GOVERNANCE PROGRAM (Protocol Parameters)                   │
│  ┌──────────────────────────────────────────────────┐      │
│  │  PoAConfig (PDA)                                 │      │
│  │  • Seeds: ["poa_config"]                         │      │
│  │  • Min/max energy amounts                      │      │
│  │  • ERC certificate validity period             │      │
│  │  • Oracle authority                            │      │
│  │  • Total ERCs issued/validated/revoked         │      │
│  │                                                  │      │
│  │  ErcCertificate (Per Certificate PDA)            │      │
│  │  • Seeds: ["erc_certificate", certificate_id]    │      │
│  │  • Certificate ID (64 bytes, unique)             │      │
│  │  • Owner & energy amount                         │      │
│  │  • Renewable source (Solar/Wind/Hydro)           │      │
│  │  • Validation data (oracle proof)                │      │
│  │  • Issued/expiry dates                           │      │
│  │  • Status (Active/Revoked/Expired)               │      │
│  │  • Oracle reading slot reference                 │      │
│  │  • Quality score                                 │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
│  PDA (Program Derived Address) Notes:                       │
│  • Off-curve accounts WITHOUT private keys                  │
│  • Derived deterministically: program_id + seeds            │
│  • Only owning program can sign/mutate                      │
│  • Used for all program state storage                       │
│  • ATAs (Associated Token Accounts) are standardized PDAs  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 On-Chain Storage Costs

```
┌─────────────────────────────────────────────────────────────┐
│              STORAGE COST PER USER                           │
│                                                              │
│  Account Breakdown (Prosumer Example):                      │
│  ┌────────────────────────────┬──────────┬────────────────┐ │
│  │ Account Type               │ Size     │ Rent Cost      │ │
│  ├────────────────────────────┼──────────┼────────────────┤ │
│  │ UserAccount                │ 256 B    │ $0.10          │ │
│  │ MeterAccount (×2 meters)   │ 512 B    │ $0.20          │ │
│  │ Orders (×10 active)        │ 2,560 B  │ $1.00          │ │
│  │ TradeRecord (×5 trades)    │ 1,280 B  │ $0.50          │ │
│  ├────────────────────────────┼──────────┼────────────────┤ │
│  │ TOTAL                      │ 4,608 B  │ ~$1.80         │ │
│  └────────────────────────────┴──────────┴────────────────┘ │
│                                                              │
│  Note: One-time cost (recoverable if account closed)        │
│  At SOL price: $135/SOL                                     │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Account Lifecycle

```
Account Creation Flow:

  User Registration
        ↓
  ┌─────────────────────────────┐
  │ Derive PDA from seeds:      │
  │ ["user", user_wallet]       │
  └───────────────┬─────────────┘
                  ↓
  ┌─────────────────────────────┐
  │ Create account & pay rent   │
  │ (~0.000732 SOL = $0.10)     │
  └───────────────┬─────────────┘
                  ↓
  ┌─────────────────────────────┐
  │ Initialize account state    │
  │ (set user type, status, etc)│
  └───────────────┬─────────────┘
                  ↓
  ┌─────────────────────────────┐
  │ Emit UserRegistered event   │
  │ (indexed off-chain)         │
  └─────────────────────────────┘


Account Closure Flow (Rare):

  Close Account Request
        ↓
  ┌─────────────────────────────┐
  │ Verify account is inactive  │
  │ (no orders, meters, etc)    │
  └───────────────┬─────────────┘
                  ↓
  ┌─────────────────────────────┐
  │ Close account               │
  │ Rent returned to authority  │
  └─────────────────────────────┘

  Note: GridTokenX rarely closes accounts
  (preserve history for auditing)
```

---

## 3. Off-Chain Storage: PostgreSQL

### 3.1 Database Schema Overview

```
┌─────────────────────────────────────────────────────────────┐
│              POSTGRESQL TABLES (Core Tables)                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  IDENTITY & AUTHENTICATION                                  │
│  ┌──────────────────────────────────────────────┐          │
│  │  users                                       │          │
│  │  • id (UUID), email, username                │          │
│  │  • password_hash (Argon2id)                  │          │
│  │  • wallet_address (Solana pubkey)            │          │
│  │  • role (admin/user/ami)                     │          │
│  │  • encrypted_private_key (AES-256-GCM)       │          │
│  │  • created_at, updated_at                    │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  TRADING LIFECYCLE                                          │
│  ┌──────────────────────────────────────────────┐          │
│  │  market_epochs                               │          │
│  │  • epoch_number, start/end time              │          │
│  │  • status (open/clearing/settled)            │          │
│  │  • clearing_price, total_volume              │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  ┌──────────────────────────────────────────────┐          │
│  │  trading_orders                              │          │
│  │  • id, user_id, epoch_id                     │          │
│  │  • order_type (limit/market)                 │          │
│  │  • side (buy/sell)                           │          │
│  │  • energy_amount, price_per_kwh              │          │
│  │  • filled_amount, status                     │          │
│  │  • blockchain_tx_hash, order_pda             │          │
│  │  • blockchain_status, retry_count            │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  ┌──────────────────────────────────────────────┐          │
│  │  order_matches                               │          │
│  │  • buy_order_id, sell_order_id               │          │
│  │  • matched_amount, match_price               │          │
│  │  • zone_id, matched_at                       │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  ┌──────────────────────────────────────────────┐          │
│  │  settlements                                 │          │
│  │  • buyer_id, seller_id                       │          │
│  │  • energy_amount, price_per_kwh              │          │
│  │  • total_amount, fee_amount                  │          │
│  │  • wheeling_charge, loss_factor              │          │
│  │  • blockchain_tx_hash, blockchain_status     │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  METER DATA                                                 │
│  ┌──────────────────────────────────────────────┐          │
│  │  meter_readings (Partitioned by month)       │          │
│  │  • meter_id, wallet_address                  │          │
│  │  • energy_generated, energy_consumed         │          │
│  │  • battery_level, voltage, current           │          │
│  │  • metadata (JSONB)                          │          │
│  │  • on_chain_confirmed, on_chain_slot         │          │
│  │  • minted, mint_tx_signature                 │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  BLOCKCHAIN INDEXING                                        │
│  ┌──────────────────────────────────────────────┐          │
│  │  blockchain_events                           │          │
│  │  • event_type, transaction_signature         │          │
│  │  • slot, program_id                          │          │
│  │  • event_data (JSONB)                        │          │
│  │  • processed flag                            │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  ┌──────────────────────────────────────────────┐          │
│  │  event_processing_state                      │          │
│  │  • service_name                              │          │
│  │  • last_processed_slot (checkpoint)          │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  CERTIFICATES                                               │
│  ┌──────────────────────────────────────────────┐          │
│  │  energy_certificates                         │          │
│  │  • certificate_id (unique)                   │          │
│  │  • wallet_address, energy_amount             │          │
│  │  • type (REC/ERC/IREC)                       │          │
│  │  • status, metadata (JSONB)                  │          │
│  │  • issued_at, expires_at                     │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  ADDITIONAL TABLES (not shown):                             │
│  • escrow_records: Financial escrow tracking                │
│  • recurring_orders: DCA orders                             │
│  • blockchain_transactions: Full tx history                 │
│  • audit_logs: Security audit trail                         │
│  • vpp_clusters: Virtual Power Plant data                   │
│  • carbon_credits: Carbon offset tracking                   │
│  • notifications, price_alerts                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Database Indexing Strategy

```
┌─────────────────────────────────────────────────────────────┐
│              INDEX OPTIMIZATION                               │
├─────────────────────────────────────────┬───────────────────┤
│ Index                                   │ Purpose           │
├─────────────────────────────────────────┼───────────────────┤
│ users(wallet_address)                   │ Auth lookups      │
│ users(email)                            │ User login        │
├─────────────────────────────────────────┼───────────────────┤
│ trading_orders(user_id, status)         │ User portfolio    │
│ trading_orders(epoch_id)                │ Epoch queries     │
│ trading_orders(blockchain_status)       │ Retry failed txs  │
│   WHERE blockchain_status != 'success'  │ (partial index)   │
├─────────────────────────────────────────┼───────────────────┤
│ settlements(buyer_id, settled_at)       │ Buyer history     │
│ settlements(seller_id, settled_at)      │ Seller history    │
│ settlements(blockchain_status)          │ Pending           │
│   WHERE blockchain_status = 'unprocessed'│ settlements      │
├─────────────────────────────────────────┼───────────────────┤
│ meter_readings(meter_id, submitted_at)  │ Time-series       │
│ meter_readings(minted, on_chain_confirmed)│ Pending mints   │
│   WHERE minted=TRUE AND confirmed=FALSE │ (partial index)   │
├─────────────────────────────────────────┼───────────────────┤
│ blockchain_events(slot)                 │ Event ordering    │
│ blockchain_events(processed, slot)      │ Unprocessed       │
│   WHERE processed=FALSE                 │ events            │
└─────────────────────────────────────────┴───────────────────┘
```

### 3.3 Database Partitioning

```
Meter Readings Partitioned by Month:

  meter_readings (parent table)
  ├─ meter_readings_2026_01 (January)
  ├─ meter_readings_2026_02 (February)
  ├─ meter_readings_2026_03 (March)
  ├─ meter_readings_2026_04 (April) ← Current
  └─ meter_readings_2026_05 (May)   ← Pre-created


  Query Example:

  SELECT * FROM meter_readings
  WHERE meter_id = 'meter_123'
    AND submitted_at >= '2026-04-01'
    AND submitted_at < '2026-05-01';

  → Only scans meter_readings_2026_04 partition
  → 10-50x faster than full table scan


  Benefits:
  ✓ Query performance: Partition pruning
  ✓ Data retention: Archive/drop old partitions
  ✓ Maintenance: Smaller indexes per partition
  ✓ Parallelism: Queries can scan partitions in parallel
```

---

## 4. Off-Chain Storage: Redis

### 4.1 Redis Use Cases

```
┌─────────────────────────────────────────────────────────────┐
│              REDIS USAGE PATTERNS                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. EVENT BUS (Redis Streams)                               │
│  ┌────────────────────────────────────────────┐            │
│  │  Stream: gridtokenx:events:v1              │            │
│  │                                             │            │
│  │  Producers:                                 │            │
│  │  • API Gateway publishes events            │            │
│  │  • Matching engine publishes matches       │            │
│  │  • Settlement manager publishes settlements│            │
│  │                                             │            │
│  │  Consumers:                                 │            │
│  │  • EventPersistenceWorker (PostgreSQL)     │            │
│  │  • WebSocket broadcaster (real-time UI)    │            │
│  │  • Analytics pipeline (metrics)            │            │
│  │                                             │            │
│  │  Events Published:                          │            │
│  │  • OrderCreated → INSERT trading_orders    │            │
│  │  • OrderMatched → INSERT order_matches     │            │
│  │  • SettlementRequested → INSERT settlements│            │
│  │  • MeterReadingCreated → INSERT readings   │            │
│  └────────────────────────────────────────────┘            │
│                                                              │
│  2. CACHE LAYER (Key-Value with TTL)                        │
│  ┌────────────────────────────────────────────┐            │
│  │  Cache Key Patterns:                        │            │
│  │                                             │            │
│  │  User Data (TTL: 24 hours)                 │            │
│  │  • user:profile:{user_id}                  │            │
│  │  • user:wallet:{user_id}                   │            │
│  │                                             │            │
│  │  Market Data (TTL: 5 minutes)              │            │
│  │  • market:current_epoch                    │            │
│  │  • market:stats:{epoch_id}                 │            │
│  │  • orderbook:{market_id}                   │            │
│  │                                             │            │
│  │  Token Balances (TTL: 1 hour)              │            │
│  │  • token:balance:{wallet}:{mint}           │            │
│  │                                             │            │
│  │  Settlement State (TTL: 1 hour)            │            │
│  │  • settlement:{settlement_id}              │            │
│  │                                             │            │
│  │  ERC Certificates (TTL: 24 hours)          │            │
│  │  • erc:certificate:{cert_id}               │            │
│  └────────────────────────────────────────────┘            │
│                                                              │
│  3. WEBSOCKET BROADCASTING (Redis Pub/Sub)                  │
│  ┌────────────────────────────────────────────┐            │
│  │  Channel: gridtokenx_market_events         │            │
│  │                                             │            │
│  │  Publishers:                                │            │
│  │  • Matching engine (order updates)         │            │
│  │  • Settlement manager (confirmations)      │            │
│  │  • Market epoch transitions                │            │
│  │                                             │            │
│  │  Subscribers:                               │            │
│  │  • WebSocket server (pushes to UI)         │            │
│  │  • Analytics service (metrics)             │            │
│  └────────────────────────────────────────────┘            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Cache Invalidation Strategy

```
┌─────────────────────────────────────────────────────────────┐
│              CACHE INVALIDATION EVENTS                       │
├─────────────────────────┬───────────────────────────────────┤
│ Event                   │ Cache Keys Invalidated            │
├─────────────────────────┼───────────────────────────────────┤
│ User profile update     │ user:profile:{id}                 │
│                         │ user:wallet:{id}                  │
├─────────────────────────┼───────────────────────────────────┤
│ New order created       │ orderbook:{market_id}             │
│                         │ market:stats:{epoch}              │
├─────────────────────────┼───────────────────────────────────┤
│ Trade settlement        │ token:balance:*                   │
│                         │ settlement:*                      │
├─────────────────────────┼───────────────────────────────────┤
│ Meter reading submitted │ user:profile:{id}                 │
│                         │ (generation stats)                │
└─────────────────────────┴───────────────────────────────────┘
```

### 4.3 Redis Performance

```
┌────────────────────────────────────────────────────┐
│              REDIS PERFORMANCE METRICS              │
├──────────────────────────┬─────────────────────────┤
│ Metric                   │ Value                   │
├──────────────────────────┼─────────────────────────┤
│ Connection pool size     │ 20 connections          │
│ Command timeout          │ 3 seconds               │
│ Connection timeout       │ 5 seconds               │
│ Typical latency          │ 1-5ms                   │
│ Throughput               │ 10,000+ ops/sec         │
└──────────────────────────┴─────────────────────────┘
```

---

## 5. Synchronization: On-Chain ↔ Off-Chain

### 5.1 Dual-Write Pattern

```
┌─────────────────────────────────────────────────────────────┐
│              OFF-CHAIN-FIRST, ON-CHAIN-VERIFICATION          │
│                                                              │
│  Step 1: Create DB Record (PostgreSQL)                      │
│  ┌──────────────────────────────────────────┐              │
│  │  INSERT INTO trading_orders              │              │
│  │  (user_id, order_type, side, amount)     │              │
│  │  VALUES ($1, $2, $3, $4)                 │              │
│  │  RETURNING id, order_index               │              │
│  │                                          │              │
│  │  blockchain_status = 'unprocessed'       │              │
│  └──────────────────────────────────────────┘              │
│                          ↓                                  │
│  Step 2: Submit On-Chain Transaction (Solana)              │
│  ┌──────────────────────────────────────────┐              │
│  │  trading_program.create_order(data)      │              │
│  │  → Transaction confirmed                 │              │
│  │  → tx_hash returned                      │              │
│  └──────────────────────────────────────────┘              │
│                          ↓                                  │
│  Step 3: Update DB with On-Chain Proof                     │
│  ┌──────────────────────────────────────────┐              │
│  │  UPDATE trading_orders                   │              │
│  │  SET blockchain_tx_hash = $1,            │              │
│  │      order_pda = $2,                     │              │
│  │      blockchain_status = 'success'       │              │
│  │  WHERE id = $3                           │              │
│  └──────────────────────────────────────────┘              │
│                          ↓                                  │
│  Step 4: Publish Event (Redis Streams)                     │
│  ┌──────────────────────────────────────────┐              │
│  │  EventBus.publish(OrderCreated {         │              │
│  │    order_id, tx_hash, pda                │              │
│  │  })                                      │              │
│  │  → EventPersistenceWorker persists       │              │
│  └──────────────────────────────────────────┘              │
│                                                              │
└─────────────────────────────────────────────────────────────┘


Why Off-Chain-First?

✓ Durability: DB record exists even if blockchain tx fails
✓ Auditability: Complete history of attempts (success & failure)
✓ Retryability: Can retry failed blockchain transactions
✓ Performance: DB write is faster than blockchain submission
```

### 5.2 Failure Handling & Retry Logic

```
┌─────────────────────────────────────────────────────────────┐
│              TRANSACTION FAILURE FLOW                        │
│                                                              │
│  Submit Blockchain Transaction                               │
│           ↓                                                  │
│        Success?                                              │
│       ╱        ╲                                             │
│     YES          NO                                          │
│      ↓            ↓                                          │
│  Update DB    Retry (max 3 attempts)                         │
│  with tx_hash • Attempt 1: wait 200ms                       │
│  status=success • Attempt 2: wait 400ms                     │
│                 • Attempt 3: wait 800ms                      │
│                        ↓                                     │
│                   Still failing?                             │
│                  ╱              ╲                            │
│                NO              YES                           │
│                 ↓                ↓                           │
│            Mark as          Mark as                         │
│            'failed_retry'   'failed_fatal'                  │
│            retry_count++    + alert operator                │
│                                                              │
│  Database Status Tracking:                                  │
│  ┌──────────────────────────────────────────────┐          │
│  │ blockchain_status column:                    │          │
│  │                                              │          │
│  │ unprocessed    → Not yet submitted           │          │
│  │ success        → Confirmed on-chain          │          │
│  │ failed_retry   → Failed, will retry          │          │
│  │ failed_fatal   → Failed, needs manual review │          │
│  └──────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 Blockchain Event Indexing

```
┌─────────────────────────────────────────────────────────────┐
│              EVENT INDEXING FLOW                             │
│                                                              │
│  On-Chain Events (Transaction Logs)                         │
│  ┌──────────────────────────────────────┐                  │
│  │ Programs emit events:                │                  │
│  │ • UserRegistered                     │                  │
│  │ • OrderCreated                       │                  │
│  │ • TradeExecuted                      │                  │
│  │ • MeterReadingConfirmed              │                  │
│  └──────────────┬───────────────────────┘                  │
│                 ↓                                           │
│  EventProcessor Service (Polling)                          │
│  ┌──────────────────────────────────────┐                  │
│  │ • Poll RPC for pending transactions  │                  │
│  │ • Check confirmation status          │                  │
│  │ • Parse events from transaction logs │                  │
│  └──────────────┬───────────────────────┘                  │
│                 ↓                                           │
│  PostgreSQL (Indexed Events)                               │
│  ┌──────────────────────────────────────┐                  │
│  │ INSERT INTO blockchain_events        │                  │
│  │ (event_type, tx_signature, slot,     │                  │
│  │  program_id, event_data)             │                  │
│  │                                      │                  │
│  │ UPDATE meter_readings                │                  │
│  │ SET on_chain_confirmed = true        │                  │
│  └──────────────────────────────────────┘                  │
│                                                              │
│  Checkpoint Tracking:                                       │
│  ┌──────────────────────────────────────────────┐          │
│  │ event_processing_state                       │          │
│  │ • service_name: "event_processor"            │          │
│  │ • last_processed_slot: 12345678              │          │
│  │                                              │          │
│  │ Allows resume from last checkpoint           │          │
│  │ (no need to re-process from genesis)         │          │
│  └──────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### 5.4 Disaster Recovery: Checkpoint Replay

```
┌─────────────────────────────────────────────────────────────┐
│              CHECKPOINT-BASED REPLAY                         │
│                                                              │
│  Use Cases:                                                  │
│  • Service restart (resume from checkpoint)                 │
│  • Database corruption (re-index from blockchain)           │
│  • Audit (verify off-chain matches on-chain)                │
│  • Migration (backfill new fields)                          │
│                                                              │
│  Replay Process:                                             │
│  ┌────────────────────────────────────────────┐            │
│  │ 1. Load last checkpoint from DB            │            │
│  │    (last_processed_slot: 12345678)         │            │
│  │                                            │            │
│  │ 2. Query Solana RPC for blocks from slot   │            │
│  │    (slot 12345679 → current slot)          │            │
│  │                                            │            │
│  │ 3. For each block:                         │            │
│  │    • Parse transactions                    │            │
│  │    • Filter GridTokenX program txs         │            │
│  │    • Extract events                        │            │
│  │    • Insert into blockchain_events         │            │
│  │                                            │            │
│  │ 4. Update checkpoint after each block      │            │
│  │    (crash recovery safe)                   │            │
│  │                                            │            │
│  │ 5. Complete → Resume normal processing     │            │
│  └────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Storage Performance & Scalability

### 6.1 Query Performance

```
┌─────────────────────────────────────────────────────────────┐
│              QUERY PERFORMANCE BY TIER                       │
├──────────────────────────────────┬──────────┬───────────────┤
│ Query Type                       │ Database │ Latency       │
├──────────────────────────────────┼──────────┼───────────────┤
│ User by wallet                   │ Postgres │ ~5ms          │
│ Active orders by user            │ Postgres │ ~10ms         │
│ Pending settlements              │ Postgres │ ~8ms          │
│ Meter readings (time range)      │ Postgres │ ~20ms         │
│                                  │ (partit.)│               │
├──────────────────────────────────┼──────────┼───────────────┤
│ Market stats (current epoch)     │ Redis    │ ~2ms          │
│ Token balance                    │ Redis    │ ~1ms          │
│ Order book snapshot              │ Redis    │ ~3ms          │
├──────────────────────────────────┼──────────┼───────────────┤
│ On-chain account read            │ Solana   │ ~50-100ms     │
│ On-chain transaction submit      │ Solana   │ ~400ms        │
└──────────────────────────────────┴──────────┴───────────────┘
```

### 6.2 Scalability Patterns

```
┌─────────────────────────────────────────────────────────────┐
│              SCALABILITY PATTERNS                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. READ REPLICAS (PostgreSQL)                              │
│  ┌──────────────────────────────────────┐                  │
│  │  Primary (port 5434)                 │                  │
│  │  • Handles all writes                │                  │
│  │  • Replicates to replica              │                  │
│  │                                      │                  │
│  │  Replica (port 5433)                 │                  │
│  │  • Handles read queries              │                  │
│  │  • Read-only                         │                  │
│  │                                      │                  │
│  │  Usage:                              │                  │
│  │  • Read queries → Replica            │                  │
│  │  • Write queries → Primary           │                  │
│  └──────────────────────────────────────┘                  │
│                                                              │
│  2. CONNECTION POOLING                                      │
│  ┌──────────────────────────────────────┐                  │
│  │  API Gateway: 50 connections         │                  │
│  │  • Handles ~500 req/sec              │                  │
│  │                                      │                  │
│  │  Trading Service: 30 connections     │                  │
│  │  • Matching engine                   │                  │
│  │                                      │                  │
│  │  Oracle Bridge: 10 connections       │                  │
│  │  • Meter ingestion                   │                  │
│  └──────────────────────────────────────┘                  │
│                                                              │
│  3. CACHE-ASIDE PATTERN                                     │
│  ┌──────────────────────────────────────┐                  │
│  │  Get market stats:                   │                  │
│  │  1. Check Redis cache                │                  │
│  │     → Hit: Return (2ms)              │                  │
│  │     → Miss: Query database (10ms)    │                  │
│  │  2. Populate cache (5-min TTL)       │                  │
│  │  3. Return result                    │                  │
│  └──────────────────────────────────────┘                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 6.3 Data Retention Strategy

```
┌─────────────────────────────────────────────────────────────┐
│              DATA RETENTION POLICY                           │
├──────────────────────────┬──────────────┬───────────────────┤
│ Data Type                │ Retention    │ Storage           │
├──────────────────────────┼──────────────┼───────────────────┤
│ On-chain accounts        │ Indefinite   │ Solana            │
│                          │              │ (rent-paid)       │
├──────────────────────────┼──────────────┼───────────────────┤
│ PostgreSQL (orders)      │ 7 years      │ Postgres (hot)    │
│                          │              │ → S3 (cold)       │
├──────────────────────────┼──────────────┼───────────────────┤
│ PostgreSQL (meter data)  │ 2 years      │ Postgres          │
│                          │              │ (partitioned)     │
├──────────────────────────┼──────────────┼───────────────────┤
│ Redis cache              │ 1-24 hours   │ Redis             │
│                          │              │ (TTL, ephemeral)  │
├──────────────────────────┼──────────────┼───────────────────┤
│ Blockchain events        │ Indefinite   │ Postgres          │
│                          │              │ (indexing)        │
└──────────────────────────┴──────────────┴───────────────────┘
```

---

## 7. Storage Security

### 7.1 Sensitive Data Protection

```
┌─────────────────────────────────────────────────────────────┐
│              ENCRYPTED PRIVATE KEY STORAGE                   │
│                                                              │
│  User private keys stored encrypted in PostgreSQL:          │
│                                                              │
│  ┌───────────────────────────────────────────────┐         │
│  │  Encryption Process:                           │         │
│  │                                                │         │
│  │  1. Generate random salt (128-bit)            │         │
│  │  2. Generate random IV (96-bit)               │         │
│  │  3. Derive encryption key:                     │         │
│  │     PBKDF2 (100,000 iterations, HMAC-SHA256)  │         │
│  │  4. Encrypt with AES-256-GCM                   │         │
│  │  5. Store in database:                         │         │
│  │     • encrypted_private_key                    │         │
│  │     • wallet_salt                              │         │
│  │     • encryption_iv                            │         │
│  └───────────────────────────────────────────────┘         │
│                                                              │
│  Security Properties:                                       │
│  ✓ Encryption: AES-256-GCM (authenticated)                 │
│  ✓ Key derivation: PBKDF2 (100k iterations)                │
│  ✓ Salt: Random 128-bit per user                           │
│  ✓ IV: Random 96-bit per encryption                        │
│  ✓ Master secret: Environment variable                     │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 Database Access Control

```
┌─────────────────────────────────────────────────────────────┐
│              DATABASE ROLES & PERMISSIONS                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  gridtokenx_api (Application Role)                          │
│  • Full CRUD on all tables                                  │
│  • Used by API Gateway, Trading Service                     │
│                                                              │
│  gridtokenx_readonly (Analytics Role)                       │
│  • SELECT only on all tables                                │
│  • Used by reporting, dashboards                            │
│                                                              │
│  Row-Level Security (Multi-Tenancy):                        │
│  • Users table: Can only access own row                    │
│  • Orders table: Can only access own orders                │
│  • Enforced by PostgreSQL (application cannot bypass)       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Complete Data Flow

### 8.1 End-to-End Example: Meter Reading

```
┌─────────────────────────────────────────────────────────────┐
│              SMART METER READING FLOW                        │
│                                                              │
│  Smart Meter (IoT Device)                                   │
│  • Generates reading every 5 minutes                        │
│  • Contains: kWh, voltage, current, battery                │
│         ↓ (HTTP POST)                                        │
│  Oracle Bridge Service                                      │
│  • Validates API key                                        │
│  • Routes to API Gateway via gRPC                           │
│         ↓ (gRPC)                                             │
│  API Gateway                                                │
│  ├─→ PostgreSQL (meter_readings table)                     │
│  │   • Insert reading with metadata                        │
│  │   • on_chain_confirmed = false                          │
│  │   • minted = false                                      │
│  ├─→ Redis Streams (event bus)                             │
│  │   • Publish MeterReadingCreated event                   │
│  │   • EventPersistenceWorker indexes to DB                │
│  └─→ Solana RPC (mint energy tokens)                       │
│        • Oracle Program validates reading                  │
│        • Governance Program issues ERC cert                │
│        • Energy Token Program mints GRID tokens            │
│              ↓                                              │
│         Transaction confirmed                               │
│              ↓                                              │
│  EventProcessor polls RPC                                   │
│  • Finds pending reading (minted=true, confirmed=false)    │
│  • Queries Solana for transaction status                   │
│  • On confirmation:                                        │
│    - UPDATE meter_readings SET on_chain_confirmed=true     │
│    - INSERT blockchain_events                              │
│    - Send webhook notification                             │
│                                                              │
│  Total Flow Time: ~2.5 seconds                              │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 Storage Decision Summary

```
┌─────────────────────────────────────────────────────────────┐
│              COMPLETE STORAGE PLACEMENT                      │
├──────────────────────┬──────────┬──────────┬───────────────┤
│ Data                 │ On-Chain │ Postgres │ Redis/Cache   │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ User identity        │ ✅ PDA   │ ✅       │ ✅ cache      │
│ User profile         │ ❌       │ ✅       │ ❌            │
│ (email, password)    │          │          │               │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ User wallet          │ ❌       │ ✅       │ ❌            │
│ (encrypted key)      │          │          │               │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Orders               │ ✅ PDA   │ ✅       │ ✅ orderbook  │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Order history        │ ❌       │ ✅       │ ❌            │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Trades               │ ✅ Record│ ✅       │ ❌            │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Settlements          │ ✅ tx    │ ✅       │ ✅ status     │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Meter readings       │ ✅ snap  │ ✅       │ ❌            │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ ERC certificates     │ ✅ PDA   │ ✅       │ ✅ cache      │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Token balances       │ ✅ SPL   │ ❌       │ ✅ cache      │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Market epochs        │ ❌       │ ✅       │ ✅ current    │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Price history        │ ✅ 24    │ ✅ full  │ ✅ cache      │
│                      │ entries  │ history  │               │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Blockchain events    │ ✅ logs  │ ✅       │ ❌            │
├──────────────────────┼──────────┼──────────┼───────────────┤
│ Audit logs           │ ❌       │ ✅       │ ❌            │
└──────────────────────┴──────────┴──────────┴───────────────┘

Legend:
✅ PDA    = Program Derived Address (on-chain account)
✅ snap   = On-chain snapshot (not full time-series)
✅ tx     = Transaction hash/reference
✅ SPL    = SPL Token account (managed by token program)
✅ logs   = Transaction logs (not stored in account state)
```

---

## 🔗 Related Documentation

- [Consensus Layer](./consensus-layer.md) - PoP and transaction finality
- [Runtime Layer](./runtime-sealevel.md) - Sealevel parallel execution
- [Database Migrations](../../../gridtokenx-api/migrations/) - Schema evolution
- [PostgreSQL Documentation](https://www.postgresql.org/docs/) - Official docs
- [Redis Documentation](https://redis.io/docs/) - Official docs

---

**Last Updated:** April 6, 2026  
**Maintained By:** GridTokenX Engineering Team
