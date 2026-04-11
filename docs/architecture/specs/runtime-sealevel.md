# Runtime Layer: Sealevel Parallel Execution in GridTokenX

**Version:** 2.0 (Diagram-Focused)  
**Last Updated:** April 6, 2026  
**Status:** ✅ Implemented

---

## Overview

GridTokenX leverages Solana's **Sealevel runtime** to execute smart contracts in parallel, enabling high-throughput energy trading without sequential bottlenecks.

This document explains the parallel execution model, account isolation, and how GridTokenX programs are designed for concurrent processing.

---

## 1. Sealevel Runtime Fundamentals

### 1.1 What is Sealevel?

```
┌─────────────────────────────────────────────────────────────┐
│                  SEALEVEL RUNTIME                            │
│                                                              │
│  Definition: Multi-Threaded Global State Machine            │
│  (vs. single-threaded EVM/EOS WASM runtimes)                │
│                                                              │
│  Core Principle: STRICT SEPARATION OF CODE AND STATE        │
│                                                              │
│  Programs (Code):                       Accounts (State):   │
│  ┌──────────────────────┐              ┌──────────────────┐ │
│  │ • Read-only executables           │ • Mutable state   │ │
│  │ • Compiled to eBPF                │ • Key-value store │ │
│  │ • Via rBPF with JIT               │ • 32-byte addresses│ │
│  │ • Never modified during exec      │ • Store all data  │ │
│  │ • No GPU required (CPU-only)      │ • Rent-exempt     │ │
│  └──────────────────────┘              └──────────────────┘ │
│                                                              │
│  VM Architecture:                                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  rBPF (Rust Berkeley Packet Filter)                  │  │
│  │  • Modified eBPF optimized for Solana               │  │
│  │  • In-kernel VM origin (UNIX packet filtering)      │  │
│  │  • JIT compilation for native speed                 │  │
│  │  • Highly optimized bytecode execution              │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Traditional Blockchains (Sequential):                      │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐              │
│  │Tx 1 │→ │Tx 2 │→ │Tx 3 │→ │Tx 4 │→ │Tx 5 │  ← Slow!     │
│  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘              │
│  (Only parallelize signature verification)                  │
│                                                              │
│  Solana Sealevel (Parallel):                                │
│  ┌─────┐  ┌─────┐                                          │
│  │Tx 1 │  │Tx 2 │  ← No shared accounts, run together      │
│  └─────┘  └─────┘                                          │
│  ┌─────┐                          ┌─────┐                  │
│  │Tx 3 │                          │Tx 5 │  ← Parallel!     │
│  └─────┘                          └─────┘                  │
│           ┌─────┐  ┌─────┐                                 │
│           │Tx 4 │  │Tx 6 │  ← Different accounts, parallel  │
│           └─────┘  └─────┘                                 │
│                                                              │
│  How Parallelism Works:                                     │
│  1. Every transaction EXPLICITLY declares accounts          │
│  2. Runtime scans declarations for conflicts                │
│  3. Non-overlapping transactions → parallel execution       │
│  4. Read-only access on same account → parallel OK          │
│  5. Write access on same account → sequential required      │
│  6. Grouped into "entries" (batches of 64)                  │
│  7. SIMD optimization: instructions sorted by Program ID    │
│                                                              │
│  Scheduling Pipeline:                                       │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │  SORT           │ →  │  SCHEDULE       │                │
│  │  pending txs    │    │  non-overlapping│                │
│  │  by accounts    │    │  across cores   │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                              │
│  Key Principle:                                              │
│  Mandatory account declaration enables safe parallel exec   │
│  Linear scaling with available CPU cores                    │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Core Principles

```
┌─────────────────────────────────────────────────────────────┐
│              SEALEVEL CORE PRINCIPLES                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. STATELESS PROGRAMS                                      │
│     • Smart contract code is read-only                     │
│     • All state stored in separate accounts                 │
│     • Programs cannot modify their own code                 │
│     • Programs execute without internal state               │
│     • All state mutations occur externally                  │
│                                                              │
│  2. EXPLICIT STATE DECLARATION                              │
│     • Transactions declare ALL accounts upfront            │
│     • Before execution, not during                          │
│     • Mirrors OS interfaces: readv/writev (POSIX)          │
│     • Allows VM to prefetch data safely                    │
│     • Enables concurrent scheduling decisions               │
│                                                              │
│  3. ACCOUNT ISOLATION                                       │
│     • Each transaction declares accounts it accesses        │
│     • Runtime checks for conflicts before execution         │
│     • Non-conflicting transactions run in parallel          │
│     • Read-only access on same account = parallel OK        │
│     • Write access on same account = sequential required    │
│                                                              │
│  4. SIMD OPTIMIZATION                                       │
│     • Instructions sorted by Program ID                    │
│     • Same program code runs across multiple data sets     │
│     • Single Instruction, Multiple Data (SIMD)              │
│     • Aligns with CPU/GPU architecture (e.g., NVIDIA CUDA) │
│     • One instruction → 80+ inputs parallel on SM          │
│     • Scales across thousands of cores                     │
│                                                              │
│  5. RUNTIME SCHEDULING                                      │
│     • Solana analyzes account dependencies                  │
│     • Builds execution graph automatically                  │
│     • Sorts millions of pending transactions                │
│     • Schedules non-overlapping in parallel                 │
│     • Applies SIMD batching when possible                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘


  SIMD Execution Example:

  Instruction: trading.create_order(...)

  ┌──────────────────────────────────────────────────┐
  │  Single Instruction (create_order)               │
  │  Applied to Multiple Data Streams:               │
  │                                                   │
  │  Core 1: User A creates Order #1234              │
  │  Core 2: User B creates Order #1235              │
  │  Core 3: User C creates Order #1236              │
  │  Core 4: User D creates Order #1237              │
  │  Core 5: User E creates Order #1238              │
  │  ...                                              │
  │  Core 80: User X creates Order #1313             │
  │                                                   │
  │  All 80 cores execute SAME instruction           │
  │  on DIFFERENT data simultaneously                │
  │                                                   │
  │  Constraint: Minimal branching required          │
  │  (slowest path bounds batch performance)         │
  └──────────────────────────────────────────────────┘
