# Consensus Layer: Proof of Provenance & GridTokenX Coordination

**Version:** 2.0 (Diagram-Focused)  
**Last Updated:** April 6, 2026  
**Status:** ✅ Implemented (Phase 1)

---

## Overview

GridTokenX uses a **hybrid consensus model** combining Solana's native consensus for transaction ordering with an application-layer **Proof of Provenance (PoP)** mechanism for energy certification.

```
┌─────────────────────────────────────────────────────────────┐
│                  CONSENSUS LAYERS                            │
│                                                              │
│  Layer 1: Solana Consensus (Base)                           │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ Proof of     │  │ Tower BFT    │                        │
│  │ History      │→ │ (Finality)   │                        │
│  │ (Ordering)   │  │              │                        │
│  └──────────────┘  └──────────────┘                        │
│           ↓                     ↓                           │
│  ┌──────────────────────────────────────┐                  │
│  │  Global Transaction Order + Finality │                  │
│  │  • ~400ms block time                 │                  │
│  │  • 65,000+ TPS theoretical           │                  │
│  │  • Decentralized validators          │                  │
│  └──────────────────────────────────────┘                  │
│                          ↓                                  │
│  Layer 2: GridTokenX Proof of Provenance (Application)     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Meter   │→ │  Oracle  │→ │   ERC    │→ │  Token   │  │
│  │ Reading  │  │Validate  │  │ Certify  │  │  Mint    │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                          ↓                                  │
│  ┌──────────────────────────────────────┐                  │
│  │  Energy Certification Consensus      │                  │
│  │  • Quality score validation          │                  │
│  │  • Anomaly detection                 │                  │
│  │  • Monotonic timestamps              │                  │
│  │  • Anti-double-spend (nullifiers)    │                  │
│  └──────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. Solana Consensus Integration

### 1.1 How GridTokenX Uses PoH + Tower BFT

```
Understanding Proof of History (PoH):

  PoH is NOT a consensus algorithm—it's a CRYPTOGRAPHIC CLOCK

  How It Works:
  ┌────────────────────────────────────────────────────┐
  │  SHA-256 Hash Chain (Verifiable Delay Function)   │
  │                                                     │
  │  Hash₁ = SHA-256(input)                            │
  │  Hash₂ = SHA-256(Hash₁)                            │
  │  Hash₃ = SHA-256(Hash₂)                            │
  │  Hash₄ = SHA-256(Hash₃)                            │
  │  ...                                                │
  │                                                     │
  │  • Difficult to produce sequentially                │
  │  • Easy to verify in parallel                       │
  │  • Creates verifiable time ordering                 │
  └────────────────────────────────────────────────────┘

  PoH Metrics:
  ┌────────────────────────────────────────┐
  │ • 800,000 hashes per block             │
  │ • 64 ticks per block = 400ms           │
  │ • Each tick = 6.25ms (proves liveness) │
  │ • Transactions hashed into PoH chain   │
  └────────────────────────────────────────┘

  GridTokenX Benefits:
  ✓ No node-to-node ordering communication needed
  ✓ Leader schedule enforced cryptographically
  ✓ Malicious validators can't produce blocks out of turn
  ✓ Transaction order is provable and verifiable


