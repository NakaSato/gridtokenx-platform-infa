# Data Flow Diagrams

## GridTokenX Complete Data Flow Documentation

> *April 2026 Edition - Standardized DFD Notation*  
> **Version:** 3.0.0

---

> **Related Documentation:**  
> - [Process Flows](./06-process-flows.md) - Detailed swimlane diagrams  
> - [System Architecture](./03-system-architecture.md) - Technical architecture  
> - [Security Analysis](./07-security-analysis.md) - Threat model  

---

## 1. Level 0: Context Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CONTEXT DIAGRAM (DFD Level 0)                     │
└─────────────────────────────────────────────────────────────────────┘

    Prosumers                                     External Systems
    (Energy Sellers)           ┌────────┐        (Price Feeds, Grid Data)
         │                     │        │               │
         │ • Registration      │        │               │
         │ • Energy Data       │        │               │
         │ • Create Orders     │        │               │
         │ • Receive Payment   │        │               │
         ▼                     │        │               ▼
    ┌─────────┐         ┌──────┴────────┴──────┐    ┌─────────┐
    │         │         │                       │    │         │
    │ Consumers│────────►      GRIDTOKENX       │◄───│ External│
    │ (Buyers)│         │       SYSTEM          │    │  APIs   │
    │         │         │                       │    │         │
    └─────────┘         │  P2P Energy Trading   │    └─────────┘
         │              │     Platform          │         │
         │ • Browse     │                       │         │
         │ • Trade      │                       │         │
         │ • Payment    │                       │         │
         ▼              └───────────┬───────────┘         ▼
                              Smart Meters          Thai Baht Chain
                              (Telemetry)           (Cross-chain)


Data Flows:
═══════════════════════════════════════════════════════════════════
Prosumers → System: Registration data, meter readings, orders
Consumers → System: Trade requests, payments, preferences
System → Smart Meters: Validation requests, timestamp sync
Smart Meters → System: Signed telemetry (Ed25519)
System → External APIs: Price queries, grid status
External APIs → System: Market prices, grid conditions
System → Thai Baht Chain: Cross-chain payment proofs
Thai Baht Chain → System: Payment confirmations
```

---

## 2. Level 1: Main Process Decomposition

```
┌─────────────────────────────────────────────────────────────────────┐
│              MAIN PROCESS DECOMPOSITION (DFD Level 1)                │
└─────────────────────────────────────────────────────────────────────┘

    Prosumer                                      Consumer
       │                                             │
       │ (1) Registration                            │ (1) Registration
       ├────────────────────────────────────────────►│
       │                                             │
       ▼                                             │
┌──────────────┐                                     │
│              │                                     │
│   P1.0       │                                     │
│   USER       │────────────────────────────────────►│
│   MANAGEMENT │  (2) Browse available orders        │
│              │◄────────────────────────────────────│
└──────┬───────┘                                     │
       │                                             │
       │ (3) Submit energy data                      │
       ▼                                             │
┌──────────────┐                                     │
│              │                                     │
│   P2.0       │                                     │
│   ENERGY     │                                     │
│   RECORDING  │                                     │
│              │                                     │
└──────┬───────┘                                     │
       │ (4) Token mint request                      │
       ▼                                             │
┌──────────────┐                                     │
│              │                                     │
│   P3.0       │                                     │
│   TOKEN      │                                     │
│   MINTING    │                                     │
│              │                                     │
└──────┬───────┘                                     │
       │ (5) Available energy tokens                 │
       ├────────────────────────────────────────────►│
       │                                             │
       ▼                                    ┌────────┴────────┐
┌──────────────┐                            │                 │
│              │                            ▼                 │
│   P4.0       │                    ┌──────────────┐         │
│   ORDER      │◄──────────────────►│   P5.0       │         │
│   MANAGEMENT │   (6) Order book   │   TRADE      │         │
│              │                    │   SETTLEMENT │         │
└──────┬───────┘                    │              │         │
       │                           └────────┬──────┘         │
       │ (7) ERC eligibility                │                │
       ▼                                    │                │
┌──────────────┐                            │                │
│              │                            │                │
│   P6.0       │◄───────────────────────────┘                │
│   ERC MGMT   │   (8) Trade confirmation                   │
│              │                                             │
└──────┬───────┘                                             │
       │                                                     │
       ▼                                    ┌────────────────┴┐