```

### 1.3 GridTokenX Program Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              GRIDTOKENX PROGRAM ECOSYSTEM                    │
│                                                              │
│  ┌──────────────┐                                          │
│  │   Registry   │  Manages users, meters, identities        │
│  │   Program    │  State: UserAccount, MeterAccount         │
│  └──────────────┘                                          │
│         ↕ CPI                                              │
│  ┌──────────────┐                                          │
│  │  Energy      │  Mints/burns GRID tokens                  │
│  │  Token       │  State: TokenInfo, MeterReading           │
│  │  Program     │                                          │
│  └──────────────┘                                          │
│         ↕ CPI                                              │
│  ┌──────────────┐        ┌──────────────┐                 │
│  │   Trading    │ ←CPI→  │   Oracle     │                 │
│  │   Program    │        │   Program    │                 │
│  │              │        │              │                 │
│  │ Orders,      │        │ MeterState,  │                 │
│  │ Trades,      │        │ Quality      │                 │
│  │ Settlement   │        │ Scores       │                 │
│  └──────────────┘        └──────────────┘                 │
│         ↕                                                  │
│  ┌──────────────┐                                          │
│  │  Governance  │  Protocol parameters, ERC certificates   │
│  │  Program     │  State: PoAConfig, ErcCertificate        │
│  └──────────────┘                                          │
│                                                              │
│  CPI = Cross-Program Invocation (programs calling programs) │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Account Model & Isolation

### 2.1 Account Types

```
┌─────────────────────────────────────────────────────────────┐
│              SOLANA ACCOUNT TYPES IN GRIDTOKENX              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PROGRAM ACCOUNTS (Executable, Read-Only)                   │
│  ┌───────────────────────────────────────────────┐         │
│  │ • Contains smart contract code                │         │
│  │ • Owned by BPF loader                         │         │
│  │ • Cannot be modified during execution         │         │
│  │ • Example: Registry Program itself            │         │
│  └───────────────────────────────────────────────┘         │
│                                                              │
│  DATA ACCOUNTS (Stateful, Read-Write)                       │
│  ┌───────────────────────────────────────────────┐         │
│  │ • Stores application state                   │         │
│  │ • Owned by specific program                  │         │
│  │ • Can be created, updated, closed            │         │
│  │ • Examples:                                  │         │
│  │   - UserAccount (user identity)              │         │
│  │   - Order (trading order)                    │         │
│  │   - MeterState (oracle data)                 │         │
│  └───────────────────────────────────────────────┘         │
│                                                              │
│  TOKEN ACCOUNTS (SPL Standard)                              │
│  ┌───────────────────────────────────────────────┐         │
│  │ • Associated Token Accounts (ATAs)            │         │
│  │ • Hold token balances                         │         │
│  │ • Owned by SPL Token program                 │         │
│  │ • Examples:                                  │         │
│  │   - User's GRID token balance                │         │
│  │   - Escrow account                           │         │
│  └───────────────────────────────────────────────┘         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Account Structure