Transaction Flow: User Submits Order

  User Wallet
       ↓
  ┌─────────────────────────────────┐
  │  Create Order Transaction       │
  │  • API Gateway builds tx        │
  │  • Adds recent blockhash        │
  │    (~1 min expiry)              │
  └───────────────┬─────────────────┘
                  ↓
  ┌─────────────────────────────────┐
  │  Sign & Submit via QUIC         │
  │  • No mempool (direct routing)  │
  │  • Forwarded to slot leader     │
  │  • Stake-Weighted QoS priority  │
  └───────────────┬─────────────────┘
                  ↓
  ┌─────────────────────────────────────────────┐
  │         LEADER TPU PIPELINE                  │
  │                                              │
  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
  │  │  FETCH   │→ │ SIGVERIFY│→ │ BANKING  │  │
  │  │  STAGE   │  │  STAGE   │  │  STAGE   │  │
  │  │ (QUIC)   │  │ (dedup)  │  │(PoH+Exec)│  │
  │  └──────────┘  └──────────┘  └──────────┘  │
  │                                              │
  │  Banking Stage:                              │
  │  • 6 CPU threads total                       │
  │  • 4 threads: normal transactions            │
  │  • 2 threads: vote transactions (priority)   │
  │  • Groups tx into "entries" (batches of 64)  │
  │  • Parallel execution of non-conflicting tx  │
  │  • Hashes results into PoH chain             │
  └─────────────────────────────────────────────┘
                  ↓
  ┌─────────────────────────────────────────────┐
  │         TURBINE (Data Propagation)           │
  │                                              │
  │  • Blocks shredded into 1,280-byte packets  │
  │  • Erasure coding: 32 data + 32 recovery    │
  │  • Merkle-chained tree, fanout=200          │
  │  • UDP protocol (minimizes leader egress)   │
  └─────────────────────────────────────────────┘
                  ↓
  ┌─────────────────────────────────────────────┐
  │      VALIDATOR TVU PIPELINE                  │
  │                                              │
  │  Shred Fetch → Verify Signature →            │
  │  Retransmit → Replay Stage                   │
  │                                              │
  │  Replay Stage:                               │
  │  • Single-threaded validation loop          │
  │  • Validates leader's block                 │
  │  • Votes on canonical fork                  │
  │  • Updates bank state                       │
  └─────────────────────────────────────────────┘
                  ↓
  ┌─────────────────────────────────────────────┐
  │      TOWER BFT CONSENSUS (Voting)            │
  │                                              │
  │  • PoH reduces messaging to ONE vote/block  │
  │  • Validators vote on valid blocks          │
  │  • Pay small fee, earn voting credits       │
  │  • 2/3 supermajority = "Confirmed"          │
  │  • Heaviest fork rule resolves conflicts    │
  │  • Lockout periods prevent flip-flopping    │
  └─────────────────────────────────────────────┘
                  ↓
  ┌─────────────────────────────────────────────┐
  │         FINALITY ACHIEVED                    │
  │                                              │
  │  Processed  → In a block                     │
  │  Confirmed  → 2/3 voted (typical ~750ms)    │
  │  Finalized  → >31 blocks built on top       │
  └─────────────────────────────────────────────┘
                  ↓
  GridTokenX Updates Database
  • blockchain_status = 'success'
  • blockchain_tx_hash stored
  • Event published to Redis
```

**Timing Breakdown:**

```
┌──────────────────────────────────────────────────────────┐
│              Transaction Timing (Typical)                 │
├────────────────────────┬────────────┬────────────────────┤
│ Step                   │ Duration   │ Cumulative         │
├────────────────────────┼────────────┼────────────────────┤
│ API builds transaction │ ~50ms      │ 50ms               │
│ Get latest blockhash   │ ~20ms      │ 70ms               │
│ Sign transaction       │ ~5ms       │ 75ms               │
│ Submit to leader       │ ~50ms      │ 125ms              │
│ Block inclusion        │ ~400ms     │ 525ms              │
│ Consensus confirmation │ ~200ms     │ 725ms              │
│ DB update              │ ~25ms      │ 750ms              │
├────────────────────────┼────────────┼────────────────────┤
│ TOTAL                  │            │ ~750ms             │
└────────────────────────┴────────────┴────────────────────┘
```

### 1.2 Blockhash-Based Timing

```
Recent Blockhash Role in GridTokenX:

  Blockhash Properties:
  ┌─────────────────────────────────────────────────┐
  │ • Derived from PoH hash chain                   │
  │ • Expires after ~1 minute (150 slots)           │
  │ • Prevents replay attacks                       │
  │ • Proves transaction was built recently         │
  └─────────────────────────────────────────────────┘

  Block N (current)     Block N+1           Block N+2
  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │ Blockhash:   │     │ Blockhash:   │     │ Blockhash:   │
  │ 0xabc123...  │────→│ 0xdef456...  │────→│ 0x789ghi...  │
  └──────────────┘     └──────────────┘     └──────────────┘
        ↓                     ↓                     ↓
  Transactions signed   Transactions signed   New blockhash
  with 0xabc123...      with 0xdef456...      required
  (valid for ~60s)      (valid for ~60s)


  GridTokenX Usage:
  ┌─────────────────────────────────────────────────┐
  │ 1. Transaction Expiry                           │
  │    • Transactions expire after ~60 seconds      │
  │    • (150 blockhashs)                           │
  │    • Forces fresh submission                    │
  │                                                 │
  │ 2. Replay Protection                            │
  │    • Each blockhash used once per transaction   │
  │    • Prevents duplicate submissions             │
  │    • Network rejects replayed transactions      │
  │                                                 │
  │ 3. Ordering Guarantee                           │
  │    • Blockhash provides PoH timestamp           │
  │    • Cryptographic proof of when tx was built   │
  │    • Leader can only include valid blockhash    │
  └─────────────────────────────────────────────────┘
