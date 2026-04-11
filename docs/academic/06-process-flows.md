# Process Flows

## GridTokenX End-to-End Process Documentation

> **April 2026 Edition**
> **Version:** 3.0.0
> **Status:** Production-Ready

---

> **Related Documentation:**
> - [Data Flow Diagrams](./04-data-flow-diagrams.md) - System DFD Level 0-2
> - [Smart Contract Architecture](../architecture/specs/smart-contract-architecture.md) - Atomic settlement & logic
> - [Trading Service Architecture](../architecture/services/TRADING_SERVICE_ARCHITECTURE.md) - CDA order book matched in Rust
> - [Hybrid Messaging](../architecture/messaging/HYBRID_MESSAGING_ARCHITECTURE.md) - Kafka/RabbitMQ/Redis

---

## Table of Contents

1. [Process Overview](#1-process-overview)
2. [P1: User Onboarding](#2-p1-user-onboarding)
3. [P2: Meter Registration](#3-p2-meter-registration)
4. [P3: Energy Recording](#4-p3-energy-recording-smart-meter-reading)
5. [P4: Token Minting](#5-p4-token-minting-automated-grid-generation)
6. [P5: Create Sell Order](#6-p5-create-sell-order)
7. [P6: Match Orders](#7-p6-match-orders-cda-order-book)
8. [P7: Atomic Settlement](#8-p7-atomic-settlement)
9. [P8: ERC Certificate Issuance](#9-p8-erc-certificate-issuance)
10. [Complete End-to-End Flow](#10-complete-end-to-end-flow)
11. [Error Handling & Recovery](#11-error-handling--recovery)
12. [Document Metadata](#12-document-metadata)

---

## 1. Process Overview

### 1.1 Core Business Processes

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        CORE BUSINESS PROCESSES                                  │
│                                                                                 │
│   P1              P2              P3              P4                             │
│   ┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐                       │
│   │ User   │────▶│ Meter  │────▶│ Energy │────▶│ Token  │                       │
│   │Onboard │     │Register│     │Record  │     │Mint    │                       │
│   └────────┘     └────────┘     └────────┘     └────────┘                       │
│                                                          │                      │
│   P8                          P7              P6         │  P5                   │
│   ┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐│                      │
│   │ ERC    │◀────│ Atomic │◀────│ Match  │◀────│ Create │◀┘                     │
│   │Certify │     │Settle  │     │ Orders │     │Sell Ord│                       │
│   └────────┘     └────────┘     └────────┘     └────────┘                       │
│                                                                                 │
│   Latency Profile:                                                              │
│   P1-P2: ~440ms (blockchain TX)  P3: <100ms (edge validation)                  │
│   P4: ~500ms (mint TX)           P5-P7: ~600ms (trade+settle)                  │
│   P8: ~440ms (cert TX)                                                          │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Swimlane Notation Standard

All swimlane diagrams use the following conventions:

```
┌──────────────┐    Action/Process Step (solid border)
└──────────────┘
╔══════════════╗    Atomic Transaction Block (double border)
╚══════════════╝
┌──────────────┐    Decision Node (diamond shown inline)
│ ?condition?  │
└──────┬───────┘
       │ Yes/No

Arrow Styles:
  ──────│─────▶  Synchronous call (blocking)
  ─ ─ ─▶         Asynchronous event (non-blocking)
  ◀──────────    Response/callback
  ──[label]──▶   Labeled data flow

Timing Annotations:
  [<10ms]        Fast operation (in-memory/cache)
  [~100ms]       Network call (HTTP/gRPC)
  [~440ms]       Solana transaction (confirmation)
  [~1s]          Complex multi-step operation
  [variable]     Depends on external factors

Decision Branches:
  ┌─────┐
  │ ?X? │──Yes──▶  Positive branch
  └─────┘
     │No
     ▼
  Negative branch

Error Paths (shown as alternate flows after main diagram):
  ⚠ ERR: condition → recovery action
```

### 1.3 Service Architecture Reference

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     SERVICE ARCHITECTURE REFERENCE                              │
│                                                                                 │
│  ┌─────────────┐     ┌─────────────────────────────────────────────────────┐   │
│  │ Smart Meter │────▶│ Edge Gateway → Oracle Bridge → API Gateway          │   │
│  │ (IoT Device)│     │  (validation, signing, orchestration)               │   │
│  └─────────────┘     └──────────────────────┬──────────────────────────────┘   │
│                                             │ gRPC                              │
│                    ┌────────────────────────┼────────────────────────┐           │
│                    ▼                        ▼                        ▼           │
│            ┌──────────────┐        ┌──────────────┐        ┌──────────────┐     │
│            │ IAM Service  │        │Trading Svc   │        │ Oracle Svc   │     │
│            │ (Port 50052) │        │ (Port 50053) │        │ (Port 4010)  │     │
│            │              │        │              │        │              │     │
│            │ • User mgmt  │        │ • Order book │        │ • Validation │     │
│            │ • KYC        │        │ • Matching   │        │ • Minting    │     │
│            │ • Wallet     │        │ • Settlement │        │ • Price feeds│     │
│            └──────┬───────┘        └──────┬───────┘        └──────┬───────┘     │
│                   │                      │                       │              │
│                   └──────────────────────┼───────────────────────┘              │
│                                          │ Solana RPC / Anchor                  │
│                                          ▼                                      │
│                        ┌──────────────────────────────────┐                    │
│                        │      Solana Blockchain           │                    │
│                        │  (Registry, Trading, Oracle,     │                    │
│                        │   Energy Token, Governance)      │                    │
│                        └──────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. P1: User Onboarding

### 2.1 Main Flow - Prosumer Registration

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  P1: USER ONBOARDING - SWIMLANE DIAGRAM                                         │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   USER              FRONTEND          API SERVICES        IAM SERVICE            │
│                                                                                 │
│   ┌───────┐                                                                     │
│   │ Start │                                                                     │
│   └───┬───┘                                                                     │
│       │                                                                         │
│       │ 1. Connect Wallet                                          [<2s]        │
│       ▼                                                                         │
│   ┌───────────┐                                                                 │
│   │ Phantom/  │──────▶ Wallet Connect Request                                   │
│   │ Solflare  │         (solana-wallet-adapter)                                 │
│   └───────────┘         │                                                       │
│                         ▼                                                       │
│                    ┌───────────┐                                                │
│                    │ Get Wallet│◀────── Sign Message Prompt                     │
│                    │ Address   │         [user confirms]                        │
│                    └─────┬─────┘                                                │
│                          │                                                      │
│       ◀──────────────────┘                                                      │
│       │ Wallet Connected                                                        │
│       │                                                                         │
│       │ 2. Fill Registration Form                                  [<5s]        │
│       ▼                                                                         │
│   ┌───────────┐                                                                 │
│   │ Email     │                                                                 │
│   │ Username  │                                                                 │
│   │ Password  │                                                                 │
│   │ User Type │──────▶ POST /api/v1/users                                       │
│   └───────────┘         │                          [JWT + API Key returned]     │
│                         ▼                                                       │
│                    ┌────────────────────┐                                       │
│                    │ Validate Input     │                                        │
│                    │ • Email format     │                                        │
│                    │ • Password strength│                                        │
│                    │ • Username unique  │                                        │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│                          │ ✓ Valid                                             │
│                          ▼                                                     │
│                    ┌────────────────────┐                                       │
│                    │ Hash Password      │                     [<50ms]           │
│                    │ (Argon2id)         │                                       │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│                          │ gRPC: CreateUser                                    │
│                          ▼                                 [~440ms]            │
│   ┌─────────────────────────────────────────┐                                  │
│   │          IAM SERVICE                   │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Check Duplicate    │                                                        │
│   │ │ (email/username)   │                                                        │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │ ✓ Not Found                │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Create User PDA    │──────▶ Solana: register_user()                     │
│   │ │ Seeds: [prefix,    │         (Registry Program)                         │
│   │ │  wallet_address]   │                                                    │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           │ ◀──── TX Confirmed         │                  [~440ms]        │
│   │           │   (signature)              │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Save to PostgreSQL │                                                        │
│   │ │ • users table      │                                                        │
│   │ │ • wallet mapping   │                                                        │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Generate JWT       │                                                        │
│   │ │ + API Key          │                                                        │
│   │ │ Encrypt wallet     │                                                        │
│   │ │ private key        │                                                        │
│   │ └────────────────────┘                 │                                  │
│   └───────────────────┬───────────────────┘                                  │
│                       │                                                       │
│       ◀───────────────┘                                                       │
│       │ 201 Created                                                           │
│       │ { user_id, jwt, api_key, wallet }                                     │
│       ▼                                                                         │
│   ┌───────────┐                                                                 │
│   │ Store JWT │                                                                 │
│   │ + API Key │                                                                 │
│   │ locally   │                                                                 │
│   └─────┬─────┘                                                                 │
│         │                                                                       │
│         ▼                                                                       │
│   ┌───────┐                                                                     │
│   │  End  │                                                                     │
│   └───────┘                                                                     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Process Metrics - P1

| Metric | Value | Notes |
|--------|-------|-------|
| Average Latency | ~600ms | Includes 1 Solana TX + DB write |
| Solana TX Time | ~440ms | Single block confirmation |
| Password Hash | ~50ms | Argon2id, default params |
| DB Write | <10ms | Single INSERT with index |
| Success Rate | 99.7% | Excluding duplicate attempts |
| Throughput | 50 req/s | Limited by Solana TX rate |

### 2.3 Exception Flow - P1

```
EXCEPTION PATHS:
═══════════════════════════════════════════════════════════════════════════════════

⚠ ERR: Duplicate Email/Username
   → Validation rejects at API Gateway [~5ms]
   → Returns 409 Conflict with field details
   → User must provide alternative

⚠ ERR: Wallet Already Registered
   → IAM Service checks existing PDAs [~20ms]
   → Returns 409 with existing user_id
   → User can recover via login flow

⚠ ERR: Solana TX Timeout
   → Solana TX fails to confirm [>10s timeout]
   → IAM Service retries with exponential backoff (3 attempts)
   → After max retries: returns 503, queues for async completion
   → Background worker monitors pending registrations

⚠ ERR: Database Constraint Violation
   → PostgreSQL UNIQUE constraint on email/username
   → Returns 500, rolls back any partial state
   → Admin alert triggered for investigation

⚠ ERR: Wallet Connection Timeout
   → Frontend wallet adapter timeout [~30s]
   → User retries connection
   → No server-side state created
```

---

## 3. P2: Meter Registration

### 3.1 Main Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  P2: METER REGISTRATION - SWIMLANE DIAGRAM                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   PROSUMER          API SERVICES        IAM SERVICE         BLOCKCHAIN           │
│                                                                                 │
│   ┌───────┐                                                                     │
│   │ Start │                                                                     │
│   └───┬───┘                                                                     │
│       │                                                                         │
│       │ 1. Submit Meter Details                                    [<2s]        │
│       ▼                                                                         │
│   ┌───────────┐                                                                 │
│   │ Meter ID  │─────▶ POST /api/v1/meters                                       │
│   │ Location  │       Headers: Authorization: Bearer <JWT>                      │
│   │ Type      │       Body: { meter_id, location, type, capacity_kw }           │
│   │ Capacity  │                                                                 │
│   └───────────┘         │                                                       │
│                         ▼                                                       │
│                    ┌────────────────────┐                                       │
│                    │ Authenticate JWT   │                     [<10ms]           │
│                    │ Extract user_id    │                                       │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│                          ▼                                                     │
│                    ┌────────────────────┐                                       │
│                    │ Validate Input     │                                        │
│                    │ • Meter ID format  │                                        │
│                    │ • Type enum check  │                                        │
│                    │ • Capacity > 0     │                                        │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│                    ┌───────┴───────┐                                            │
│                    │     ?Valid?   │───No──▶ 400 Bad Request                   │
│                    └───────┬───────┘                                            │
│                          │ Yes                                                 │
│                          ▼                                                     │
│                    │ gRPC: RegisterMeter                   [~440ms]            │
│                    ▼                                                       │
│   ┌─────────────────────────────────────────┐                                  │
│   │          IAM SERVICE                   │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Verify User PDA    │──────▶ Solana: read_user_pda()                     │
│   │ │ exists             │         (Registry Program)                         │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │     ┌─────┴─────┐                                                          │
│   │     │  ?Exists? │───No──▶ 404 User Not Found                              │
│   │     └─────┬─────┘                                                          │
│   │           │ Yes                                                            │
│   │           ▼                                                                │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Check Meter        │                                                        │
│   │ │ Duplicate (ID)     │                                                        │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │     ┌─────┴─────┐                                                          │
│   │     │ ?Unique?  │───No──▶ 409 Meter Already Registered                    │
│   │     └─────┬─────┘                                                          │
│   │           │ Yes                                                            │
│   │           ▼                                                                │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Build TX:          │                                                        │
│   │ │ register_meter()   │───────────────▶ Create Meter PDA [~440ms]           │
│   │ │ Seeds: [prefix,    │         Seeds: [prefix, meter_id]                   │
│   │ │  meter_id]         │         Accounts: [user_pda, meter_pda, signer]     │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           │ ◀──── TX Confirmed         │                  [~440ms]        │
│   │           │   (signature + slot)       │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Save to PostgreSQL │                                                        │
│   │ │ • meters table     │                                                        │
│   │ │ • link to user_id  │                                                        │
│   │ │ • pda_address      │                                                        │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Emit Kafka Event   │  - ─ ─▶ meter.registered                          │
│   │ │ (async)            │         (event sourcing)                           │
│   │ └────────────────────┘                 │                                  │
│   └───────────────────┬───────────────────┘                                  │
│                       │                                                       │
│       ◀───────────────┘                                                       │
│       │ 201 Created                                                           │
│       │ { meter_id, pda_address, tx_signature, slot }                         │
│       ▼                                                                         │
│   ┌───────┐                                                                     │
│   │  End  │                                                                     │
│   └───────┘                                                                     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Process Metrics - P2

| Metric | Value | Notes |
|--------|-------|-------|
| Average Latency | ~550ms | 1 Solana TX + 2 PDA reads + DB |
| PDA Read (User) | <20ms | Cached RPC call |
| PDA Create (Meter) | ~440ms | Single block confirmation |
| DB Write | <10ms | INSERT with FK constraint |
| Kafka Publish | <5ms | Async, non-blocking |
| Success Rate | 99.5% | Excluding duplicates |
| Max Meters/User | 100 | Protocol-level limit |

### 3.3 Exception Flow - P2

```
EXCEPTION PATHS:
═══════════════════════════════════════════════════════════════════════════════════

⚠ ERR: User PDA Not Found
   → IAM Service cannot locate user on-chain [~20ms]
   → Returns 404 with suggestion to complete onboarding
   → User must complete P1 first

⚠ ERR: Duplicate Meter ID
   → Check against existing meter PDAs [~30ms]
   → Returns 409 with existing meter details
   → User must provide unique meter ID

⚠ ERR: Invalid Meter Type
   → Validation rejects unknown type [~5ms]
   → Returns 400 with allowed types: [SOLAR, WIND, BATTERY, HYDRO]
   → User selects valid type

⚠ ERR: Solana TX Failure (Meter Creation)
   → register_meter() instruction fails [~440ms timeout]
   → Retry with backoff (3 attempts, 1s/2s/4s)
   → After max: 503 returned, async reconciliation worker retries

⚠ ERR: Capacity Out of Range
   → Validation: capacity_kw must be 0.1 - 10000 [~5ms]
   → Returns 400 with valid range
   → User provides corrected capacity
```

---

## 4. P3: Energy Recording (Smart Meter Reading)

### 4.1 Main Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  P3: ENERGY RECORDING - SWIMLANE DIAGRAM                                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   SMART METER       EDGE GATEWAY      ORACLE BRIDGE      API SERVICES            │
│                                                                                 │
│   ┌───────┐                                                                     │
│   │ Start │                                                                     │
│   │(Cycle)│                                                                     │
│   └───┬───┘                                                                     │
│       │                                                                         │
│       │ 1. Generate Reading (every 5-15 min)                       [instant]    │
│       ▼                                                                         │
│   ┌───────────┐                                                                 │
│   │ Measure:  │                                                                 │
│   │ • kWh_prod│                                                                 │
│   │ • kWh_cons│                                                                 │
│   │ • voltage │                                                                 │
│   │ • current │                                                                 │
│   │ • timestamp│                                                                │
│   └─────┬─────┘                                                                 │
│         │                                                                       │
│         │ 2. Sign Payload (Ed25519)                                [<5ms]       │
│         ▼                                                                       │
│   ┌───────────┐                                                                 │
│   │ Create    │                                                                 │
│   │ Ed25519   │                                                                 │
│   │ Signature │                                                                 │
│   │ over hash │                                                                 │
│   │(payload)  │                                                                 │
│   └─────┬─────┘                                                                 │
│         │                                                                       │
│         │ 3. HTTP POST /telemetry                                  [<100ms]     │
│         ▼                                                                       │
│   ┌───────────┐         │                                                       │
│   │ Send to   │─────────▶                                                        │
│   │ Edge GW   │         │                                                       │
│   └───────────┘         ▼                                                       │
│                    ┌────────────────────┐                                       │
│                    │ Verify Ed25519     │                     [<10ms]           │
│                    │ Signature          │                                       │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│                    ┌───────┴───────┐                                            │
│                    │    ?Valid?    │───No──▶ 401 Unauthorized, Log Security    │
│                    └───────┬───────┘                                            │
│                          │ Yes                                                 │
│                          ▼                                                     │
│                    ┌────────────────────┐                                       │
│                    │ Validate Reading   │                                        │
│                    │ • Timestamp age    │                                        │
│                    │   < 60s            │                                        │
│                    │ • Not duplicate    │                                        │
│                    │   (idempotency)    │                                        │
│                    │ • Values in range  │                                        │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│                    ┌───────┴───────┐                                            │
│                    │  ?All Valid?  │───No──▶ 400 Bad Reading, Meter Alert      │
│                    └───────┬───────┘                                            │
│                          │ Yes                                                 │
│                          ▼                                                     │
│                    │ gRPC: SubmitReading                  [~50ms]             │
│                    ▼                                                       │
│   ┌─────────────────────────────────────────┐                                  │
│   │          ORACLE SERVICE                │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Resolve Meter PDA  │──────▶ Solana: get_meter_pda()                     │
│   │ │ from meter_id      │         (Registry Program)                         │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Build TX:          │                                                        │
│   │ │ submit_reading()   │───────────────▶ Update Meter PDA  [~440ms]          │
│   │ │ Accounts:          │         Sets: cumulative_kwh, last_reading_ts       │
│   │ │  [meter_pda,       │                                                       │
│   │ │   oracle_authority]│                                                        │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           │ ◀──── TX Confirmed         │                  [~440ms]        │
│   │           │   (signature + slot)       │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Store Reading in   │                                                        │
│   │ │ PostgreSQL         │                                                        │
│   │ │ • meter_readings   │                                                        │
│   │ │   table            │                                                        │
│   │ │ • minted = FALSE   │                                                        │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           │ - ─ ─▶ reading.recorded   │                                    │
│   │           │      (Kafka event)         │                                    │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Confidence Score   │                                                        │
│   │ │ • Update oracle    │                                                        │
│   │ │   trust metric     │                                                        │
│   │ └────────────────────┘                 │                                  │
│   └───────────────────┬───────────────────┘                                  │
│                       │                                                       │
│       ◀───────────────┘                                                       │
│       │ 200 OK                                                                │
│       │ { reading_id, slot, tx_signature, cumulative_kwh }                    │
│       ▼                                                                         │
│   ┌───────┐                                                                     │
│   │  End  │◀──── Next cycle in 5-15 min                                        │
│   └───────┘                                                                     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Process Metrics - P3

| Metric | Value | Notes |
|--------|-------|-------|
| Average Latency | ~500ms | Ed25519 verify + Solana TX + DB |
| Ed25519 Verify | <10ms | Single signature verification |
| Reading Validation | <5ms | In-memory checks |
| Solana TX (submit_reading) | ~440ms | Single block confirmation |
| DB Write | <10ms | INSERT into meter_readings |
| Reading Frequency | 5-15 min | Configurable per meter |
| Daily Readings/Meter | 96-288 | At 5-15 min intervals |
| Throughput | 1000 readings/s | Across all meters |
| Success Rate | 99.9% | Highly reliable pipeline |

### 4.3 Exception Flow - P3

```
EXCEPTION PATHS:
═══════════════════════════════════════════════════════════════════════════════════

⚠ ERR: Invalid Ed25519 Signature
   → Oracle Bridge rejects at gateway [~5ms]
   → Returns 401, logs security event
   → Meter must re-authenticate or rotate keys

⚠ ERR: Stale Reading (timestamp > 60s old)
   → Oracle Bridge rejects [~2ms]
   → Returns 400, meter discards reading
   → No blockchain state affected

⚠ ERR: Duplicate Reading (same reading_id)
   → Idempotency check catches duplicate [~5ms]
   → Returns 200 OK (idempotent), returns existing result
   → Safe for meter to retry

⚠ ERR: Reading Out of Physical Range
   → Validation: kWh must be >= 0, within meter capacity [~5ms]
   → Returns 400, triggers meter health alert
   → Operations team investigates meter malfunction

⚠ ERR: Meter PDA Not Found
   → Oracle Service cannot resolve meter on-chain [~20ms]
   → Returns 404, suggests re-registration (P2)
   → Meter readings queued for retry

⚠ ERR: Solana TX Failure (Reading Submit)
   → submit_reading() fails [~440ms timeout]
   → Oracle Service retries (3 attempts, exponential backoff)
   → After max: reading stored with pending status, background worker retries

⚠ ERR: Oracle Service Unavailable
   → gRPC call times out [>10s]
   → Edge Gateway buffers reading locally
   → Retries on next cycle with batched readings
```

---

## 5. P4: Token Minting (Automated GRID Generation)

### 5.1 Main Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  P4: TOKEN MINTING - SWIMLANE DIAGRAM                                           │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   POLLING SVC       ORACLE SERVICE    ENERGY TOKEN PG   SPL TOKEN PG            │
│   (Scheduler)                                                                   │
│                                                                                 │
│   ┌───────┐                                                                     │
│   │ Start │                                                                     │
│   │(Timer)│  Fires every 30 seconds                                [scheduled]  │
│   └───┬───┘                                                                     │
│       │                                                                         │
│       │ 1. Query Unminted Readings                                 [<50ms]      │
│       ▼                                                                         │
│   ┌────────────────────────┐                                                    │
│   │ SELECT * FROM          │                                                    │
│   │ meter_readings         │                                                    │
│   │ WHERE minted = FALSE   │                                                    │
│   │ AND status = 'settled' │                                                    │
│   │ ORDER BY timestamp ASC │                                                    │
│   │ LIMIT 50               │                                                    │
│   └───────────┬────────────┘                                                    │
│               │                                                                 │
│         ┌─────┴─────┐                                                           │
│         │  ?Has Any? │───No──▶ Sleep 30s, loop back to Start                   │
│         └─────┬─────┘                                                           │
│               │ Yes                                                             │
│               ▼                                                                 │
│         ┌────────────────────┐                                                  │
│         │ Group by           │                                                  │
│         │ meter_id           │                                                  │
│         │ Sum unminted kWh   │                                                  │
│         │ per meter          │                                                  │
│         └─────────┬──────────┘                                                  │
│                   │                                                             │
│                   │ For each meter                                              │
│                   ▼                                                             │
│   ┌──────────────────────────────────────────────────┐                         │
│   │          ORACLE SERVICE                         │                         │
│   │ ┌────────────────────┐                          │                         │
│   │ │ Fetch Meter PDA    │─────▶ Solana: get_meter()                          │
│   │ │ (current state)    │      (Registry Program)                            │
│   │ └─────────┬──────────┘                          │                         │
│   │           │                                     │                         │
│   │           ▼                                     │                         │
│   │ ┌────────────────────┐                          │                         │
│   │ │ Calculate:         │                          │                         │
│   │ │ unminted =         │                          │                         │
│   │ │   cumulative_kwh - │                          │                         │
│   │ │   settled_kwh      │                          │                         │
│   │ └─────────┬──────────┘                          │                         │
│   │           │                                     │                         │
│   │     ┌─────┴─────┐                               │                         │
│   │     │  ?>0 kWh? │───No──▶ Skip this meter       │                         │
│   │     └─────┬─────┘                               │                         │
│   │           │ Yes                                 │                         │
│   │           ▼                                     │                         │
│   │ ┌────────────────────┐                          │                         │
│   │ │ Build TX:          │                          │                         │
│   │ │ mint_from_         │────────────────────────▶ Mint GRID Tokens          │
│   │ │ production()       │         (Energy Token Program)                     │
│   │ │                    │         1 kWh = 1 GRID (1:1 ratio)                 │
│   │ │ Accounts:          │         CPI → SPL Token mint_to()                  │
│   │ │  [meter_pda,       │                                                    │
│   │ │   token_mint,      │                                                    │
│   │ │   user_ata,        │                                                    │
│   │ │   oracle_authority]│                                                    │
│   │ └─────────┬──────────┘                          │                         │
│   │           │                                     │                         │
│   │           │ ◀──── TX Confirmed                  │         [~440ms]        │
│   │           │   (signature + minted_amount)       │                         │
│   │           ▼                                     │                         │
│   │ ┌────────────────────┐                          │                         │
│   │ │ Update PostgreSQL  │                          │                         │
│   │ │ • minted = TRUE    │                          │                         │
│   │ │ • tx_signature     │                          │                         │
│   │ │ • mint_amount      │                          │                         │
│   │ └─────────┬──────────┘                          │                         │
│   │           │                                     │                         │
│   │           │ - ─ ─▶ tokens.minted                │                         │
│   │           │      (Kafka event)                  │                         │
│   │           ▼                                     │                         │
│   │ ┌────────────────────┐                          │                         │
│   │ │ Update Meter PDA   │─────▶ Solana: update     │                         │
│   │ │ settled_kwh +=     │      settled_kwh         │                         │
│   │ │ unminted amount    │                            │                         │
│   │ └────────────────────┘                          │                         │
│   └───────────────────┬─────────────────────────────┘                         │
│                       │                                                       │
│                       │ Continue to next meter                                │
│                       │ (loop until all processed)                            │
│                       ▼                                                       │
│                 ┌──────────────┐                                              │
│                 │ Batch        │                                              │
│                 │ Complete     │                                              │
│                 │ Log Summary: │                                              │
│                 │ • N meters   │                                              │
│                 │ • X GRID     │                                              │
│                 │ • Y TXs      │                                              │
│                 └──────┬───────┘                                              │
│                        │                                                      │
│                        ▼                                                      │
│                 ┌──────────────┐                                              │
│                 │ Sleep 30s    │                                              │
│                 │ Loop to Start│                                              │
│                 └──────────────┘                                              │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Process Metrics - P4

| Metric | Value | Notes |
|--------|-------|-------|
| Polling Interval | 30s | Configurable via env |
| Batch Size | 50 readings | Max per cycle |
| Per-Meter TX Time | ~440ms | Single mint TX |
| Total Cycle Time | ~500ms avg | Depends on batch size |
| Mint Ratio | 1 kWh = 1 GRID | Fixed protocol ratio |
| Success Rate | 99.8% | Retries handle most failures |
| Daily Mint Events | 10K-100K | Depends on active meters |
| Max GRID Supply | Uncapped | Backed 1:1 by renewable kWh |

### 5.3 Exception Flow - P4

```
EXCEPTION PATHS:
═══════════════════════════════════════════════════════════════════════════════════

⚠ ERR: No Unminted Readings
   → Polling query returns empty [~20ms]
   → Normal case: sleep 30s, retry next cycle
   → No action needed

⚠ ERR: Meter Has Zero Unminted kWh
   → cumulative_kwh == settled_kwh [~5ms]
   → Skip this meter, continue to next
   → Reading was likely minted in prior cycle

⚠ ERR: Token Mint Authority Invalid
   → Oracle Service authority key mismatch [~440ms]
   → TX fails, returns error
   → Admin must rotate oracle authority key on-chain

⚠ ERR: SPL Token Mint Failure
   → SPL mint_to() fails (frozen account, wrong mint) [~440ms]
   → TX rolls back, no state change
   → Admin investigates token mint configuration

⚠ ERR: Solana TX Timeout
   → Mint TX does not confirm within timeout [>10s]
   → Oracle Service retries (3 attempts)
   → After max: readings remain unminted, next cycle retries

⚠ ERR: Database Update Fails After Successful Mint
   → Critical: tokens minted but DB not updated [~10ms]
   → Reconciliation job detects mismatch
   → Auto-corrects minted flag from on-chain state
```

---

## 6. P5: Create Sell Order

### 6.1 Main Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  P5: CREATE SELL ORDER - SWIMLANE DIAGRAM                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   PROSUMER          FRONTEND         TRADING SERVICE      BLOCKCHAIN            │
│                                                                                 │
│   ┌───────┐                                                                     │
│   │ Start │                                                                     │
│   └───┬───┘                                                                     │
│       │                                                                         │
│       │ 1. Enter Order Details                                     [<10s]       │
│       ▼                                                                         │
│   ┌───────────┐                                                                 │
│   │ Amount:   │                                                                 │
│   │  kWh to   │                                                                 │
│   │  sell     │                                                                 │
│   │ Price:    │                                                                 │
│   │  GRX/kWh  │                                                                 │
│   │ ERC:      │                                                                 │
│   │  optional │                                                                 │
│   └─────┬─────┘                                                                 │
│         │                                                                       │
│         │ 2. Review & Sign TX                                      [<30s]       │
│         ▼                                                                       │
│   ┌───────────┐                                                                 │
│   │ Wallet    │─────▶ Simulate TX (dry run)                        [<200ms]     │
│   │ Popup     │       Check balances, validate params                           │
│   └───────────┘         │                                                       │
│                   ┌─────┴─────┐                                                 │
│                   │?Simulate  │───Fail──▶ Show Error, Abort                     │
│                   │  OK?      │                                                 │
│                   └─────┬─────┘                                                 │
│                         │ OK                                                    │
│                         ▼                                                       │
│                   ┌────────────────────┐                                        │
│                   │ User Signs TX      │                                        │
│                   │ (Phantom/Solflare) │                                        │
│                   └─────────┬──────────┘                                        │
│                         │                                                       │
│                         │ Signed TX + Order Params                              │
│                         ▼                                  [~440ms]            │
│   ┌───────────────────────────────────────────────┐                            │
│   │          TRADING SERVICE                     │                            │
│   │ ┌────────────────────┐                       │                            │
│   │ │ Validate Order     │                       │                            │
│   │ │ • Amount > 0       │                       │                            │
│   │ │ • Price > 0        │                       │                            │
│   │ │ • Seller has GRID  │                       │                            │
│   │ │   balance >= amount│                       │                            │
│   │ └─────────┬──────────┘                       │                            │
│   │           │                                  │                            │
│   │     ┌─────┴─────┐                            │                            │
│   │     │ ?All Valid?│───No──▶ 400 Invalid Order │                            │
│   │     └─────┬─────┘                            │                            │
│   │           │ Yes                              │                            │
│   │           ▼                                  │                            │
│   │ ┌────────────────────┐                       │                            │
│   │ │ If ERC Included:   │                       │                            │
│   │ │ • Verify ERC PDA   │                       │                            │
│   │ │ • Check status     │                       │                            │
│   │ │   = VALID          │                       │                            │
│   │ │ • Check not expired│                       │                            │
│   │ │ • Check amount     │                       │                            │
│   │ │   covers order     │                       │                            │
│   │ └─────────┬──────────┘                       │                            │
│   │           │                                  │                            │
│   │           ▼ (ERC or no ERC)                  │                            │
│   │ ┌────────────────────┐                       │                            │
│   │ │ Build TX:          │                       │                            │
│   │ │ create_sell_order()│─────────────────────▶ Create Order PDA             │
│   │ │                    │         (Trading Program)                          │
│   │ │ Seeds: [prefix,    │         CPI: Transfer GRID to Escrow PDA          │
│   │ │  order_id]         │         Accounts: [order_pda, seller_ata,         │
│   │ │                    │          escrow_ata, token_mint, signer]           │
│   │ └─────────┬──────────┘                       │                            │
│   │           │                                  │                            │
│   │           │ ◀──── TX Confirmed               │            [~440ms]        │
│   │           │   (order_pda, tx_sig)            │                            │
│   │           ▼                                  │                            │
│   │ ┌────────────────────┐                       │                            │
│   │ │ Update Order Book  │                       │                            │
│   │ │ (in-memory + Redis)│                       │                            │
│   │ │ • Add to price     │                       │                            │
│   │ │   level            │                       │                            │
│   │ │ • Broadcast via    │                       │                            │
│   │ │   WebSocket        │                       │                            │
│   │ └─────────┬──────────┘                       │                            │
│   │           │                                  │                            │
│   │           │ - ─ ─▶ order.created             │                            │
│   │           │      (Kafka + RabbitMQ)          │                            │
│   │           ▼                                  │                            │
│   │ ┌────────────────────┐                       │                            │
│   │ │ Persist to DB      │                       │                            │
│   │ │ • orders table     │                       │                            │
│   │ │ • status = ACTIVE  │                       │                            │
│   │ └────────────────────┘                       │                            │
│   └───────────────────┬──────────────────────────┘                            │
│                       │                                                       │
│       ◀───────────────┘                                                       │
│       │ 201 Created                                                           │
│       │ { order_id, order_pda, tx_signature, status: "ACTIVE" }               │
│       ▼                                                                         │
│   ┌───────┐                                                                     │
│   │  End  │◀──── Order now visible in order book                               │
│   └───────┘                                                                     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Process Metrics - P5

| Metric | Value | Notes |
|--------|-------|-------|
| Average Latency | ~600ms | Validation + Solana TX + order book update |
| TX Simulation | <200ms | Dry run on frontend |
| User Signing | <30s | Depends on user interaction |
| Solana TX (create order) | ~440ms | Includes CPI to SPL Token |
| Order Book Update | <5ms | In-memory + Redis |
| Kafka Publish | <5ms | Async, non-blocking |
| Success Rate | 99.5% | Most failures are insufficient balance |
| Active Orders | ~1000 | Typical concurrent orders |

### 6.3 Exception Flow - P5

```
EXCEPTION PATHS:
═══════════════════════════════════════════════════════════════════════════════════

⚠ ERR: Insufficient GRID Balance
   → Trading Service checks balance before TX [~10ms]
   → Returns 400 with required vs available amount
   → User must acquire more GRID tokens or reduce order

⚠ ERR: Invalid ERC Certificate
   → ERC verification fails (expired, invalid, insufficient) [~30ms]
   → Returns 400 with ERC error details
   → User removes ERC from order or obtains valid certificate

⚠ ERR: TX Simulation Failed
   → Frontend dry run fails [~200ms]
   → Shows specific error (balance, authority, program error)
   → User corrects order parameters

⚠ ERR: User Rejects TX in Wallet
   → Wallet popup cancelled by user [variable]
   → Frontend returns 400, no server-side state
   → User can retry

⚠ ERR: Solana TX Timeout
   → create_sell_order() does not confirm [>10s]
   → Trading Service retries (3 attempts)
   → After max: checks if order PDA was created (idempotent check)
   → If created: returns success with existing order
   → If not: returns 503, async worker retries

⚠ ERR: Duplicate Order ID
   → Order PDA already exists (collision) [~440ms]
   → Extremely rare (PDA seeds are unique)
   → Returns error, generates new order ID, retries
```

---

## 7. P6: Match Orders (CDA Order Book)

### 7.1 Main Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  P6: MATCH ORDERS (CDA ORDER BOOK) - SWIMLANE DIAGRAM                           │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   CONSUMER          FRONTEND         TRADING SERVICE      SELLER               │
│                                                                                 │
│   ┌───────┐                                                                     │
│   │ Start │                                                                     │
│   └───┬───┘                                                                     │
│       │                                                                         │
│       │ 1. Browse Order Book                                       [<100ms]     │
│       ▼                                                                         │
│   ┌───────────┐         │                                                       │
│   │ GET       │─────────▶                                                        │
│   │ /api/v1/  │         │                                                       │
│   │ orders    │         │                                                       │
│   └───────────┘         ▼                                                       │
│                    ┌────────────────────┐                                       │
│                    │ Fetch Order Book   │                     [<10ms]           │
│                    │ (Redis Sorted Set) │         Sorted by price ASC           │
│                    │ Best sell orders   │                                       │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│       ◀──────────────────┘                                                     │
│       │ 200 OK: [{order_id, price, amount, seller}, ...]                       │
│       ▼                                                                         │
│   ┌───────────┐                                                                 │
│   │ Display   │                                                                 │
│   │ Order Book│                                                                 │
│   │ UI Table  │                                                                 │
│   └─────┬─────┘                                                                 │
│         │                                                                       │
│         │ 2. Select Order to Buy                                   [<30s]       │
│         ▼                                                                       │
│   ┌───────────┐                                                                 │
│   │ Select    │                                                                 │
│   │ Order #1  │                                                                 │
│   │ 10 kWh    │                                                                 │
│   │ @ 3 GRX   │                                                                 │
│   └─────┬─────┘                                                                 │
│         │                                                                       │
│         │ 3. Sign Match TX                                         [<30s]       │
│         ▼                                                                       │
│   ┌───────────┐                                                                 │
│   │ Wallet    │─────▶ Simulate match_order()                       [<200ms]     │
│   │ Popup     │       Check GRX balance, order availability                     │
│   └───────────┘         │                                                       │
│                   ┌─────┴─────┐                                                 │
│                   │?Simulate  │───Fail──▶ Show Error, Abort                     │
│                   │  OK?      │                                                 │
│                   └─────┬─────┘                                                 │
│                         │ OK                                                    │
│                         ▼                                                       │
│                   ┌────────────────────┐                                        │
│                   │ User Signs TX      │                                        │
│                   │ (Phantom/Solflare) │                                        │
│                   └─────────┬──────────┘                                        │
│                         │                                                       │
│                         │ Signed TX + {order_id, buy_amount}                    │
│                         ▼                                  [~600ms]            │
│   ┌───────────────────────────────────────────────┐                            │
│   │          TRADING SERVICE                     │                            │
│   │ ┌────────────────────┐                       │                            │
│   │ │ Validate Match     │                       │                            │
│   │ │ • Order exists     │                       │                            │
│   │ │ • Order = ACTIVE   │                       │                            │
│   │ │ • Not self-trade   │                       │                            │
│   │ │ • Buyer has GRX    │                       │                            │
│   │ │   balance          │                       │                            │
│   │ └─────────┬──────────┘                       │                            │
│   │           │                                  │                            │
│   │     ┌─────┴─────┐                            │                            │
│   │     │ ?All Valid?│───No──▶ 400 Invalid Match │                            │
│   │     └─────┬─────┘                            │                            │
│   │           │ Yes                              │                            │
│   │           ▼                                  │                            │
│   │ ┌────────────────────┐                       │                            │
│   │ │ Determine Match    │                       │                            │
│   │ │ Quantity:          │                       │                            │
│   │ │   min(order_amt,   │                       │                            │
│   │ │       buy_amt)     │                       │                            │
│   │ │ Calculate:         │                       │                            │
│   │ │   total_cost =     │                       │                            │
│   │ │   qty × sell_price │                       │                            │
│   │ └─────────┬──────────┘                       │                            │
│   │           │                                  │                            │
│   │           ▼                                  │                            │
│   │ ╔═══════════════════════════════════════╗    │                            │
│   │ ║  ATOMIC SETTLEMENT (Phase 1-3)      ║    │                            │
│   │ ║  See P7: Atomic Settlement diagram    ║    │                            │
│   │ ║                                       ║    │                            │
│   │ ║  Phase 1: Release GRID from Escrow    ║    │                            │
│   │ ║           → Buyer ATA                 ║    │                            │
│   │ ║  Phase 2: Transfer GRX from Buyer     ║    │                            │
│   │ ║           → Seller ATA                ║    │                            │
│   │ ║  Phase 3: Update Order Status         ║    │                            │
│   │ ║           → FILLED or PARTIALLY_FILLED║    │                            │
│   │ ╚═══════════════╤═══════════════════════╝    │                            │
│   │                 │                            │                            │
│   │                 │ ◀──── TX Confirmed         │            [~440ms]        │
│   │                 │   (trade details)          │                            │
│   │                 ▼                            │                            │
│   │ ┌────────────────────┐                       │                            │
│   │ │ Update Order Book  │                       │                            │
│   │ │ • Remove/Update    │                       │                            │
│   │ │   filled order     │                       │                            │
│   │ │ • Emit trade event │                       │                            │
│   │ └─────────┬──────────┘                       │                            │
│   │           │                                  │                            │
│   │           │ - ─ ─▶ trade.executed            │                            │
│   │           │      (Kafka + RabbitMQ + Redis)  │                            │
│   │           ▼                                  │                            │
│   │ ┌────────────────────┐                       │                            │
│   │ │ Persist Trade      │                       │                            │
│   │ │ • trades table     │                       │                            │
│   │ │ • Update order     │                       │                            │
│   │ │   status           │                       │                            │
│   │ └────────────────────┘                       │                            │
│   └───────────────────┬──────────────────────────┘                            │
│                       │                                                       │
│       ◀───────────────┘                                                       │
│       │ 200 OK                                                                │
│       │ { trade_id, qty, price, total_cost, order_status }                    │
│       ▼                                                                         │
│   ┌───────┐                                                                     │
│   │  End  │◀──── Trade settled atomically                                       │
│   └───────┘                                                                     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Process Metrics - P6

| Metric | Value | Notes |
|--------|-------|-------|
| Order Book Fetch | <10ms | Redis Sorted Set |
| TX Simulation | <200ms | Frontend dry run |
| User Signing | <30s | Depends on user |
| Match Validation | <10ms | In-memory checks |
| Atomic Settlement TX | ~440ms | 3-phase atomic TX |
| Total Match Latency | ~600ms | Excluding user signing |
| Match Success Rate | 99.3% | Mostly balance issues |
| Order Book Depth | 50-200 orders | Active market |
| Daily Trade Volume | 500-2000 trades | Varies by time |

### 7.3 Exception Flow - P6

```
EXCEPTION PATHS:
═══════════════════════════════════════════════════════════════════════════════════

⚠ ERR: Order Already Filled/Cancelled
   → Trading Service checks order status [~5ms]
   → Returns 400 with current order status
   → Consumer selects different order

⚠ ERR: Self-Trade Detected
   → Buyer wallet == Seller wallet check [~5ms]
   → Returns 400, self-trade prohibited
   → Consumer cannot trade own orders

⚠ ERR: Insufficient GRX Balance
   → Trading Service checks buyer GRX [~10ms]
   → Returns 400 with required vs available
   → Consumer must acquire more GRX or reduce amount

⚠ ERR: Order Partially Available
   → Order has less remaining quantity than requested [~5ms]
   → Match proceeds with available quantity (partial fill)
   → Returns trade with actual filled quantity

⚠ ERR: Order Book Stale
   → Redis cache miss, fallback to DB [~50ms]
   → Returns slightly stale data (<1s old)
   → Refresh triggered for next request

⚠ ERR: Atomic Settlement TX Fails
   → Multi-phase TX fails mid-execution [~440ms]
   → Entire TX rolls back (Solana atomicity)
   → Trading Service retries (3 attempts)
   → After max: async worker retries, order remains ACTIVE
```

---

## 8. P7: Atomic Settlement

### 8.1 Main Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  P7: ATOMIC SETTLEMENT - SWIMLANE DIAGRAM                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   BUYER             TRADING PROGRAM   ESCROW PDA         SELLER                │
│   (GRX Payer)       (Solana)          (GRID Holder)      (GRID Receiver)       │
│                                                                                 │
│   ┌───────┐                                                                     │
│   │ Start │  Triggered by match_order() instruction                [TX entry]   │
│   └───┬───┘                                                                     │
│       │                                                                         │
│       │ ╔═══════════════════════════════════════════════════════════════╗       │
│       │ ║            ATOMIC TRANSACTION (All-or-Nothing)               ║       │
│       │ ╚═══════════════════════════════════════════════════════════════╝       │
│       │                                                                         │
│       │ PHASE 1: Release GRID from Escrow to Buyer                 [~150ms]     │
│       ▼                                                                         │
│   ┌──────────────────────┐                                                      │
│   │ CPI: spl_token::     │                                                      │
│   │ transfer_checked()   │                                                      │
│   │ From: escrow_ata     │────────────────────────────────▶ GRID tokens flow    │
│   │ To: buyer_ata        │         (escrow → buyer)                             │
│   │ Amount: match_qty    │                                                      │
│   │ Authority: order_pda │                                                      │
│   └──────────┬───────────┘                                                      │
│              │                                                                 │
│        ┌─────┴─────┐                                                           │
│        │ ?Transfer │───Fail──▶ TX ABORT (all changes rolled back)              │
│        │  OK?      │         Error: insufficient escrow, wrong authority       │
│        └─────┬─────┘                                                           │
│              │ OK                                                              │
│              ▼                                                                 │
│       PHASE 2: Transfer GRX from Buyer to Seller                  [~150ms]     │
│   ┌──────────────────────┐                                                      │
│   │ CPI: spl_token::     │                                                      │
│   │ transfer_checked()   │                                                      │
│   │ From: buyer_ata      │                                                      │
│   │ To: seller_ata       │◀────────────────────────────── GRX tokens flow       │
│   │ Amount: match_qty ×  │         (buyer → seller)                             │
│   │  price               │                                                      │
│   │ Authority: buyer_sig │         (signed by buyer in TX)                     │
│   └──────────┬───────────┘                                                      │
│              │                                                                 │
│        ┌─────┴─────┐                                                           │
│        │ ?Transfer │───Fail──▶ TX ABORT (GRID also rolled back)                │
│        │  OK?      │         Error: insufficient GRX, wrong authority          │
│        └─────┬─────┘                                                           │
│              │ OK                                                              │
│              ▼                                                                 │
│       PHASE 3: Update Order Status                                [<50ms]      │
│   ┌──────────────────────┐                                                      │
│   │ Update Order PDA:    │                                                      │
│   │ • filled_qty += qty  │                                                      │
│   │ • If filled == total:│                                                     │
│   │     status = FILLED  │                                                      │
│   │   Else:              │                                                      │
│   │     status =         │                                                      │
│   │     PARTIALLY_FILLED │                                                      │
│   │ • last_trade_ts = now│                                                      │
│   └──────────┬───────────┘                                                      │
│              │                                                                 │
│              ▼                                                                 │
│       PHASE 4: Emit Trade Event                                   [<10ms]      │
│   ┌──────────────────────┐                                                      │
│   │ emit TradeExecuted   │                                                      │
│   │ event with:          │                                                      │
│   │ • trade_id           │                                                      │
│   │ • order_id           │                                                      │
│   │ • buyer, seller      │                                                      │
│   │ • qty, price, total  │                                                      │
│   │ • timestamp          │                                                      │
│   └──────────┬───────────┘                                                      │
│              │                                                                 │
│              ▼                                                                 │
│       ╔═══════════════════════════════════════════════════════════════╗        │
│       ║  TRANSACTION COMPLETE - All phases succeeded atomically       ║        │
│       ║  If ANY phase failed, ALL changes are rolled back             ║        │
│       ╚═══════════════════════════════════════════════════════════════╝        │
│              │                                                                 │
│              ▼                                                                 │
│         ┌────────┐                                                             │
│         │ Return │◀──── TX Signature + Trade Details                           │
│         │ Success│                                                              │
│         └────────┘                                                             │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Process Metrics - P7

| Metric | Value | Notes |
|--------|-------|-------|
| Phase 1 (GRID transfer) | ~150ms | CPI spl_token transfer |
| Phase 2 (GRX transfer) | ~150ms | CPI spl_token transfer |
| Phase 3 (Order update) | <50ms | PDA state update |
| Phase 4 (Event emit) | <10ms | Solana log event |
| Total TX Time | ~440ms | Single block confirmation |
| Rollback on Failure | 100% | Solana guarantees atomicity |
| Success Rate | 99.7% | After pre-validation |
| Gas Fee | ~0.000005 SOL | Very low on Solana |
| Priority Fee | ~0.00001 SOL | Optional, during congestion |

### 8.3 Exception Flow - P7

```
EXCEPTION PATHS:
═══════════════════════════════════════════════════════════════════════════════════

⚠ ERR: Phase 1 Fails (GRID Transfer from Escrow)
   → Escrow has insufficient GRID tokens [~150ms]
   → Entire TX aborts: no GRID moves, no GRX moves, no state change
   → Trading Service detects via simulation before submission
   → If reaches chain: order marked as problematic, admin alert

⚠ ERR: Phase 2 Fails (GRX Transfer from Buyer)
   → Buyer has insufficient GRX tokens [~150ms]
   → Entire TX aborts: GRID transfer from Phase 1 also rolled back
   → Solana's transaction model guarantees all-or-nothing
   → Pre-validation should catch this before TX submission

⚠ ERR: Phase 3 Fails (Order Update)
   → PDA account space or permission error [<50ms]
   → Entire TX aborts: both token transfers rolled back
   → Critical bug if reached; indicates program logic error

⚠ ERR: Transaction Expiry
   → Blockhash expired before confirmation [>15s]
   → Entire TX discarded, no state change on-chain
   → Trading Service retries with fresh blockhash (3 attempts)

⚠ ERR: Concurrent Match on Same Order
   → Two buyers match same order simultaneously [~440ms]
   → Second TX fails: order already filled by first TX
   → Solana's sequential processing prevents double-spend
   → Second buyer receives error, can match next best order

⚠ ERR: Priority Fee Too Low (Congestion)
   → TX lands in block too slowly [>10s]
   → Blockhash expires, TX discarded
   → Retry with higher priority fee
```

---

## 9. P8: ERC Certificate Issuance

### 9.1 Main Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  P8: ERC CERTIFICATE ISSUANCE - SWIMLANE DIAGRAM                                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   PROSUMER          API SERVICES     GOVERNANCE SVC     BLOCKCHAIN               │
│                                                                                 │
│   ┌───────┐                                                                     │
│   │ Start │                                                                     │
│   └───┬───┘                                                                     │
│       │                                                                         │
│       │ 1. Request ERC Certificate                                 [<5s]        │
│       ▼                                                                         │
│   ┌───────────┐                                                                 │
│   │ Select    │                                                                 │
│   │ Settled   │                                                                 │
│   │ Energy    │                                                                 │
│   │ Amount    │─────▶ POST /api/v1/erc-certificates                             │
│   │ Source    │       Headers: Authorization: Bearer <JWT>                      │
│   │ (Meter)   │       Body: { meter_id, energy_kwh, period_start, period_end }  │
│   └───────────┘         │                                                       │
│                         ▼                                                       │
│                    ┌────────────────────┐                                       │
│                    │ Authenticate JWT   │                     [<10ms]           │
│                    │ Extract user_id    │                                       │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│                          ▼                                                     │
│                    │ gRPC: IssueERC                       [~500ms]            │
│                    ▼                                                       │
│   ┌─────────────────────────────────────────┐                                  │
│   │       GOVERNANCE / ORACLE SERVICE       │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Resolve Meter PDA  │─────▶ Solana: get_meter_pda()                      │
│   │ │                    │      (Registry Program)                             │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Verify Production  │                                                        │
│   │ │ Data:              │                                                        │
│   │ │ • Energy produced  │                                                        │
│   │ │   in period        │                                                        │
│   │ │ • >= requested     │                                                        │
│   │ │   certificate amt  │                                                        │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │     ┌─────┴─────┐                                                          │
│   │     │ ?Sufficient│───No──▶ 400 Insufficient Production                     │
│   │     │ Production?│                                                          │
│   │     └─────┬─────┘                                                          │
│   │           │ Yes                                                            │
│   │           ▼                                                                │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Check ERC History  │                                                        │
│   │ │ • claimed_erc_gen  │                                                        │
│   │ │   on meter PDA     │                                                        │
│   │ │ • Available =      │                                                        │
│   │ │   produced -       │                                                        │
│   │ │   claimed          │                                                        │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │     ┌─────┴─────┐                                                          │
│   │     │?Available │───No──▶ 400 Already Claimed for ERC                     │
│   │     │  > 0?      │                                                         │
│   │     └─────┬─────┘                                                          │
│   │           │ Yes                                                            │
│   │           ▼                                                                │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Build TX:          │                                                        │
│   │ │ issue_erc()        │───────────────▶ Create ERC PDA      [~440ms]        │
│   │ │                    │         (Governance Program)                         │
│   │ │ Seeds: [prefix,    │         Sets: status=PENDING, energy_kwh,           │
│   │ │  erc_id]           │          expiry_date, validated_for_trading=FALSE   │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           │ ◀──── TX Confirmed         │                  [~440ms]        │
│   │           │   (erc_pda, tx_sig)        │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Update Meter PDA:  │─────▶ Solana: update                               │
│   │ │ claimed_erc_gen += │      claimed_erc_gen                               │
│   │ │ certificate amount │                            │                         │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Save to PostgreSQL │                                                        │
│   │ │ • erc_certificates │                                                        │
│   │ │   table            │                                                        │
│   │ │ • status = PENDING │                                                        │
│   │ └─────────┬──────────┘                 │                                  │
│   │           │                            │                                  │
│   │           │ - ─ ─▶ erc.issued          │                                    │
│   │           │      (Kafka event)         │                                    │
│   │           ▼                            │                                  │
│   │ ┌────────────────────┐                 │                                  │
│   │ │ Validation Queue   │  - ─ ─▶ Background validation                      │
│   │ │ (async)            │         process will set                          │
│   │ │                    │         validated_for_trading                     │
│   │ └────────────────────┘                 │                                  │
│   └───────────────────┬───────────────────┘                                  │
│                       │                                                       │
│       ◀───────────────┘                                                       │
│       │ 201 Created                                                           │
│       │ { erc_id, erc_pda, status: "PENDING", tx_signature }                  │
│       ▼                                                                         │
│   ┌───────┐                                                                     │
│   │  End  │◀──── Certificate issued, pending validation                        │
│   └───────┘                                                                     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 9.2 Process Metrics - P8

| Metric | Value | Notes |
|--------|-------|-------|
| Average Latency | ~550ms | 2 Solana TXs + DB + validation |
| Meter PDA Read | <20ms | RPC call |
| Production Verification | <30ms | DB query + calculation |
| ERC PDA Create | ~440ms | Single block confirmation |
| Meter PDA Update | ~440ms | Second TX (can be batched) |
| DB Write | <10ms | INSERT into erc_certificates |
| Success Rate | 99.4% | Most failures are insufficient production |
| Validation Time | <5 min | Async background process |
| ERC Expiry | 12 months | From issuance date |

### 9.3 Exception Flow - P8

```
EXCEPTION PATHS:
═══════════════════════════════════════════════════════════════════════════════════

⚠ ERR: Insufficient Production
   → Meter produced < requested ERC amount [~30ms]
   → Returns 400 with available production amount
   → User reduces requested amount or waits for more production

⚠ ERR: Energy Already Claimed for ERC
   → claimed_erc_gen >= produced on meter PDA [~20ms]
   → Returns 400 with already-claimed amount
   → User can only claim unclaimed production

⚠ ERR: Meter PDA Not Found
   → Cannot resolve meter on-chain [~20ms]
   → Returns 404, suggests re-registration (P2)
   → User must register meter first

⚠ ERR: Period Overlaps Existing ERC
   → Overlapping period_start/period_end check [~10ms]
   → Returns 409 with existing ERC details
   → User adjusts period or uses existing ERC

⚠ ERR: Solana TX Failure (ERC Creation)
   → issue_erc() instruction fails [~440ms timeout]
   → Governance Service retries (3 attempts)
   → After max: returns 503, async worker retries

⚠ ERR: Async Validation Fails
   → Background validation detects data mismatch [variable]
   → ERC status set to REJECTED
   → User notified, can re-submit with corrected data
```

---

## 10. Complete End-to-End Flow

### 10.1 Daily Trading Cycle

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     COMPLETE DAILY TRADING CYCLE                                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   TIME     PROSUMER              PLATFORM                CONSUMER               │
│                                                                                 │
│   06:00    ┌─────────────┐                                                      │
│   AM       │ Solar Start │                                                      │
│            │ Production  │                                                      │
│            └──────┬──────┘                                                      │
│                   │ [P3: Energy Recording]                                      │
│   08:00          │       ┌──────────────────────────┐                           │
│   AM             ▼       │ Smart meter reading      │                           │
│            ┌─────────────┤→ Edge Gateway            │                           │
│            │ Meter       │→ Oracle Bridge            │                           │
│            │ Reading #1  │→ Oracle Svc               │                           │
│            │ 5 kWh       │→ Solana: submit_reading() │                           │
│            └──────┬──────┤  [~500ms total]           │                           │
│                   │       └──────────────────────────┘                           │
│                   ▼                                                               │
│            ┌─────────────┐                                                        │
│            │ Surplus:    │                                                        │
│            │ 3 kWh       │                                                        │
│            └──────┬──────┘                                                        │
│                   │                                                               │
│   10:00          │       ┌──────────────────────────┐                            │
│   AM             ▼       │ [P4: Token Minting]      │                            │
│            ┌─────────────┤ Polling svc detects      │                            │
│            │ Meter       │ unminted readings        │                            │
│            │ Reading #2  │→ Oracle Svc: settle_meter│                            │
│            │ 10 kWh      │→ Energy Token: mint()    │                            │
│            └──────┬──────┤  11 GRID (3+8 surplus)   │                            │
│                   │       │  [~500ms per meter]      │                            │
│                   │       └──────────────────────────┘                            │
│                   ▼                                                               │
│            ┌─────────────┐                                                        │
│            │ Check       │                                                        │
│            │ Balance:    │                                                        │
│            │ 11 GRID     │                                                        │
│            └──────┬──────┘                                                        │
│                   │                                                               │
│            ┌──────┴──────┐                                                        │
│            │ [P5: Create  │                                                        │
│            │  Sell Order] │                                                        │
│            │ 8 GRID      │                                                        │
│            │ @ 3 GRX/kWh │──────▶ Order Active in Order Book                     │
│            │ ERC: optional│     [~600ms + user signing]                          │
│            └──────┬──────┘                                                        │
│                   │                                                               │
│   12:00          │                ┌──────────────────────────┐                   │
│   PM             │                │ Order Book Updated        │                   │
│                   │                │ → Redis Sorted Set        │                   │
│                   │                │ → WebSocket Broadcast     │                   │
│                   │                └────────┬─────────────────┘                   │
│                   │                         │                                     │
│   01:00          │                         │       ┌─────────────┐              │
│   PM             │                         │       │ Browse      │              │
│                   │                         │◀──────│ Order Book  │              │
│                   │                         │       │ [GET /orders│              │
│                   │                         │       │  <100ms]    │              │
│                   │                         │       └─────────────┘              │
│                   │                         │              │                     │
│                   │                         │       ┌──────┴──────┐             │
│                   │                         │       │ Select 8    │             │
│                   │                         │       │ GRID @ 3GRX │             │
│                   │                         │       └──────┬──────┘             │
│                   │                         │              │                     │
│                   │                ┌────────▼──────────────┤                     │
│                   │                │ [P6: Match Orders]    │                     │
│                   │                │ [P7: Atomic           │                     │
│                   │                │  Settlement]          │                     │
│                   │                │ → Trading Program     │                     │
│                   │                │ → Phase 1: GRID       │                     │
│                   │                │   Escrow → Buyer      │                     │
│                   │                │ → Phase 2: GRX        │                     │
│                   │                │   Buyer → Seller      │                     │
│                   │                │ → Phase 3: Order      │                     │
│                   │                │   Status = FILLED     │                     │
│                   │                │  [~600ms total]       │                     │
│                   │                └───────────────────────┘                     │
│                   │                         │                                    │
│   01:05   ┌──────┴──────┐                  │       ┌─────────────┐             │
│   PM      │ Received:   │                  │       │ Received:   │             │
│           │ +24 GRX     │                  │       │ +8 GRID     │             │
│           │ (8 × 3)     │                  │       │ (Energy)    │             │
│           └─────────────┘                  │       └─────────────┘             │
│                                                                                    │
│   04:00   ┌─────────────┐                  │                                    │
│   PM      │ More        │                  │                                    │
│           │ Production  │                  │                                    │
│           │ → New       │                  │                                    │
│           │   orders... │                  │                                    │
│           └─────────────┘                  │                                    │
│                                                                                    │
│   06:00   ┌─────────────┐                  │                                    │
│   PM      │ End of Day  │                  │                                    │
│           │ Balance:    │                  │                                    │
│           │ 3 GRID      │                  │                                    │
│           │ 24 GRX      │                  │                                    │
│           └─────────────┘                  │                                    │
│                                                                                    │
│   DAILY SUMMARY:                                                                  │
│   ═══════════════════════════════════════════════════════════════════════════     │
│   Prosumer:                            Consumer:                                  │
│   ├─ Produced: 20 kWh                  ├─ Purchased: 8 kWh                        │
│   ├─ Consumed: 9 kWh                   ├─ Spent: 24 GRX                           │
│   ├─ Surplus: 11 kWh                   └─ Got: 8 GRID (green energy)             │
│   ├─ Minted: 11 GRID                                                              │
│   ├─ Sold: 8 GRID                                                                   │
│   ├─ Remaining: 3 GRID                                                              │
│   └─ Earned: 24 GRX                                                                 │
│                                                                                    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Process Chain Summary

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     PROCESS CHAIN DEPENDENCIES                                  │
│                                                                                 │
│   P1: User Onboarding ──┐                                                      │
│                          ▼                                                      │
│   P2: Meter Registration ──┐                                                   │
│                             ▼                                                   │
│   P3: Energy Recording ──┐  [5-15 min cycles]                                  │
│                          ▼                                                      │
│   P4: Token Minting ────┐  [30s polling]                                       │
│                         ▼                                                       │
│   P5: Create Sell Order ──┐  [user triggered]                                  │
│                            ▼                                                    │
│   P6: Match Orders ──┐  [user triggered]                                       │
│                      ▼                                                          │
│   P7: Atomic Settlement ──┐  [automatic, part of P6]                           │
│                            ▼                                                    │
│   P8: ERC Certificate ──┐  [user triggered, independent of trading]            │
│                          ▼                                                      │
│   [ERC used in P5 for premium orders]                                           │
│                                                                                 │
│   Critical Path: P1 → P2 → P3 → P4 → P5 → P6+P7 → P8                          │
│   Total Time (new user to first trade): ~3-5 minutes                            │
│   Recurring Trade Cycle: ~1-2 seconds (P3 → P4 → P5 → P6+P7)                   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 11. Error Handling & Recovery

### 11.1 Transaction Failure Recovery

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  TRANSACTION FAILURE RECOVERY FLOW                                              │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   CLIENT            BACKEND           BLOCKCHAIN          RECOVERY              │
│                                                                                 │
│   ┌───────┐                                                                     │
│   │Submit │                                                                     │
│   │Action │                                                                     │
│   └───┬───┘                                                                     │
│       │                                                                         │
│       │ 1. Submit TX                                               [<100ms]     │
│       ▼                                                                         │
│   ┌───────────┐                                                                 │
│   │ Build +   │─────▶ Submit to Solana                                          │
│   │ Sign TX   │                                                                  │
│   └───────────┘         │                                                       │
│                         ▼                                  [~440ms]            │
│                    ┌────────────────────┐                                       │
│                    │ TX Execution on    │                                       │
│                    │ Solana Network     │                                       │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│                    ┌───────┴───────┐                                            │
│                    │    ?Success?  │───No──▶ Go to error handling              │
│                    └───────┬───────┘                                            │
│                          │ Yes                                                 │
│                          ▼                                                     │
│                    ┌────────────────────┐                                       │
│                    │ Return Success     │                                       │
│                    │ (tx_sig, results)  │                                       │
│                    └────────────────────┘                                       │
│                                                                                 │
│  ERROR HANDLING PATH:                                                           │
│  ═══════════════════                                                            │
│                          │                                                     │
│                    ┌─────▼──────┐                                               │
│                    │ TX Failed  │                                               │
│                    └─────┬──────┘                                               │
│                          │                                                     │
│                          ▼                                                     │
│                    ┌────────────────────┐                                       │
│                    │ Log Error +        │                     [<10ms]           │
│                    │ Classify Failure   │                                       │
│                    └─────────┬──────────┘                                       │
│                          │                                                     │
│                    ┌───────┴───────┐                                            │
│                    │ Classify:     │                                            │
│                    │ • Retryable?  │                                            │
│                    │ • Idempotent? │                                            │
│                    │ • Max retries │                                            │
│                    └───────┬───────┘                                            │
│                          │                                                     │
│              ┌───────────┼───────────┐                                         │
│              │           │           │                                          │
│              ▼           ▼           ▼                                          │
│       ┌──────────┐ ┌──────────┐ ┌──────────┐                                   │
│       │Retryable │ │Non-Retry │ │Idempotent│                                   │
│       │          │ │          │ │          │                                   │
│       │retry_cnt  │ │Return    │ │Check if  │                                   │
│       │< 3?      │ │Error     │ │already   │                                   │
│       └─────┬────┘ └─────┬────┘ │done?     │                                   │
│             │            │      └─────┬────┘                                   │
│        ┌────┴────┐       │       ┌────┴────┐                                   │
│        │  Yes    │       │       │  Yes    │                                   │
│        ▼         ▼       │       ▼         ▼                                   │
│   ┌─────────┐ ┌──────┐  │   ┌─────────┐ ┌──────┐                              │
│   │Wait     │ │Return│  │   │Return   │ │Return│                              │
│   │(Exp     │ │Error │  │   │Existing │ │Error │                              │
│   │Backoff) │ │      │  │   │Result   │ │      │                              │
│   └────┬────┘ └──────┘  │   └─────────┘ └──────┘                              │
│        │                │                                                      │
│        ▼                │                                                      │
│   ┌─────────┐           │                                                      │
│   │Retry TX │───────────┘                                                      │
│   │(fresh   │                                                                  │
│   │blockhash│                                                                  │
│   └────┬────┘                                                                  │
│        │                                                                       │
│        ▼                                                                       │
│   ┌──────────────┐                                                             │
│   │ If retry_cnt  │                                                             │
│   │ >= 3:         │                                                             │
│   │ • Alert admin │                                                             │
│   │ • Queue for   │                                                             │
│   │   async retry │                                                             │
│   │ • Notify user │                                                             │
│   └──────────────┘                                                             │
│                                                                                 │
│   RETRY POLICY:                                                                 │
│   ═══════════════                                                               │
│   • Max Retries: 3                                                              │
│   • Backoff: Exponential (1s → 2s → 4s)                                        │
│   • After Max: Alert admin + notify user + async queue                          │
│   • Idempotent: Check TX signature / PDA state before retry                     │
│   • Blockhash: Always use fresh blockhash for retries                           │
│   • Non-Retryable: Program errors, permission errors, logic bugs                │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 11.2 Error Classification Matrix

| Error Type | Retryable | Idempotent | Max Retries | Action |
|------------|-----------|------------|-------------|--------|
| Network Timeout | Yes | Yes | 3 | Exponential backoff |
| Blockhash Expired | Yes | Yes | 3 | Fresh blockhash, retry |
| Insufficient Balance | No | Yes | 0 | Return error to user |
| Account Not Found | No | Yes | 0 | Return 404, suggest fix |
| Program Error | No | Check | 0 | Alert admin, investigate |
| Permission Denied | No | Yes | 0 | Return 403, check auth |
| Rate Limited | Yes | Yes | 1 | Wait, retry once |
| Duplicate TX | No | Yes | 0 | Return existing result |
| Priority Fee Too Low | Yes | Yes | 2 | Increase fee, retry |
| Account Data Changed | Yes | Check | 3 | Re-fetch state, retry |

### 11.3 Circuit Breaker Pattern

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  CIRCUIT BREAKER FOR EXTERNAL SERVICES                                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   State Machine:                                                                │
│                                                                                 │
│   ┌──────────┐     failures >= threshold      ┌──────────┐                     │
│   │          │ ──────────────────────────────▶│          │                     │
│   │  CLOSED  │                                │   OPEN   │                     │
│   │(healthy) │◀────────────────────────────── │(failing) │                     │
│   │          │     recovery_timeout elapsed   │          │                     │
│   └────┬─────┘                                └────┬─────┘                     │
│        │                                          │                            │
│        │ test_request succeeds                    │ test_request               │
│        ▼                                          ▼                            │
│   ┌──────────┐                                ┌──────────┐                     │
│   │          │                                │ HALF_OPEN│                     │
│   │  CLOSED  │◀────────────────────────────── │(testing) │                     │
│   │          │     test request succeeds      │          │                     │
│   └──────────┘                                └──────────┘                     │
│        ▲                                          │                            │
│        │ test_request fails                       │ test_request fails         │
│        └──────────────────────────────────────────┘                            │
│                                                                                 │
│   Configuration:                                                                │
│   • Failure Threshold: 5 consecutive failures                                   │
│   • Recovery Timeout: 30 seconds                                                │
│   • Applies To: Solana RPC, gRPC services, database                             │
│   • On OPEN: Return cached/default response, log warning                        │
│   • On HALF_OPEN: Allow 1 test request, monitor result                          │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 12. Document Metadata

| Attribute | Value |
|-----------|-------|
| **Document ID** | GRX-DOC-06-PROCESS-FLOWS |
| **Version** | 3.0.0 |
| **Last Updated** | April 2026 |
| **Status** | Production-Ready |
| **Authors** | GridTokenX Research Team |
| **Review Cycle** | Quarterly |
| **Next Review** | July 2026 |
| **Classification** | Internal - Engineering |
| **Related Documents** | 04-DFD, Settlement Architecture, Trading Program |

### Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | Nov 2024 | Initial process flow documentation | GridTokenX Team |
| 2.0.0 | Feb 2026 | Added settlement architecture, updated for microservices | GridTokenX Team |
| 3.0.0 | Apr 2026 | Complete rewrite: standardized swimlane notation, timing annotations, decision branching, error handling paths, process metrics tables, 8 complete process diagrams (P1-P8) | GridTokenX Research Team |

### Process Index

| Process ID | Name | Avg Latency | Trigger | Blockchain |
|------------|------|-------------|---------|------------|
| P1 | User Onboarding | ~600ms | User registration | Registry Program |
| P2 | Meter Registration | ~550ms | User adds meter | Registry Program |
| P3 | Energy Recording | ~500ms | Meter cycle (5-15min) | Registry Program |
| P4 | Token Minting | ~500ms/cycle | Polling (30s) | Energy Token Program |
| P5 | Create Sell Order | ~600ms | User creates order | Trading Program |
| P6 | Match Orders | ~600ms | User accepts order | Trading Program |
| P7 | Atomic Settlement | ~440ms | Part of P6 | Trading Program |
| P8 | ERC Certificate | ~550ms | User requests cert | Governance Program |

---

## Document Navigation

| Previous | Current | Next |
|----------|---------|------|
| [05-TOKEN-ECONOMICS.md](./05-TOKEN-ECONOMICS.md) | **06-PROCESS-FLOWS.md** | [07-SECURITY-ANALYSIS.md](./07-SECURITY-ANALYSIS.md) |