```
Every GridTokenX Data Account:

┌────────────────────────────────────────────┐
│              ACCOUNT STRUCTURE              │
├────────────────────────────────────────────┤
│                                            │
│  Discriminator (8 bytes)                   │
│  • Identifies account type                 │
│  • Prevents type confusion attacks         │
│                                            │
│  Data (variable size, aligned to 256 bytes)│
│  • Program-specific state                  │
│  • Fixed-size fields for efficiency        │
│  • Padding for alignment                   │
│                                            │
│  Metadata (managed by runtime)             │
│  • Owner (which program owns this account) │
│  • Lamports (rent-exempt balance)          │
│  • Executable flag (false for data)        │
│                                            │
└────────────────────────────────────────────┘


Example Account Sizes:

┌────────────────────────┬──────────┬──────────────┐
│ Account Type           │ Size     │ Rent Cost    │
├────────────────────────┼──────────┼──────────────┤
│ UserAccount            │ 256 B    │ $0.10        │
│ MeterAccount           │ 256 B    │ $0.10        │
│ Order                  │ 256 B    │ $0.10        │
│ TradeRecord            │ 256 B    │ $0.10        │
│ Market (singleton)     │ 1,024 B  │ $0.39        │
│ ZoneMarket             │ 512 B    │ $0.20        │
│ ErcCertificate         │ 512 B    │ $0.20        │
└────────────────────────┴──────────┴──────────────┘


Account Access Rules:

┌────────────────────────────────────────────────────────┐
│                  ACCESS CONTROL                         │
├────────────────────────────────────────────────────────┤
│                                                        │
│  Programs can MODIFY accounts they OWN:                │
│  ✓ Registry Program → UserAccount, MeterAccount        │
│  ✓ Trading Program → Order, TradeRecord                │
│  ✓ Oracle Program → MeterState                         │
│                                                        │
│  Programs can CREDIT any account:                      │
│  ✓ Any program can add lamports (SOL)                  │
│  ✓ No ownership restriction                            │
│                                                        │
│  Programs CANNOT debit accounts they don't own:        │
│  ✗ Trading Program cannot touch UserAccount            │
│  ✗ Oracle Program cannot touch Order                   │
│                                                        │
│  System Program (default owner):                       │
│  • Can assign ownership (permanent, one-time)          │
│  • Can allocate zero-initialized data                  │
│  • Creates accounts, funds them                        │
│                                                        │
└────────────────────────────────────────────────────────┘


Program Loading Workflow:

  1. Create Account (System Program)
     ↓
  2. Fund Account with rent-exempt SOL
     ↓
  3. Allocate Memory (via System Program)
     ↓
  4. Assign Ownership to Loader (permanent)
     ↓
  5. Upload Bytecode (in chunks)
     ↓
  6. Loader Verifies Bytecode
     ↓
  7. Mark Account as Executable
     ↓
  Program Ready for Execution
```

### 2.3 PDA (Program Derived Address)

```
What is a PDA?

  Traditional Blockchain:
  • Accounts have public/private key pairs
  • Users sign transactions with private key

  Solana PDA:
  • Accounts derived deterministically (no private key)
  • Only the program can "sign" for these accounts
  • Address derived from: seeds + program ID

PDA Derivation:

  Seeds (inputs)                Program ID
  ┌──────────────┐              ┌────────────┐
  │ "user"       │              │            │
  │ authority    │    +         │ Registry   │  →  UserAccount PDA
  │ pubkey       │              │ Program ID │
  └──────────────┘              └────────────┘
         ↓                              ↓
  ┌─────────────────────────────────────────────┐
  │  find_program_address(seeds, program_id)    │
  │  → Returns: (PDA, bump_seed)                │
  └─────────────────────────────────────────────┘


GridTokenX PDA Patterns:

┌────────────────────────────────────────────────────────────┐
│ Account              │ Seeds                              │
├────────────────────────────────────────────────────────────┤
│ UserAccount          │ ["user", authority_pubkey]          │
│ MeterAccount         │ ["meter", meter_id]                 │
│ Order                │ ["order", authority_pubkey, index]  │
│ Market               │ ["market"]                          │
│ ZoneMarket           │ ["zone_market", market_pda, zone_id]│
│ MarketShard          │ ["market_shard", market_pda, shard] │
│ MeterState           │ ["meter", meter_id]                 │
│ ErcCertificate       │ ["erc_certificate", certificate_id] │
│ PoAConfig            │ ["poa_config"]                      │
└────────────────────────────────────────────────────────────┘

PDA Benefits:
✓ Deterministic: Same inputs → same address every time
✓ Program-controlled: Only program can modify
✓ Collision-resistant: Unique per user/order/meter
✓ Off-chain derivable: API can derive without on-chain lookup
```

---

## 3. Parallel Execution Patterns

### 3.1 How Sealevel Schedules GridTokenX Transactions