```

---

## 2. Proof of Provenance (PoP) - Application Consensus

### 2.1 What is Proof of Provenance?

PoP certifies that renewable energy tokens are backed by **real, verified physical generation**:

```
┌──────────────────────────────────────────────────────────────┐
│                 PROOF OF PROVENANCE FLOW                      │
│                                                               │
│  Physical World          Validation         Blockchain        │
│  ┌────────────┐        ┌────────────┐      ┌──────────────┐ │
│  │            │        │            │      │              │ │
│  │ Smart Meter│───────→│  Oracle    │─────→│ ERC Certificate││
│  │ (Solar)    │ Reading│  Program   │ Issue│  (Governance) │ │
│  │            │        │            │      │              │ │
│  │ Generates  │        │ Validates  │      │ Certifies    │ │
│  │ 10 kWh     │        │ ✓ Quality  │      │ 10 kWh GRID  │ │
│  └────────────┘        │ ✓ Bounds   │      │              │ │
│                        │ ✓ Unique   │      └──────┬───────┘ │
│                        └────────────┘             │         │
│                                                   ↓         │
│                                          ┌──────────────┐  │
│                                          │  Energy      │  │
│                                          │  Token       │  │
│                                          │  Program     │  │
│                                          │              │  │
│                                          │ Mints 10 GRID│  │
│                                          │ to user      │  │
│                                          └──────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 PoP Consensus Steps

```
STEP 1: Meter Reading Submission
┌────────────────────────────────────┐
│  Smart Meter (IoT Device)          │
│  • Generates reading every 5 min   │
│  • Contains: kWh, voltage, current │
│  • Signed by meter's API key       │
└───────────────┬────────────────────┘
                ↓
┌────────────────────────────────────┐
│  Oracle Bridge Service             │
│  • Receives via HTTP/gRPC          │
│  • Validates API key               │
│  • Routes to API Gateway           │
└───────────────┬────────────────────┘
                ↓
┌────────────────────────────────────┐
│  Oracle Program (On-Chain)         │
│  • Creates MeterState PDA          │
│  • Records reading + timestamp     │
│  • Emits event for indexing        │
└────────────────────────────────────┘


STEP 2: Oracle Validation
┌────────────────────────────────────┐
│  Validation Checks (All must pass) │
│                                    │
│  ✓ Monotonic Timestamps            │
│    New reading > last reading      │
│                                    │
│  ✓ Rate-of-Change Limits           │
│    Delta ≤ max allowed per zone    │
│    (prevents anomalous spikes)     │
│                                    │
│  ✓ Physical Bounds                 │
│    Voltage: 180-260V               │
│    Current: 0-100A                 │
│    Power factor: 0.8-1.0           │
│                                    │
│  ✓ Quality Score Calculation       │
│    Based on consistency, accuracy   │
│    Score: 0-100 (threshold: 70+)   │
└───────────────┬────────────────────┘
                ↓
         All checks pass?
         ╱            ╲
       YES             NO
        ↓               ↓
   Update MeterState  Reject reading
   quality_score      + flag anomaly
        ↓
   Proceed to Step 3


STEP 3: ERC Certificate Issuance
┌───────────────────────────────────────────────────┐
│  Governance Program Issues Certificate            │
│                                                    │
│  ┌─────────────────────────────────────────┐     │
│  │  ERC Certificate                        │     │
│  │  • Certificate ID: 64 bytes (unique)    │     │
│  │  • Owner: Prosumer wallet address       │     │
│  │  • Energy: 10 kWh (certified amount)    │     │
│  │  • Source: Solar                        │     │
│  │  • Oracle reading slot: #12345678       │     │
│  │  • Quality score: 92/100                │     │
│  │  • Zone: 3 (geographic region)          │     │
│  │  • Valid for: 365 days                  │     │
│  │  • Status: Active                       │     │
│  └─────────────────────────────────────────┘     │
│                                                    │
│  Certificate is PROOF that energy was:            │
│  1. Generated (physical meter reading)            │
│  2. Validated (oracle quality check)              │
│  3. Certified (governance program issued)          │
│  4. Unique (cannot be double-counted)             │
└───────────────────────────────────────────────────┘


STEP 4: Token Minting
┌────────────────────────────────────────────┐
│  Energy Token Program Mints GRID Tokens    │
│                                             │
│  Prerequisites (all must be true):         │
│  ✓ Valid ERC certificate exists            │
│  ✓ Certificate status = Active             │
│  ✓ Quality score ≥ threshold (70+)         │
│  ✓ Certificate not expired                 │
│  ✓ Energy amount ≥ requested mint amount   │
│                                             │
│  If all checks pass:                       │
│  → Mint GRID tokens to user's wallet       │
│  → 1 GRID = 1 kWh certified energy         │
│  → Emit TokensMinted event                 │
└────────────────────────────────────────────┘
```