┌──────────────┐                            │                 │
│              │                            ▼                 │
│   P7.0       │                    ┌──────────────┐         │
│   PAYMENT    │◄───────────────────│   External   │         │
│   PROCESSING │   (9) THB payment  │   Systems    │         │
│              │───────────────────►│              │         │
└──────────────┘                    └──────────────┘         │


Data Stores:
═══════════════════════════════════════════════════════════════════
D1: User Database       → User profiles, wallets, PDAs (PostgreSQL)
D2: Meter Readings      → Time-series energy data (InfluxDB + PostgreSQL)
D3: Token Ledger        → GRID token balances (On-chain, SPL Token-2022)
D4: Order Book          → Active and historical orders (PostgreSQL + Cache)
D5: Trade History       → Completed trades (PostgreSQL + Blockchain events)
D6: ERC Registry        → Certificate records (On-chain PDA + PostgreSQL)
D7: Payment Records     → Payment transactions (PostgreSQL)
```

---

## 3. Level 2: Detailed Process Flows

### 3.1 Process P1.0: User Management

```
┌─────────────────────────────────────────────────────────────────────┐
│                PROCESS P1.0: USER MANAGEMENT (DFD Level 2)           │
└─────────────────────────────────────────────────────────────────────┘

                              User
                               │
                               │ (1) Registration Request
                               │ {wallet, type, profile, KYC docs}
                               ▼
                     ┌─────────────────────┐
                     │                     │
                     │   P1.1 VALIDATE     │
                     │   REGISTRATION      │
                     │                     │
                     └──────────┬──────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
     ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
     │              │  │              │  │              │
     │ P1.2 CHECK   │  │ P1.3 VERIFY  │  │ P1.4 CHECK   │
     │ WALLET       │  │ KYC DOCS     │  │ DUPLICATE    │
     │ FORMAT       │  │ (if required)│  │ USER         │
     │              │  │              │  │              │
     └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
            │                 │                 │
            └─────────────────┼─────────────────┘
                              │
                              │ (2) Validation Result
                              ▼
                     ┌─────────────────────┐
                     │                     │
                     │   P1.5 CREATE       │
                     │   USER PDA          │◄──── D1: User Database (check)
                     │   (Solana)          │
                     │                     │
                     └──────────┬──────────┘
                                │
                                │ (3) PDA Address + TX Signature
                                ▼
                     ┌─────────────────────┐
                     │                     │
                     │   P1.6 STORE        │──────────► D1: User Database
                     │   USER PROFILE      │           (INSERT user record)
                     │   (PostgreSQL)      │
                     │                     │
                     └──────────┬──────────┘
                                │
                                │ (4) Registration Confirmation
                                ▼
                              User


Data Flows:
═══════════════════════════════════════════════════════════════════
Input:  Registration request (wallet address, user type, profile)
Output: User PDA address, TX signature, confirmation
D1 Read:  Duplicate user check, wallet format validation
D1 Write: New user profile with PDA references
Processing Time: ~2-3 seconds (includes blockchain TX confirmation)
Success Rate: 99.5% (0.5% failure from invalid wallet formats)
```

### 3.2 Process P2.0: Energy Recording

```
┌─────────────────────────────────────────────────────────────────────┐
│              PROCESS P2.0: ENERGY RECORDING (DFD Level 2)            │
└─────────────────────────────────────────────────────────────────────┘

          Smart Meter
               │
               │ (1) Signed Reading Payload
               │ {meter_id, production, consumption, timestamp, signature}
               ▼
      ┌─────────────────────┐
      │                     │
      │   P2.1 VERIFY       │
      │   ED25519 SIGNATURE │
      │   (< 10ms)          │
      │                     │
      └──────────┬──────────┘
                 │
                 │ (2) Valid Signature
                 ▼
      ┌─────────────────────┐
      │                     │
      │   P2.2 CHECK        │◄─────────── D1: User Database
      │   METER REGISTRATION│            (Meter Registry lookup)
      │                     │
      └──────────┬──────────┘
                 │
                 │ (3) Registered Meter Confirmed
                 ▼
      ┌─────────────────────┐
      │                     │
      │   P2.3 VALIDATE     │
      │   READING DATA      │
      │                     │
      │   Checks:           │
      │   • Timestamp ≤5s   │
      │   • Rate limit 60s  │
      │   • No duplicates   │
      │   • Anomaly detect  │
      │                     │
      └──────────┬──────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
  PASS  │              FAIL │
        │                 │
        ▼                 ▼