```
OS-Inspired Transaction Design:

  Solana transactions mirror POSIX readv/writev interfaces:

  ┌──────────────────────────────────────────────────────┐
  │  C Language: struct iovec                            │
  │  struct iovec {                                      │
  │      void  *iov_base;    // Memory address           │
  │      size_t iov_len;     // Bytes to read/write      │
  │  };                                                  │
  │                                                      │
  │  ssize_t readv(int fd, const struct iovec *iov, ...);│
  │  ssize_t writev(int fd, const struct iovec *iov,...);│
  └──────────────────────────────────────────────────────┘

  Solana Transaction Structure (from Ackee Solana Book):

  ┌──────────────────────────────────────────────────────────────┐
  │                      TRANSACTION                              │
  ├──────────────────────────────────────────────────────────────┤
  │                                                               │
  │  Signatures                                                    │
  │  ┌──────────────────────────────────────────────────┐        │
  │  │ Compact Array of 64-byte Ed25519 signatures      │        │
  │  │ • Signature [0] → Account [0]                   │        │
  │  │ • Signature [1] → Account [1]                   │        │
  │  │ • ...                                            │        │
  │  └──────────────────────────────────────────────────┘        │
  │                           ↓                                   │
  │  Message                                                       │
  │  ┌──────────────────────────────────────────────────┐        │
  │  │  Header (24 bits total)                          │        │
  │  │  ┌────────────────────────────────────────────┐  │        │
  │  │  │ 8 bits: Total required signatures          │  │        │
  │  │  │ 8 bits: Read-only accounts w/ signatures   │  │        │
  │  │  │ 8 bits: Read-only accounts w/o signatures  │  │        │
  │  │  └────────────────────────────────────────────┘  │        │
  │  ├──────────────────────────────────────────────────┤        │
  │  │  Accounts (Compact Array of Public Keys)        │        │
  │  │  ┌────────────────────────────────────────────┐  │        │
  │  │  │ [0..n]: Signers (Read-Write)               │  │        │
  │  │  │ [n..m]: Signers (Read-Only)                │  │        │
  │  │  │ [m..p]: Non-Signers (Read-Write)           │  │        │
  │  │  │ [p..q]: Non-Signers (Read-Only)            │  │        │
  │  │  └────────────────────────────────────────────┘  │        │
  │  │  ↑ STRICT ORDER: categorical, fixed              │        │
  │  ├──────────────────────────────────────────────────┤        │
  │  │  Recent Blockhash (32 bytes)                     │        │
  │  │  • Ties to Proof of History                      │        │
  │  │  • ~1 minute expiry (150 blocks)                 │        │
  │  │  • Prevents replay attacks                       │        │
  │  ├──────────────────────────────────────────────────┤        │
  │  │  Instructions (Compact Array)                    │        │
  │  │  ┌────────────────────────────────────────────┐  │        │
  │  │  │ Instruction [0]                            │  │        │
  │  │  │  • 1 byte: Program ID Index                │  │        │
  │  │  │  • Compact Array: Account Indices          │  │        │
  │  │  │  • Compact Array: 8-bit Instruction Data   │  │        │
  │  │  ├────────────────────────────────────────────┤  │        │
  │  │  │ Instruction [1]                            │  │        │
  │  │  │  • 1 byte: Program ID Index                │  │        │
  │  │  │  • Compact Array: Account Indices          │  │        │
  │  │  │  • Compact Array: 8-bit Instruction Data   │  │        │
  │  │  └────────────────────────────────────────────┘  │        │
  │  └──────────────────────────────────────────────────┘        │
  └──────────────────────────────────────────────────────────────┘

  Compact Array Format:
  ┌────────────────────────────────────────┐
  │ 16-bit length prefix (max 65,535)     │
  │ followed by sequential elements       │
  │ Actual limits: packet size + compute  │
  └────────────────────────────────────────┘

  Benefit: VM knows memory access pattern BEFORE execution
  → Can prefetch data from Cloudbreak database
  → Can schedule parallel execution safely
  → No runtime surprises or conflicts


Scenario: Three users submit orders simultaneously

  Transaction A: User 1 creates order
  • Reads: Market PDA, User1 PDA
  • Writes: Order1 PDA, MarketShard1

  Transaction B: User 2 creates order
  • Reads: Market PDA, User2 PDA
  • Writes: Order2 PDA, MarketShard2

  Transaction C: Settle trade (Order1 ↔ Order2)
  • Reads: Order1, Order2, Market
  • Writes: TradeRecord, Token ATAs (4 accounts)


  Runtime Analysis:

  ┌───────────────────────────────────────────────┐
  │ Transaction A  Transaction B                  │
  │ ┌───────────┐  ┌───────────┐                 │
  │ │ Reads:    │  │ Reads:    │                 │
  │ │  Market   │  │  Market   │  ← Shared read  │
  │ │  User1    │  │  User2    │  ← Different ✓  │
  │ │ Writes:   │  │ Writes:   │                 │
  │ │  Order1   │  │  Order2   │  ← Different ✓  │
  │ │  Shard1   │  │  Shard2   │  ← Different ✓  │
  │ └───────────┘  └───────────┘                 │
  │        ↓              ↓                       │
  │   EXECUTE IN PARALLEL (no write conflicts)    │
  └───────────────────────────────────────────────┘
                    ↓ (both complete)
  ┌───────────────────────────────────────────────┐
  │            Transaction C                      │
  │   ┌──────────────────────────────┐           │
  │   │ Reads: Order1, Order2        │           │
  │   │ Writes: TradeRecord, ATAs    │           │
  │   └──────────────────────────────┘           │
  │                                               │
  │   EXECUTES SEQUENTIALLY                       │
  │   (depends on A & B completion)               │
  └───────────────────────────────────────────────┘
```

### 3.2 Sharding: GridTokenX's Parallelism Strategy