### 2.3 PoP Consensus Properties

```
┌──────────────────────────────────────────────────────────────┐
│              PROOF OF PROVENANCE PROPERTIES                   │
├──────────────────┬──────────────────┬────────────────────────┤
│ Property         │ Mechanism        │ Guarantee               │
├──────────────────┼──────────────────┼────────────────────────┤
│ Authenticity     │ Oracle-signed    │ Only valid physical     │
│                  │ meter readings   │ readings accepted       │
├──────────────────┼──────────────────┼────────────────────────┤
│ Uniqueness       │ ERC certificate  │ No double-certification │
│                  │ ID (64 bytes)    │ of same energy          │
├──────────────────┼──────────────────┼────────────────────────┤
│ Integrity        │ Monotonic        │ Prevents manipulation   │
│                  │ timestamps       │ and backdating          │
├──────────────────┼──────────────────┼────────────────────────┤
│ Quality          │ Score-based      │ Filters anomalous or    │
│                  │ validation (0-100)│ suspicious data         │
├──────────────────┼──────────────────┼────────────────────────┤
│ Traceability     │ On-chain cert    │ Full provenance audit   │
│                  │ + slot reference │ trail from meter to     │
│                  │                  │ token                   │
├──────────────────┼──────────────────┼────────────────────────┤
│ Anti-Double-     │ Order nullifier  │ Prevents same energy    │
│ Spend            │ pattern          │ from being traded twice │
└──────────────────┴──────────────────┴────────────────────────┘
```

---

## 3. Leader Schedule & Transaction Priority

### 3.1 Solana Leader Schedule

```
Solana Time Division:

  Slot 1        Slot 2        Slot 3        Slot 4
  (400ms)       (400ms)       (400ms)       (400ms)
  ┌─────┐      ┌─────┐      ┌─────┐      ┌─────┐
  │Leader│      │Leader│      │Leader│      │Leader│
  │  A   │─────→│  B   │─────→│  C   │─────→│  D   │
  └─────┘      └─────┘      └─────┘      └─────┘
   Validator 1   Validator 5   Validator 2   Validator 8


  GridTokenX Optimization:
  ┌─────────────────────────────────────────────────────┐
  │ • Transactions submitted to current leader          │
  │ • If leader is slow, next leader can include        │
  │ • Priority fees incentivize faster inclusion        │
  │ • Typical: 1-2 slots for confirmation               │
  └─────────────────────────────────────────────────────┘
```

### 3.2 Priority Fee Strategy