┌──────────────┐  ┌──────────────┐
│              │  │              │
│ P2.4 STORE   │  │ P2.5 REJECT  │
│ READING      │  │ & LOG ERROR  │
│ (PostgreSQL) │  │              │
│              │  │              │
└──────┬───────┘  └──────────────┘
       │
       │ (4) Reading Stored
       ▼
      ┌─────────────────────┐
      │                     │
      │   P2.6 UPDATE       │
      │   METER PDA         │─────────────► Blockchain
      │   (Solana)          │              (submit_reading TX)
      │                     │
      └──────────┬──────────┘
                 │
                 │ (5) PDA Updated
                 ▼
      ┌─────────────────────┐
      │                     │
      │   P2.7 CALCULATE    │
      │   SURPLUS           │
      │                     │
      │   surplus =         │
      │   production -      │
      │   consumption       │
      │                     │
      └──────────┬──────────┘
                 │
                 │ (6) Surplus Amount (if > 0)
                 ▼
           To Process P3.0
           (Token Minting)


Data Flows:
═══════════════════════════════════════════════════════════════════
Input:  Signed meter reading payload (Ed25519)
Output: Storage confirmation, blockchain TX signature
D1 Read:  Meter registration status, owner verification
D2 Write: Time-series reading record (InfluxDB + PostgreSQL)
Processing Time: < 100ms total (signature < 10ms, validation < 50ms)
Success Rate: 99.8% (0.2% rejection from invalid signatures/duplicates)
Rejection Reasons: Invalid signature, unregistered meter, rate limit exceeded
```

### 3.3 Process P3.0: Token Minting

```
┌─────────────────────────────────────────────────────────────────────┐
│               PROCESS P3.0: TOKEN MINTING (DFD Level 2)              │
└─────────────────────────────────────────────────────────────────────┘

     From Process P2.0
     (Surplus Amount > 0)
           │
           │
           ▼
  ┌─────────────────────┐
  │                     │
  │   P3.1 CHECK        │◄────────── D2: Meter Readings
  │   UNMINTED          │            (WHERE minted = false)
  │   READINGS          │
  │                     │
  └──────────┬──────────┘
             │
             │ (1) Unminted Readings Found
             ▼
  ┌─────────────────────┐
  │                     │
  │   P3.2 CALCULATE    │
  │   UNSETTLED         │
  │   BALANCE           │
  │                     │
  │   current_net =     │
  │   production -      │
  │   consumption       │
  │                     │
  │   unsettled =       │
  │   current_net -     │
  │   settled_net_gen   │
  │                     │
  │   If unsettled ≤ 0  │
  │   → No minting      │
  │                     │
  └──────────┬──────────┘
             │
             │ (2) Unsettled Amount > 0
             ▼
  ┌─────────────────────┐
  │                     │
  │   P3.3 SETTLE       │
  │   METER BALANCE     │
  │   (Registry CPI)    │
  │                     │
  │   Instruction:      │
  │   settle_energy()   │
  │                     │
  └──────────┬──────────┘
             │
             │ (3) Settlement Proof
             │     (High-water mark updated)
             ▼
  ┌─────────────────────┐
  │                     │
  │   P3.4 MINT TOKENS  │
  │   (Energy Token     │
  │    Program CPI)     │
  │                     │
  │   Instruction:      │
  │   mint_tokens_      │
  │   direct()          │
  │                     │
  │   1 kWh = 1 GRID    │
  │   (9 decimals)      │
  │                     │
  └──────────┬──────────┘
             │
     ┌───────┴───────┐
     │               │
     ▼               ▼
┌──────────┐   ┌──────────┐
│          │   │          │
│ P3.5 UPD │   │ P3.6 UPD │
│ TOKEN    │   │ METER    │
│ BALANCE  │   │ READING  │
│ (SPL)    │   │ (minted  │
│          │   │  = true) │
└────┬─────┘   └────┬─────┘
     │              │
     │              │
     ▼              ▼
D3: Token       D2: Meter
    Ledger          Readings
    (On-chain)      (UPDATE minted=T)