```
Problem: Write Contention

  Without Sharding:
  ┌──────────────────────────────────────┐
  │          Market Account              │
  │  ┌────────────────────────────┐     │
  │  │ total_orders: 1523         │     │
  │  │ active_orders: 245         │     │
  │  └────────────────────────────┘     │
  │         ↑    ↑    ↑    ↑             │
  │      Tx1  Tx2  Tx3  Tx4  ← All write here!
  │                                      │
  │  Result: Sequential execution        │
  │  (runtime must serialize writes)     │
  └──────────────────────────────────────┘


  With Sharding:
  ┌──────────────────────────────────────────────┐
  │          Market (read-only for most)         │
  │                                              │
  │  ┌─────────┐ ┌─────────┐ ┌─────────┐       │
  │  │ Shard 0 │ │ Shard 1 │ │ Shard 2 │  ...  │
  │  │ orders: │ │ orders: │ │ orders: │       │
  │  │   15    │ │   12    │ │   18    │       │
  │  └─────────┘ └─────────┘ └─────────┘       │
  │      ↑          ↑           ↑                │
  │     Tx1        Tx2         Tx3   ← Different shards!
  │                                              │
  │  Result: Parallel execution                  │
  │  (16 shards = up to 16x parallelism)         │
  └──────────────────────────────────────────────┘


Zone-Based Sharding (Geographic):

  Zone 1 (North)     Zone 2 (East)      Zone 3 (West)
  ┌──────────┐      ┌──────────┐       ┌──────────┐
  │ ZoneMkt 1│      │ ZoneMkt 2│       │ ZoneMkt 3│
  │ Buy: 45  │      │ Buy: 32  │       │ Buy: 28  │
  │ Sell: 38 │      │ Sell: 41 │       │ Sell: 35 │
  └──────────┘      └──────────┘       └──────────┘
       ↓                  ↓                  ↓
  Trades in Zone 1  Trades in Zone 2  Trades in Zone 3
  don't block       don't block       don't block
  other zones       other zones       other zones


  Shard Assignment Logic:
  ┌─────────────────────────────────────────┐
  │ User ID + Zone ID → Hash → Shard (0-15)│
  │                                         │
  │ Example:                                │
  │ User in Zone 1 → Hash → Shard 7        │
  │ User in Zone 2 → Hash → Shard 12       │
  │ User in Zone 1 → Hash → Shard 3        │
  │ (same zone, different shard possible)   │
  └─────────────────────────────────────────┘
```

### 3.3 Sharding Benefits

```
┌───────────────────────────────────────────────────────────┐
│              SHARDING BENEFITS                             │
├─────────────────────┬─────────────────────────────────────┤
│ Benefit             │ Explanation                         │
├─────────────────────┼─────────────────────────────────────┤
│ Reduced Contention  │ Multiple orders created             │
│                     │ simultaneously if different shards   │
├─────────────────────┼─────────────────────────────────────┤
│ Zone Isolation      │ Trading in Zone A doesn't block     │
│                     │ Zone B                              │
├─────────────────────┼─────────────────────────────────────┤
│ Linear Scalability  │ Add more shards to increase         │
│                     │ throughput proportionally           │
├─────────────────────┼─────────────────────────────────────┤
│ Fault Isolation     │ If one shard is slow, others        │
│                     │ continue normally                   │
├─────────────────────┼─────────────────────────────────────┤
│ Geographic Locality │ Orders in same zone more likely     │
│                     │ to match, reducing cross-zone       │
│                     │ transactions                        │
└─────────────────────┴─────────────────────────────────────┘
```

---

## 4. Cross-Program Invocations (CPIs)

### 4.1 What are CPIs?

```
Cross-Program Invocation:

  Program A calls Program B during execution

  ┌──────────────────────────────────────────────────┐
  │            Transaction Execution                  │
  │                                                    │
  │  ┌────────────────┐                              │
  │  │ Trading Program│ ← User calls this             │
  │  │ (entry point)  │                               │
  │  └────────┬───────┘                              │
  │           │                                       │
  │           │ CPI                                   │
  │           ↓                                       │
  │  ┌────────────────┐                              │
  │  │ SPL Token      │ ← Transfers tokens           │
  │  │ Program        │   (escrow, settlement)        │
  │  └────────────────┘                              │
  │                                                    │
  │  All or nothing:                                  │
  │  • If CPI fails, entire transaction fails         │
  │  • If CPI succeeds, changes are committed         │
  │  • Atomic: no partial execution possible          │
  └──────────────────────────────────────────────────┘
```

### 4.2 GridTokenX CPI Flows