```
┌─────────────────────────────────────────────────────────────┐
│              PRIORITY FEE TIERS                              │
├──────────────────────┬──────────────┬────────────────────────┤
│ Operation            │ Priority     │ Rationale              │
├──────────────────────┼──────────────┼────────────────────────┤
│ Meter reading        │ HIGH         │ Time-sensitive,        │
│ minting              │              │ revenue-impacting       │
├──────────────────────┼──────────────┼────────────────────────┤
│ Settlement           │ CRITICAL     │ Financial transaction, │
│                      │              │ must succeed            │
├──────────────────────┼──────────────┼────────────────────────┤
│ Order creation       │ MEDIUM       │ Standard trading       │
│                      │              │ operation               │
├──────────────────────┼──────────────┼────────────────────────┤
│ User registration    │ LOW          │ Non-time-sensitive     │
└──────────────────────┴──────────────┴────────────────────────┘
```

---

## 4. Conflict Resolution & Failure Handling

### 4.1 Transaction Retry Logic

```
Transaction Failure Flow:

  Submit Transaction
        ↓
     Success?
     ╱      ╲
   YES       NO
    ↓         ↓
  Update DB  Retry (max 3)
  with tx    with backoff:
  hash       • Attempt 1: 200ms
             • Attempt 2: 400ms
             • Attempt 3: 800ms
                    ↓
               Still failing?
               ╱            ╲
             NO              YES
              ↓               ↓
         Mark as          Mark as
         'failed_retry'   'failed_fatal'
                          + alert operator


Database Status Tracking:
┌──────────────────────────────────────────┐
│ blockchain_status column on every table: │
│                                          │
│ unprocessed    → Not yet submitted       │
│ success        → Confirmed on-chain      │
│ failed_retry   → Failed, will retry      │
│ failed_fatal   → Failed, manual review    │
└──────────────────────────────────────────┘
```

### 4.2 Reorg Handling

```
Slot Reorg Scenario (Rare: <0.1% of slots):

  Expected:  Slot 100 → Slot 101 → Slot 102
  Actual:    Slot 100 → Slot 101' → Slot 102
                          ↑
                    Reorg here

  GridTokenX Response:
  1. Detect slot mismatch during confirmation
  2. Re-index affected slot range
  3. Update blockchain_events table
  4. Reconcile DB state with on-chain truth
  5. Continue processing from new head
```

---

## 5. Governance & Protocol Parameters

### 5.1 Governance Structure

```
┌────────────────────────────────────────────────┐
│         GOVERNANCE PROGRAM (PoA Model)          │
│                                                 │
│  Protocol Authority (Admin)                    │
│  ┌──────────────────────────────────────────┐  │
│  │ • Update fee parameters                 │  │
│  │ • Modify ERC validity periods           │  │
│  │ • Change quality score thresholds       │  │
│  │ • Manage oracle authorities             │  │
│  │ • Upgrade program versions              │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  Current: Centralized (Phase 1)                 │
│  Future: DAO governance (Phase 2)               │
└────────────────────────────────────────────────┘
```

### 5.2 Configurable Parameters

```
┌───────────────────────────────────────────────────────┐
│              PROTOCOL PARAMETERS                       │
├───────────────────────────┬───────────────────────────┤
│ Parameter                 │ Current Value             │
├───────────────────────────┼───────────────────────────┤
│ Market fee (basis points) │ 100 bps (1.0%)            │
│ Min energy trade size     │ 0.001 kWh                 │
│ Max energy trade size     │ 1000 kWh                  │
│ ERC certificate validity  │ 365 days                  │
│ Quality score threshold   │ 70/100                    │
│ Max deviation per reading │ 20% from baseline          │
│ Validator stake required  │ 10,000 GRX                │
└───────────────────────────┴───────────────────────────┘
```

---

## 6. Consensus Performance & Metrics

### 6.1 Real-World Performance

```
┌────────────────────────────────────────────────────────────┐
│              CONSENSUS PERFORMANCE METRICS                  │
├─────────────────────────┬──────────┬──────────┬────────────┤
│ Metric                  │ Target   │ Actual   │ Status     │
├─────────────────────────┼──────────┼──────────┼────────────┤
│ Block inclusion time    │ < 500ms  │ ~320ms   │ ✅ Pass    │
│ Finality (1 slot)       │ < 800ms  │ ~750ms   │ ✅ Pass    │
│ PoP validation time     │ < 2s     │ ~1.8s    │ ✅ Pass    │
│ End-to-end minting      │ < 3s     │ ~2.5s    │ ✅ Pass    │
│ Transaction success     │ > 99%    │ 99.7%    │ ✅ Pass    │
│ Reorg rate               │ < 0.1%   │ 0.05%    │ ✅ Pass    │
└─────────────────────────┴──────────┴──────────┴────────────┘
```