Data Flows:
═══════════════════════════════════════════════════════════════════
Input:  Settled surplus amount from Registry program
Output: GRID tokens minted to user's token account
D2 Read:  Unminted readings, settled_net_generation high-water mark
D2 Write: UPDATE readings SET minted = true
D3 Write: SPL Token-2022 mint (on-chain token balance increase)
Processing Time: ~450ms (Registry CPI: 200ms + Energy Token CPI: 250ms)
Success Rate: 99.9% (0.1% failure from insufficient CU budget)
CU Consumption: ~30,000 CU total (Registry settle: 12k + Token mint: 18k)
Security: Dual high-water mark prevents double-minting
```

### 3.4 Process P4.0: Order Management

```
┌─────────────────────────────────────────────────────────────────────┐
│             PROCESS P4.0: ORDER MANAGEMENT (DFD Level 2)             │
└─────────────────────────────────────────────────────────────────────┘

        Prosumer                                     Consumer
           │                                            │
           │ (1) Create Order Request                   │
           │ {amount, price, expires_at, erc_cert?}     │
           ▼                                            │
  ┌─────────────────────┐                               │
  │                     │                               │
  │   P4.1 VALIDATE     │                               │
  │   ORDER REQUEST     │                               │
  │                     │                               │
  │   Checks:           │                               │
  │   • Amount > 0      │                               │
  │   • Price > 0       │                               │
  │   • expires_at > now│                               │
  │   • Has balance     │◄────── D3: Token Ledger       │
  │                     │                               │
  └──────────┬──────────┘                               │
             │                                          │
             │ (2) Valid Order                          │
             ▼                                          │
  ┌─────────────────────┐                               │
  │                     │                               │
  │   P4.2 TRANSFER     │                               │
  │   TO ESCROW         │                               │
  │   (Lock Tokens)     │                               │
  │                     │                               │
  └──────────┬──────────┘                               │
             │                                          │
             │ (3) Tokens Locked in Escrow PDA          │
             ▼                                          │
  ┌─────────────────────┐                               │
  │                     │                               │
  │   P4.3 CREATE       │                               │
  │   ORDER PDA         │                               │
  │   (Solana)          │                               │
  │                     │                               │
  └──────────┬──────────┘                               │
             │                                          │
             │ (4) Order Created                        │
             ▼                                          │
  ┌─────────────────────┐        ┌─────────────────────┐
  │                     │        │                     │
  │   P4.4 STORE        │───────►│   P4.5 QUERY        │◄─────────┘
  │   ORDER             │        │   ORDER BOOK        │
  │   (PostgreSQL)      │        │                     │
  │                     │        │                     │
  └──────────┬──────────┘        └──────────┬──────────┘
             │                              │
             │                              │ (5) Order List
             ▼                              ▼
      D4: Order Book                   Consumer UI
      (PostgreSQL + Cache)             (Available orders)

                    ┌─────────────────────┐
                    │                     │
                    │   P4.6 CANCEL       │
                    │   ORDER             │
                    │   (If requested)    │
                    │                     │
                    │   • Return tokens   │
                    │   • Update status   │
                    │   • Emit event      │
                    │                     │
                    └─────────────────────┘


Data Flows:
═══════════════════════════════════════════════════════════════════
Input:  Order creation request (type, amount, price, expiry)
Output: Order PDA address, escrow confirmation, order book entry
D3 Read:  Token balance verification before order creation
D4 Write: New order record with PDA reference, escrow status
Processing Time: ~410ms (validation: 10ms + escrow: 200ms + PDA create: 200ms)
Success Rate: 99.6% (0.4% failure from insufficient balance or invalid params)
CU Consumption: ~7,500 CU (sell order), ~7,200 CU (buy order)
```

### 3.5 Process P5.0: Trade Settlement

```
┌─────────────────────────────────────────────────────────────────────┐
│             PROCESS P5.0: TRADE SETTLEMENT (DFD Level 2)             │
└─────────────────────────────────────────────────────────────────────┘

        Consumer
           │
           │ (1) Match Order Request
           │ {order_id, quantity}
           ▼
  ┌─────────────────────┐
  │                     │
  │   P5.1 VALIDATE     │
  │   MATCH REQUEST     │
  │                     │
  │   Checks:           │
  │   • Order active    │◄────── D4: Order Book
  │   • Not self-trade  │
  │   • Buyer balance   │◄────── D3: Token Ledger (GRX)
  │   • Qty ≤ available │
  │                     │
  └──────────┬──────────┘
             │
             │ (2) Valid Match
             ▼
  ┌─────────────────────┐
  │                     │
  │   P5.2 ATOMIC       │
  │   SETTLEMENT        │
  │   (All-or-Nothing)  │
  │                     │
  │   6-Way Transfer:   │
  │   1. Escrow → Buyer │
  │   2. Buyer → Seller │
  │   3. Buyer → Fee    │
  │   4. Seller → Fee   │
  │   5. Update Order   │
  │   6. Emit Event     │
  │                     │
  └──────────┬──────────┘
             │
     ┌───────┴───────────────────┐
     │                           │
     ▼                           ▼