```
FLOW 1: Order Creation with Escrow

  User → Trading Program → SPL Token Program
   │           │                  │
   │           │ 1. Create order  │
   │           │    account       │
   │           ├─────────────────→│
   │           │                  │ 2. Transfer tokens
   │           │                  │    to escrow
   │           │←─────────────────┤
   │           │    (tokens locked)
   │←──────────┤
   │ Order confirmed
   │ + escrow receipt


  Accounts Accessed:
  ┌─────────────────────────────────────────────────────┐
  │ Account              │ Access     │ Program         │
  ├─────────────────────────────────────────────────────┤
  │ Order PDA            │ Read-Write │ Trading         │
  │ User wallet          │ Read       │ System          │
  │ User energy ATA      │ Read-Write │ SPL Token       │
  │ Escrow ATA           │ Read-Write │ SPL Token       │
  └─────────────────────────────────────────────────────┘


FLOW 2: Atomic Settlement (Multi-Token Transfer)

  Platform Authority → Trading Program
                              │
                    ┌─────────┼─────────┐
                    ↓         ↓         ↓
               ┌────────┐ ┌────────┐ ┌────────┐
               │Energy  │ │Currency│ │  Fee   │
               │Token   │ │ Token  │ │Collect │
               │Program │ │Program │ │Program │
               └────────┘ └────────┘ └────────┘
                    ↓         ↓         ↓
               Transfer   Transfer   Transfer
               energy     currency   fee
               to buyer   to seller  to platform
                    ↓         ↓         ↓
                    └─────────┴─────────┘
                              ↓
                    All three succeed
                    or all fail (atomic)


  Settlement Guarantees:
  ✓ Buyer receives energy tokens
  ✓ Seller receives currency tokens
  ✓ Platform receives fee
  ✓ No partial settlement possible
  ✓ Escrow authority ensures only program releases funds
```

### 4.3 CPI Performance

```
┌────────────────────────────────────────────────────┐
│              CPI EXECUTION COST                     │
├──────────────────────┬───────────────┬─────────────┤
│ CPI Depth            │ Compute Units │ Typical Use │
├──────────────────────┼───────────────┼─────────────┤
│ Single program       │ ~5,000 CU     │ Order       │
│                      │               │ creation    │
├──────────────────────┼───────────────┼─────────────┤
│ 1 CPI (SPL Token)    │ ~10,000 CU    │ Token       │
│                      │               │ transfers   │
├──────────────────────┼───────────────┼─────────────┤
│ 2-3 CPIs             │ ~25,000 CU    │ Settlement  │
│                      │               │ with verify │
├──────────────────────┼───────────────┼─────────────┤
│ 4+ CPIs              │ ~50,000+ CU   │ Meter       │
│ (complex flows)      │               │ → ERC → Mint│
├──────────────────────┼───────────────┼─────────────┤
│ Budget limit         │ 200,000 CU    │ Per tx      │
└──────────────────────┴───────────────┴─────────────┘

GridTokenX Usage: 15,000-40,000 CU typical (well within budget)
```

---

## 5. State Management & Memory Model

### 5.1 On-Chain vs Off-Chain State

```
┌────────────────────────────────────────────────────────────┐
│              STATE PLACEMENT DECISION                       │
├──────────────────────┬──────────┬──────────────────────────┤
│ Data Type            │ Location │ Rationale                │
├──────────────────────┼──────────┼──────────────────────────┤
│ User identity        │ On-chain │ Canonical ownership      │
│ User profile (email) │ Off-chain│ Privacy, not needed      │
│                      │          │ on-chain                 │
├──────────────────────┼──────────┼──────────────────────────┤
│ Orders               │ On-chain │ Settlement authority     │
│ Order history        │ Off-chain│ Indexing efficiency      │
├──────────────────────┼──────────┼──────────────────────────┤
│ Trades               │ On-chain │ Immutable audit trail    │
│ Trade metadata       │ Off-chain│ Complex queries          │
├──────────────────────┼──────────┼──────────────────────────┤
│ Token balances       │ On-chain │ Financial truth (SPL)    │
│ Balance cache        │ Off-chain│ Performance (Redis)      │
├──────────────────────┼──────────┼──────────────────────────┤
│ Meter readings       │ On-chain │ Certification snapshot   │
│ Time-series data     │ Off-chain│ Volume, queries          │
├──────────────────────┼──────────┼──────────────────────────┤
│ Price history        │ On-chain │ 24-entry ring buffer     │
│ Full history         │ Off-chain│ Unlimited storage        │
├──────────────────────┼──────────┼──────────────────────────┤
│ User passwords       │ Off-chain│ Security (PostgreSQL)    │
│ Encrypted keys       │ Off-chain│ Encrypted storage        │
└──────────────────────┴──────────┴──────────────────────────┘
```

### 5.2 Zero-Copy Memory Access

```
Traditional Approach (Slow):

  1. Read account from blockchain
  2. Deserialize entire account into memory
  3. Access specific field
  4. Serialize back when done

  Overhead: ~50-100μs per account


GridTokenX Zero-Copy Approach (Fast):

  1. Read account from blockchain
  2. Direct memory access (no deserialization)
  3. Access specific field in-place
  4. Changes written directly

  Overhead: ~5-10μs per account

  Performance Improvement: 10x faster

Zero-Copy Requirements:
✓ Fixed-size fields (no variable-length arrays)
✓ Proper alignment (256-byte boundaries)
✓ Padding bytes for alignment
✓ All fields have known size at compile time
```