### 6.2 Bottleneck Analysis

```
Transaction Latency Breakdown:

  API Layer      Blockchain     Consensus      DB Update
  ┌──────┐      ┌──────┐      ┌──────┐       ┌──────┐
  │ 50ms │      │ 50ms │      │600ms │       │ 25ms │
  └──────┘      └──────┘      └──────┘       └──────┘
     │              │              │              │
     └──────────────┴──────────────┴──────────────┘
                            ↓
                    Total: ~725ms


  Bottlenecks & Optimizations:
  ┌─────────────────────────┬────────────┬─────────────────────┐
  │ Bottleneck              │ Impact     │ Optimization        │
  ├─────────────────────────┼────────────┼─────────────────────┤
  │ PBKDF2 wallet decrypt   │ ~200ms     │ Batch decryption    │
  │ RPC polling latency     │ 5-15s      │ WebSocket (planned) │
  │ Priority fee estimation │ Variable   │ Dynamic calculation │
  │ Reorg handling          │ Rare       │ Checkpoint replay   │
  └─────────────────────────┴────────────┴─────────────────────┘
```

---

## 7. Consensus Security Model

### 7.1 Trust Assumptions

```
┌────────────────────────────────────────────────────────────┐
│              TRUST MODEL BY COMPONENT                       │
├──────────────────────┬──────────────┬──────────────────────┤
│ Component            │ Trust Model  │ Decentralization     │
├──────────────────────┼──────────────┼──────────────────────┤
│ Solana Consensus     │ PoS          │ ✅ Decentralized     │
│                      │ (validators) │ (1000+ validators)   │
├──────────────────────┼──────────────┼──────────────────────┤
│ Oracle Validation    │ PoA          │ ⚠️ Centralized       │
│                      │ (authorized) │ (v2: decentralized)  │
├──────────────────────┼──────────────┼──────────────────────┤
│ Governance           │ PoA          │ ⚠️ Centralized       │
│                      │ (authority)  │ (DAO planned)        │
├──────────────────────┼──────────────┼──────────────────────┤
│ Energy Certification │ Multi-sig    │ ✅ Validated         │
│                      │ (Oracle +    │ by multiple sources  │
│                      │ Governance)  │                      │
└──────────────────────┴──────────────┴──────────────────────┘
```

### 7.2 Attack Vectors & Mitigations

```
┌─────────────────────────────────────────────────────────────┐
│              SECURITY THREATS & DEFENSES                     │
├──────────────────┬──────────────┬───────────────────────────┤
│ Attack           │ Impact       │ Mitigation                │
├──────────────────┼──────────────┼───────────────────────────┤
│ Oracle           │ Fake energy  │ • Quality scores          │
│ manipulation     │ minting      │ • Anomaly detection       │
│                  │              │ • Rate limits             │
├──────────────────┼──────────────┼───────────────────────────┤
│ Double-spending  │ Duplicate    │ • ERC cert ID uniqueness  │
│                  │ certificates │ • On-chain tracking       │
│                  │              │ • Nullifier pattern       │
├──────────────────┼──────────────┼───────────────────────────┤
│ MEV (sandwich)   │ Front-running│ • Sharded matching engine │
│                  │ trades       │ • Batch processing        │
├──────────────────┼──────────────┼───────────────────────────┤
│ Validator        │ Transaction  │ • Priority fees           │
│ censorship       │ exclusion    │ • Multiple RPC endpoints  │
└──────────────────┴──────────────┴───────────────────────────┘
```

---

## 🔗 Related Documentation

- [Runtime Layer (Sealevel)](./runtime-sealevel.md) - Parallel execution model
- [Storage Layer](./storage-layer.md) - On-chain & off-chain state management
- [Blockchain Architecture](./blockchain-architecture.md) - Solana programs overview
- [Tokenomics](../economic-models/tokenomics.md) - Economic incentive design

---

**Last Updated:** April 6, 2026  
**Maintained By:** GridTokenX Engineering Team