┌──────────────┐          ┌──────────────┐
│              │          │              │
│ P5.3 TRANSFER│          │ P5.4 TRANSFER│
│ ENERGY TOKNS │          │ PAYMENT      │
│              │          │              │
│ Escrow PDA   │          │ Buyer Wallet │
│    →         │          │    →         │
│ Buyer Wallet │          │ Seller Wallet│
│              │          │              │
└──────┬───────┘          └──────┬───────┘
       │                         │
       │                         │
       └────────────┬────────────┘
                    │
                    │ (3) Both Transfers Complete
                    ▼
           ┌─────────────────────┐
           │                     │
           │   P5.5 UPDATE       │
           │   ORDER STATUS      │
           │   (FILLED/PARTIAL)  │
           │                     │
           └──────────┬──────────┘
                      │
                      │ (4) Status Updated
           ┌──────────┴──────────┐
           │                     │
           ▼                     ▼
  ┌─────────────────┐   ┌─────────────────┐
  │                 │   │                 │
  │ P5.6 EMIT       │   │ P5.7 RECORD     │
  │ TRADE EVENT     │   │ TRADE           │
  │ (On-chain)      │   │ (PostgreSQL)    │
  │                 │   │                 │
  └────────┬────────┘   └────────┬────────┘
           │                     │
           │                     │
           ▼                     ▼
     Event Listener        D5: Trade History
     (Kafka Stream)        (INSERT trade record)


Data Flows:
═══════════════════════════════════════════════════════════════════
Input:  Match order request (order_id, quantity)
Output: Trade confirmation, token transfer signatures
D3 Read/Write: Token balances updated (buyer receives, seller receives payment)
D4 Read/Write: Order status updated (filled_amount, status)
D5 Write: New trade record with TX signature
Processing Time: ~440ms average (atomic settlement, all-or-nothing)
Success Rate: 99.7% (0.3% transient failures, retryable)
CU Consumption: ~15,000 CU (simple match), ~28,000 CU (6-way atomic)
Security: Self-trade prevention, atomic transfer (reverts on failure)
```

---

## 4. Cross-Process Data Flows

### 4.1 End-to-End Energy Trading Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│           END-TO-END ENERGY TRADING DATA FLOW                        │
└─────────────────────────────────────────────────────────────────────┘

PHASE 1: ENERGY GENERATION & RECORDING
══════════════════════════════════════════════════════════════════

 Smart Meter          Oracle Bridge         Backend            Blockchain
     │                    │                    │                   │
     │  (1) Signed        │                    │                   │
     │  Reading           │                    │                   │
     │ ──────────────────►│                    │                   │
     │                    │  (2) Verify Sig    │                   │
     │                    │  [< 10ms]          │                   │
     │                    │  ──────┐           │                   │
     │                    │  ◄─────┘           │                   │
     │                    │                    │                   │
     │                    │  (3) Forward       │                   │
     │                    │ ──────────────────►│                   │
     │                    │                    │  (4) Store        │
     │                    │                    │ ──────┐           │
     │                    │                    │ ◄─────┘           │
     │                    │                    │                   │
     │                    │                    │  (5) Update PDA   │
     │                    │                    │ ─────────────────►│
     │                    │                    │                   │
     │  (6) 200 OK        │                    │  (7) TX Sig       │
     │  ◄─────────────────│────────────────────│───────────────────│


PHASE 2: TOKEN MINTING (Automated)
══════════════════════════════════════════════════════════════════

 Polling Svc        Registry Program    Energy Token Prog    SPL Token
     │                    │                    │                  │
     │  (1) Query         │                    │                  │
     │  Unminted          │                    │                  │
     │ ──────┐            │                    │                  │
     │ ◄─────┘            │                    │                  │
     │                    │                    │                  │
     │  (2) Settle        │                    │                  │
     │  Balance           │                    │                  │
     │ ──────────────────►│                    │                  │
     │                    │  (3) CPI: Mint     │                  │
     │                    │ ──────────────────►│                  │
     │                    │                    │  (4) SPL Mint    │
     │                    │                    │ ────────────────►│
     │                    │                    │                  │
     │  (5) Update DB     │                    │                  │
     │  (minted=true)     │                    │                  │
     │ ──────┐            │                    │                  │
     │ ◄─────┘            │                    │                  │


PHASE 3: ORDER CREATION
══════════════════════════════════════════════════════════════════

 Prosumer           API Gateway         Trading Program       Escrow PDA
     │                    │                    │                   │
     │  (1) Create Order  │                    │                   │
     │ ──────────────────►│                    │                   │
     │                    │  (2) Create Order  │                   │
     │                    │ ──────────────────►│                   │
     │                    │                    │  (3) Lock Tokens  │
     │                    │                    │ ─────────────────►│
     │                    │                    │                   │
     │  (4) Order Confirm │   (5) Created      │                   │
     │ ◄──────────────────│ ◄──────────────────│                   │


PHASE 4: TRADE EXECUTION & SETTLEMENT
══════════════════════════════════════════════════════════════════

 Consumer           API Gateway         Trading Program     Seller Wallet
     │                    │                    │                  │
     │  (1) Match Order   │                    │                  │
     │ ──────────────────►│                    │                  │
     │                    │  (2) Match Orders  │                  │
     │                    │ ──────────────────►│                  │
     │                    │                    │  (3) Atomic       │
     │                    │                    │      Settlement   │
     │                    │                    │  [~440ms]         │
     │                    │                    │                  │
     │  (4) Trade Confirm │   (5) Settled      │                  │
     │ ◄──────────────────│ ◄──────────────────│                  │
     │                    │                    │                  │


PHASE 5: ERC CERTIFICATE ISSUANCE (Optional)
══════════════════════════════════════════════════════════════════

 Prosumer           Trading Service     Governance Program   Registry Program
     │                    │                    │                    │
     │  (1) Check ERC     │                    │                    │
     │  Eligibility       │                    │                    │
     │ ──────────────────►│                    │                    │
     │                    │  (2) Verify        │                    │
     │                    │  Unclaimed Energy  │                    │
     │                    │ ──────────────────────────────────────►│
     │                    │                    │                    │
     │                    │  (3) Issue ERC     │ ◄─────────────────│
     │                    │ ──────────────────►│                    │
     │                    │                    │                    │
     │  (4) ERC Issued    │   (5) Certificate  │                    │
     │ ◄──────────────────│ ◄──────────────────│                    │
```