---

## 6. Runtime Security & Sandboxing

### 6.1 Sealevel Security Model

```
┌──────────────────────────────────────────────────────────┐
│              RUNTIME ISOLATION GUARANTEES                 │
│                                                           │
│  Program A (Registry)                Program B (Trading) │
│  ┌────────────────────────┐         ┌─────────────────┐ │
│  │ • Can ONLY access      │         │ • Isolated from │ │
│  │   declared accounts    │         │   Program A     │ │
│  │ • CANNOT access Program│         │ • Own account   │ │
│  │   B's accounts         │         │   namespace     │ │
│  │ • CANNOT make HTTP     │         │ • Deterministic │ │
│  │   calls                │         │   execution     │ │
│  │ • CANNOT access file   │         │ • No side       │ │
│  │   system               │         │   effects       │ │
│  │ • CANNOT spawn threads │         │   outside       │ │
│  │                        │         │   accounts      │ │
│  └────────────────────────┘         └─────────────────┘ │
│                                                           │
│  Result: Programs cannot interfere with each other       │
└──────────────────────────────────────────────────────────┘
```

### 6.2 GridTokenX Runtime Safeguards

```
Input Validation (prevents invalid state transitions):

  Order Parameters Check:
  ┌────────────────────────────────────┐
  │ ✓ Amount > 0                       │
  │ ✓ Amount ≤ Maximum allowed         │
  │ ✓ Price > 0                        │
  │ ✓ Price ≤ Maximum allowed          │
  │ ✓ Expiration in future             │
  │ ✓ User has sufficient balance      │
  └────────────────────────────────────┘

Authority Checks (prevents unauthorized access):

  ┌────────────────────────────────────┐
  │ Operation          │ Required      │
  ├────────────────────┼───────────────┤
  │ Create order       │ User wallet   │
  │ Cancel order       │ Order owner   │
  │ Settle trade       │ Program auth  │
  │ Update market cfg  │ Market auth   │
  │ Register meter     │ User + Oracle │
  └────────────────────────────────────┘

Reentrancy Protection:

  Solana prevents reentrancy by design:
  • Programs cannot call themselves during execution
  • No recursive instruction execution
  • Each transaction has fixed instruction limit

  GridTokenX adds explicit checks:
  • Verify order status before settlement
  • Prevent double-settlement of same order
  • Check nullifier before processing
```

---

## 7. Runtime Performance Optimization

### 7.1 Compute Unit Usage

```
┌──────────────────────────────────────────────────────┐
│              GRIDTOKENX COMPUTE UNIT USAGE            │
├────────────────────────────┬─────────────┬───────────┤
│ Operation                  │ Compute U.  │ % Budget  │
├────────────────────────────┼─────────────┼───────────┤
│ User registration          │ ~8,000 CU   │ 4%        │
│ Order creation             │ ~15,000 CU  │ 7.5%      │
│ Meter reading submission   │ ~12,000 CU  │ 6%        │
│ Trade settlement (3 CPIs)  │ ~35,000 CU  │ 17.5%     │
│ ERC certificate issuance   │ ~18,000 CU  │ 9%        │
├────────────────────────────┼─────────────┼───────────┤
│ Budget limit               │ 200,000 CU  │ 100%      │
└────────────────────────────┴─────────────┴───────────┘

Headroom: Plenty of room for complex multi-CPI transactions
```

### 7.2 Optimization Techniques

```
Technique 1: Account Reuse

  Problem: Creating new accounts for every operation is expensive

  Solution: Order Nullifier Pattern
  ┌─────────────────────────────────────────┐
  │  OrderNullifier Account (reusable)      │
  │  • order_id: Unique identifier          │
  │  • authority: Who owns this             │
  │  • filled_amount: How much settled      │
  │                                         │
  │  Prevents double-spend without          │
  │  creating new accounts each time        │
  └─────────────────────────────────────────┘


Technique 2: Ring Buffer for Price History

  Fixed 24-entry array (no reallocation):

  ┌─────┬─────┬─────┬─────┬─────┬─────┐
  │ P1  │ P2  │ P3  │ P4  │ P5  │ ... │  ← 24 entries total
  └─────┴─────┴─────┴─────┴─────┴─────┘
                    ↑
                  Head (next write position)

  Add price: O(1) operation
  • Write at head position
  • Increment head (wrap around at 24)
  • No memory allocation needed


Technique 3: Batch Operations

  Market maintains batch of up to 32 orders:
  ┌──────────────────────────────────────┐
  │ Current Batch:                       │
  │ [Order1, Order2, Order3, ..., N]    │
  │ (max 32 orders)                      │
  │                                      │
  │ Execute all at once → save compute   │
  └──────────────────────────────────────┘


Technique 4: Minimal On-Chain Logging

  Instead of storing logs on-chain (expensive):
  • Emit events (stored in transaction log)
  • Off-chain indexer persists to database
  • On-chain only stores current state
```

---