---

## 5. Data Dictionary

### 5.1 Core Data Entities

| Entity | Fields | Storage | Description |
|--------|--------|---------|-------------|
| **User** | id, wallet, email, kyc_status, user_type, created_at | D1 (PostgreSQL) + PDA | Registered platform user |
| **Meter** | id, owner_id, meter_type, location, total_prod, total_cons, settled_net, claimed_erc | D1 + PDA | Smart meter device |
| **Reading** | id, meter_id, production, consumption, timestamp, signature, minted | D2 (InfluxDB + PostgreSQL) | Energy telemetry record |
| **Order** | id, seller, buyer, type, amount, filled, price, status, expires_at, erc_cert | D4 + PDA | Trading order (buy/sell) |
| **Trade** | id, buy_order, sell_order, quantity, price, total, tx_sig, settled_at | D5 (PostgreSQL) | Executed trade record |
| **ERC Certificate** | id, energy_amount, source, status, issued_at, validated_at, retired_at | D6 + PDA | Renewable energy certificate |

### 5.2 Data Flow Timing Summary

| Flow | Source → Destination | Latency | Frequency |
|------|---------------------|---------|-----------|
| Meter Reading → Oracle Bridge | Smart Meter → API | < 50ms | Every 60s (rate limited) |
| Oracle Bridge → Backend | API → Service | < 10ms | Every 60s |
| Backend → Blockchain | Service → Solana | ~400ms | Every 60s |
| Order Creation | User → Trading Program | ~410ms | On demand |
| Order Matching | Consumer → Settlement | ~440ms | On demand |
| Token Minting | Registry → Energy Token | ~450ms | Automated (polling) |
| ERC Issuance | Governance → Registry | ~380ms | On demand |

---

**Document Information:**

| Field | Value |
|-------|-------|
| **Version** | 3.0.0 |
| **Last Updated** | April 2026 |
| **Status** | Production-Ready |
| **Authors** | GridTokenX Research Team |