## 8. Runtime in GridTokenX Architecture

### 8.1 Complete Stack Context

```
┌────────────────────────────────────────────────────┐
│              APPLICATION LAYER                      │
│  API Gateway → Matching Engine → Settlement Mgr    │
└────────────────────────────────────────────────────┘
                     ↓ (RPC calls)
┌────────────────────────────────────────────────────┐
│              CONSENSUS LAYER                        │
│  PoH + Tower BFT + PoP (Application consensus)     │
└────────────────────────────────────────────────────┘
                     ↓ (Transaction execution)
┌────────────────────────────────────────────────────┐
│         RUNTIME LAYER (Sealevel) ← This document   │
│  • Parallel program execution                      │
│  • Account isolation                               │
│  • CPIs, zero-copy access, PDA derivation          │
└────────────────────────────────────────────────────┘
                     ↓ (Account reads/writes)
┌────────────────────────────────────────────────────┐
│              STORAGE LAYER                          │
│  Cloudbreak (accounts), Archivers (historical)     │
└────────────────────────────────────────────────────┘
```

### 8.2 GridTokenX-Specific Runtime Features

```
┌───────────────────────────────────────────────────────┐
│              RUNTIME FEATURES SUMMARY                   │
├──────────────────────────┬────────────────────────────┤
│ Feature                  │ Implementation             │
├──────────────────────────┼────────────────────────────┤
│ Zone-based sharding      │ ZoneMarket accounts per    │
│                          │ geographic zone            │
├──────────────────────────┼────────────────────────────┤
│ Order nullifier pattern  │ OrderNullifier prevents    │
│                          │ double-spend               │
├──────────────────────────┼────────────────────────────┤
│ Ring buffer price history│ Fixed 24-entry array in    │
│                          │ Market (O(1) updates)      │
├──────────────────────────┼────────────────────────────┤
│ Sharded counters         │ RegistryShard, MarketShard │
│                          │ reduce write contention    │
├──────────────────────────┼────────────────────────────┤
│ PDA-based escrow         │ Program authority controls │
│                          │ token locks                │
├──────────────────────────┼────────────────────────────┤
│ SIMD-friendly design     │ GridTokenX programs use    │
│                          │ minimal branching, ideal   │
│                          │ for SIMD batching          │
└──────────────────────────┴────────────────────────────┘


Cloudbreak Database Integration:

  ┌──────────────────────────────────────────────────┐
  │  Cloudbreak: Horizontally-Scaled Key-Value Store │
  │                                                   │
  │  • Maps Public Keys → Accounts                   │
  │  • Stores: balances, data (byte vector), owner   │
  │  • Optimized for parallel reads/writes           │
  │  • Used by all validators during execution       │
  │                                                   │
  │  GridTokenX Impact:                              │
  │  ✓ Account lookups are O(1)                      │
  │  ✓ Parallel reads don't block each other         │
  │  ✓ Writes locked to specific accounts only       │
  │  ✓ Scales with validator hardware                │
  └──────────────────────────────────────────────────┘


Performance Benchmarks (Solana Testnet):

  ┌──────────────────────────────────────────────────┐
  │ • 50,000+ TPS sustained                         │
  │ • 200 physically distinct nodes                 │
  │ • GPU-accelerated validators                    │
  │ • SIMD optimization across cores                │
  │                                                   │
  │  GridTokenX Typical Usage:                       │
  │  • Order creation: ~15,000 CU                    │
  │  • Settlement: ~35,000 CU                        │
  │  • Well within 200,000 CU budget                 │
  └──────────────────────────────────────────────────┘
```

---

## 9. Debugging & Monitoring

### 9.1 Transaction Simulation

```
Before submitting transaction to blockchain:

  ┌─────────────────────────────────────┐
  │  1. Build transaction               │
  │  2. Simulate (doesn't submit)       │
  │  3. Check for errors                │
  │  4. If clean → submit for real      │
  │  5. If error → fix and retry        │
  └─────────────────────────────────────┘

  Benefits:
  ✓ Catches errors before spending SOL
  ✓ Shows compute unit usage
  ✓ Reveals account access patterns
  ✓ Identifies permission issues
```

### 9.2 Compute Unit Profiling

```
Development Mode (localnet only):

  Enable checkpoints in code:
  • Start operation → checkpoint
  • Expensive computation → checkpoint
  • End operation → checkpoint

  Analyze:
  • Which operation uses most compute?
  • Are there unexpected costs?
  • Can we optimize hot paths?

  Production: Checkpoints disabled (zero overhead)
```

---

## 🔗 Related Documentation

- [Consensus Layer](./consensus-layer.md) - PoH, PoP, and finality
- [Storage Layer](./storage-layer.md) - On-chain vs off-chain state
- [Smart Contract Architecture](./smart-contract-architecture.md) - Program implementations
- [Solana Runtime Docs](https://docs.solana.com/developing/programming-model/runtime) - Official documentation

---

**Last Updated:** April 6, 2026  
**Maintained By:** GridTokenX Engineering Team
