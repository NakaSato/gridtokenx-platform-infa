# Smart Contract Design and Implementation
## GridTokenX Platform

---

## 1. Overview

GridTokenX implements a suite of **Solana-native smart contracts** (called Programs in Solana terminology) using the **Anchor framework**. The programs enforce trustless P2P energy trading, digital identity management, and renewable energy certification.

**Core Design Principles:**
*   **Deterministic State**: All trading logic executed on-chain for verifiable settlement.
*   **Program Derived Addresses (PDAs)**: Link Web2 database IDs to Web3 accounts without private keys.
*   **Cross-Program Invocation (CPI)**: Atomic composability between programs.
*   **Zero-Copy Deserialization**: High-performance account loading using `AccountLoader<>`.

---

## 2. Program Architecture

### 2.1 Program Inventory

| Program | Program ID | Purpose |
|---------|-----------|---------|
| **Registry** | `2XPQmFYMdXjP7ffoBB3mXeCdboSFg5Yeb6QmTSGbW8a7` | User/Meter identity management |
| **Trading** | `GZnqNTJsre6qB4pWCQRE9FiJU2GUeBtBDPp6s7zosctk` | P2P energy marketplace |
| **Energy Token** | `94G1r674LmRDmLN2UPjDFD8Eh7zT8JaSaxv9v68GyEur` | GRID token (SPL Token-2022) |
| **Oracle** | `DvdtU4quEbuxUY2FckmvcXwTpC9qp4HLJKb1PMLaqAoE` | Meter reading validation |
| **Governance** | `4DY97YYBt4bxvG7xaSmWy3MhYhmA6HoMajBHVqhySvXe` | Renewable Energy Certificates (RECs) |
| **BLOCKBENCH** | `BLKbnchMrk1111111111111111111111111111111111` | Performance benchmarking suite |

### 2.2 Program Interaction Flow

```
┌─────────────┐
│   Client    │ (Next.js + Wallet Adapter)
└──────┬──────┘
       │ JSON RPC
       ▼
┌─────────────────────────────────────────────┐
│          Solana Validator Network           │
│                                             │
│  ┌──────────┐        ┌──────────┐         │
│  │ Registry │◄──────►│ Trading  │         │
│  │ Program  │  CPI   │ Program  │         │
│  └────┬─────┘        └────┬─────┘         │
│       │                   │                │
│       │ CPI               │ CPI            │
│       ▼                   ▼                │
│  ┌──────────┐        ┌──────────┐         │
│  │  Oracle  │        │  Energy  │         │
│  │ Program  │        │  Token   │         │
│  └──────────┘        └──────────┘         │
│       ▲                                    │
│       │                                    │
└───────┼────────────────────────────────────┘
        │
   ┌────┴────┐
   │ API GW  │ (Trusted Oracle Authority)
   └─────────┘
```

---

## 3. Registry Program (Identity Layer)

**Purpose**: Manages deterministic mapping between users/meters and blockchain accounts.

### 3.1 Core Instructions

#### `initialize`
*   Creates the global `Registry` account.
*   Sets the program authority (admin).
*   **PDA**: `[b"registry"]`

#### `register_user`
*   Creates a `UserAccount` tied to a wallet.
*   Stores user type (Prosumer/Consumer), geolocation, and status.
*   **PDA**: `[b"user", user_pubkey]`

**Account Structure:**
```rust
pub struct UserAccount {
    pub authority: Pubkey,         // Wallet address
    pub user_type: UserType,       // Prosumer | Consumer
    pub lat: f64,                  // Latitude
    pub long: f64,                 // Longitude
    pub status: UserStatus,        // Active | Suspended
    pub registered_at: i64,        // Unix timestamp
    pub meter_count: u32,          // Number of registered meters
}
```

#### `register_meter`
*   Links a smart meter to a user account.
*   Tracks lifetime generation/consumption.
*   **PDA**: `[b"meter", user_pubkey, meter_id.as_bytes()]`

**Account Structure:**
```rust
pub struct MeterAccount {
    pub meter_id: [u8; 32],             // Fixed-size meter serial
    pub owner: Pubkey,                  // User who owns the meter
    pub meter_type: MeterType,          // Solar | Grid | Hybrid
    pub status: MeterStatus,            // Active | Inactive
    pub registered_at: i64,             // Registration timestamp
    pub last_reading_at: i64,           // Latest reading timestamp
    pub total_generation: u64,          // Lifetime energy produced (Wh)
    pub total_consumption: u64,         // Lifetime energy consumed (Wh)
    pub settled_net_generation: u64,    // Tokenized energy (prevents double-mint)
    pub claimed_erc_generation: u64,    // Energy claimed as RECs
}
```

### 3.2 Oracle Integration

#### `set_oracle_authority`
*   Authorizes the API Gateway to submit meter readings.
*   Only callable by program authority.

#### `update_meter_reading`
*   Updates `total_generation` and `total_consumption`.
*   Only callable by the designated oracle (API Gateway).
*   **Validation**: Ensures readings are monotonically increasing.

### 3.3 Token Settlement

#### `get_unsettled_balance`
*   **View Function**: Returns `total_generation - total_consumption - settled_net_generation`.
*   Used by clients to check how much energy can be tokenized.

#### `settle_meter_balance`
*   Updates `settled_net_generation` to current net generation.
*   Emits `MeterBalanceSettled` event.
*   **Prevents Double-Minting**: Tracks already-tokenized energy.

#### `settle_and_mint_tokens`
*   **Atomic Operation**: Settles balance + mints GRID tokens via CPI.
*   Calls `energy_token::mint_tokens_direct` in a single transaction.

---

## 4. Trading Program (Marketplace Layer)

**Purpose**: Implements a trustless order book for P2P energy trading.

### 4.1 Market State

#### `initialize_market`
*   Creates the `Market` account with order book state.
*   Configures market fee (default: 0.25% or 25 basis points).
*   **PDA**: `[b"market"]`

**Market Structure:**
```rust
pub struct Market {
    pub authority: Pubkey,               // Market admin
    pub active_orders: u32,              // Open orders count
    pub total_volume: u64,               // Lifetime traded volume (Wh)
    pub total_trades: u64,               // Lifetime trade count
    pub market_fee_bps: u16,             // Fee in basis points
    pub clearing_enabled: u8,            // Batch clearing toggle
    pub last_clearing_price: u64,        // Last market-clearing price
    
    // Order Book Depth (20 price levels per side)
    pub buy_side_depth: [PriceLevel; 20],
    pub sell_side_depth: [PriceLevel; 20],
    
    // Price Discovery
    pub price_history: [PricePoint; 24], // Hourly VWAP
    pub volume_weighted_price: u64,
}
```

### 4.2 Order Management

#### `create_sell_order`
*   Creates a sell order for surplus energy.
*   **Validation**: Checks for valid REC certificate (if provided).
*   Locks seller's energy tokens in escrow.

**Order Structure:**
```rust
pub struct Order {
    pub seller: Pubkey,
    pub buyer: Pubkey,                 // Filled after matching
    pub amount: u64,                   // Energy quantity (Wh)
    pub filled_amount: u64,            // Partially filled tracking
    pub price_per_kwh: u64,            // Price in lamports/kWh
    pub order_type: u8,                // Buy | Sell
    pub status: u8,                    // Active | Filled | Cancelled
    pub created_at: i64,
    pub expires_at: i64,
}
```

**REC Validation:**
```rust
// Checks if seller has a valid Renewable Energy Certificate
require!(erc_certificate.status == ErcStatus::Valid);
require!(energy_amount <= erc_certificate.energy_amount);
require!(erc_certificate.validated_for_trading);
```

#### `create_buy_order`
*   Creates a buy order for energy deficit.
*   Locks buyer's USDC/SOL in escrow.

#### `match_orders`
*   Atomically matches a buy and sell order.
*   **Price Agreement**: Executes at the sell price if `buy_price >= sell_price`.
*   **Transfers**:
    1.  Energy tokens: Seller → Buyer.
    2.  Payment (USDC/SOL): Buyer → Seller (minus market fee).

**Atomic Settlement Flow:**
```rust
// 1. Transfer energy tokens (GRID)
token_interface::transfer_checked(
    energy_transfer_ctx,
    energy_amount,
    energy_decimals,
)?;

// 2. Transfer payment (USDC)
token_interface::transfer_checked(
    payment_transfer_ctx,
    total_price,
    usdc_decimals,
)?;

// 3. Update order states
sell_order.status = OrderStatus::Filled;
buy_order.status = OrderStatus::Filled;

// 4. Update market stats
market.total_volume += energy_amount;
market.total_trades += 1;
```

#### `cancel_order`
*   Cancels an active order.
*   Unlocks escrowed funds/tokens.
*   Only callable by order creator.

### 4.3 Advanced Features

#### Batch Clearing (Market-Based Matching)
*   Aggregates orders within a time window (default: 5 minutes).
*   Calculates market-clearing price using supply/demand curves.
*   Executes multiple matches in a single transaction.

**Configuration:**
```rust
pub struct BatchConfig {
    pub enabled: u8,
    pub max_batch_size: u16,           // Max orders per batch (100)
    pub batch_timeout_seconds: u32,    // Batch window (300s)
    pub min_batch_size: u16,           // Min for clearing (5)
    pub price_improvement_threshold: u8, // Min improvement (5%)
}
```

#### Dynamic Pricing
*   **Time-of-Use Pricing**: Adjusts prices based on grid load.
*   **VWAP Tracking**: Maintains 24-hour price history for transparency.

#### Carbon Credit Integration
*   Orders can be tagged with carbon offset data.
*   Integrates with `carbon.rs` module for emissions tracking.

---

## 5. Energy Token Program (Asset Layer)

**Purpose**: Implements the GRID token using SPL Token-2022 standard.

### 5.1 Token Specification

*   **Standard**: SPL Token-2022 (Token Extensions Program).
*   **Decimals**: 9 (matches Solana's native SOL).
*   **Supply**: Uncapped (minted based on verified energy generation).
*   **Metadata**: Integrated with Metaplex Token Metadata for discoverability.

### 5.2 Core Instructions

#### `create_token_mint`
*   Initializes the GRID token mint.
*   Creates Metaplex metadata (name, symbol, URI).

**Metadata:**
```json
{
  "name": "GridTokenX Energy Credit",
  "symbol": "GRID",
  "decimals": 9,
  "uri": "https://gridtokenx.com/metadata/grid.json"
}
```

#### `mint_to_wallet`
*   Mints GRID tokens to a user's wallet.
*   Only callable by token authority (program or admin).

#### `mint_tokens_direct`
*   **CPI Endpoint**: Called by Registry Program during settlement.
*   Mints tokens based on unsettled meter balance.

**Minting Logic:**
```rust
let tokens_to_mint = meter.total_generation
    - meter.total_consumption
    - meter.settled_net_generation;

token_interface::mint_to(
    mint_ctx,
    tokens_to_mint,
)?;
```

#### `burn_tokens`
*   Burns GRID tokens (e.g., when energy is consumed from the grid).
*   Reduces circulating supply.

---

## 6. Oracle Program (Data Integrity Layer)

**Purpose**: Validates meter readings before updating on-chain state.

### 6.1 Oracle Authority

*   **API Gateway** is designated as the trusted oracle.
*   Only the API Gateway can call `submit_meter_reading`.

### 6.2 Validation Rules

#### `submit_meter_reading`
*   **Monotonic Increase**: Readings must be strictly increasing.
*   **Timestamp Validation**: No future readings; must be newer than last.
*   **Rate Limiting**: Minimum interval between readings (default: 60s).
*   **Anomaly Detection**: Rejects readings exceeding deviation thresholds.

**Validation Flow:**
```rust
// 1. Check oracle is active
require!(oracle_data.active == 1);

// 2. Verify caller is authorized
require!(authority.key() == oracle_data.api_gateway);

// 3. Check timestamp ordering
require!(reading_timestamp > oracle_data.last_reading_timestamp);
require!(reading_timestamp <= current_time + 60); // No future readings

// 4. Rate limiting
let time_since_last = reading_timestamp - oracle_data.last_reading_timestamp;
require!(time_since_last >= oracle_data.min_reading_interval);

// 5. Anomaly detection
if oracle_data.anomaly_detection_enabled == 1 {
    validate_meter_reading(energy_produced, energy_consumed, oracle_data)?;
}
```

### 6.3 Quality Metrics

*   **Acceptance Rate**: `total_valid_readings / total_readings`.
*   **Quality Score**: Updated based on reading consistency.
*   **Average Interval**: Tracks typical reading frequency.

---

## 7. Governance Program (Certification Layer)

**Purpose**: Issues and manages Renewable Energy Certificates (RECs).

### 7.1 REC Lifecycle

#### `issue_erc`
*   Creates an REC for verified renewable energy generation.
*   **Input**: Meter ID, energy amount, generation period.
*   **Validation**: Cross-references with Registry meter data.

**REC Structure:**
```rust
pub struct ErcCertificate {
    pub certificate_id: [u8; 32],
    pub meter_id: [u8; 32],
    pub owner: Pubkey,
    pub energy_amount: u64,          // Wh of certified renewable energy
    pub generation_start: i64,
    pub generation_end: i64,
    pub status: ErcStatus,           // Valid | Retired | Revoked
    pub expires_at: Option<i64>,
    pub validated_for_trading: bool, // Approved for marketplace
    pub issued_at: i64,
}
```

#### `validate_erc_for_trading`
*   Approves an REC for use in the trading marketplace.
*   Only callable by governance authority.

#### `retire_erc`
*   Permanently retires an REC after consumption.
*   Prevents double-claiming of renewable credits.

---

## 8. Security Model

### 8.1 Access Control

*   **Program Authority**: Set at initialization; can update configuration.
*   **Oracle Authority**: Only API Gateway can submit readings.
*   **User Ownership**: PDAs ensure only wallet owners can modify their accounts.

### 8.2 Reentrancy Protection

*   **Solana Architecture**: No reentrancy risk (single-threaded execution per account).
*   **CPI Safety**: Cross-program calls use signer checks.

### 8.3 Validation Layers

| Layer | Validation | Location |
|-------|-----------|----------|
| **Client** | Input sanitization | Next.js frontend |
| **API Gateway** | Business logic, rate limiting | Rust backend |
| **Oracle** | Timestamp, anomaly detection | Oracle program |
| **Registry** | Ownership, state consistency | Registry program |
| **Trading** | Price bounds, REC validity | Trading program |

### 8.4 Upgrade Authority

*   Programs deployed with **upgrade authority** retained by multi-sig.
*   **Future**: Transition to DAO-controlled upgrades via governance token.

---

## 9. Performance Characteristics

### 9.1 Benchmark Results (LiteSVM)

| Metric | Value | Context |
|--------|-------|---------|
| **Peak Throughput** | 530.2 TPS | Sequential order creation |
| **Real-World TPS** | 206.9 TPS | Flash sale (100 concurrent users) |
| **Average Latency** | 1.96 ms | Warm cache |
| **p99 Latency** | 3.87 ms | 99th percentile |

### 9.2 Compute Units (CU) Budget

| Instruction | CU Usage | Optimization |
|-------------|----------|--------------|
| `register_user` | ~5,000 CU | Zero-copy init |
| `register_meter` | ~8,000 CU | PDA caching |
| `update_meter_reading` | ~12,000 CU | Minimal logging |
| `create_sell_order` | ~18,000 CU | REC validation |
| `match_orders` | ~35,000 CU | Dual token transfer |

**Optimization Techniques:**
*   **Zero-Copy Deserialization**: Using `AccountLoader<>` instead of `Account<>`.
*   **Conditional Logging**: Disabled in production to save CU.
*   **Batch Operations**: Single transaction for settlement + minting.

---

## 10. Testing Strategy

### 10.1 Unit Tests (Anchor Test Suite)

*   **Coverage**: All instructions with success/failure cases.
*   **Mock Data**: Simulated meter readings and orders.
*   **Execution**: `anchor test --skip-build`

### 10.2 Integration Tests (LiteSVM)

*   **In-Process VM**: Tests run against local Solana VM.
*   **Performance Profiling**: Measures CU consumption and latency.

### 10.3 BLOCKBENCH Suite

*   **YCSB Workloads**: Tests read/write patterns.
*   **Smallbank**: OLTP transaction simulation.
*   **TPC-C**: Order processing benchmark.

---

## 11. Future Enhancements

1.  **zkSNARKs Integration**: Privacy-preserving energy trades (see `confidential.rs`).
2.  **Wormhole Bridge**: Cross-chain energy trading with Ethereum (see `wormhole.rs`).
3.  **AMM Module**: Automated market maker for liquidity (see `amm.rs`).
4.  **Auction Mechanism**: Dutch auction for peak demand periods (see `auction.rs`).
5.  **Governance Token**: Decentralized program upgrades via token voting.

---

## 12. Code Repository Structure

```
gridtokenx-anchor/
├── programs/
│   ├── registry/        # Identity & meter management
│   ├── trading/         # Order book & matching
│   ├── energy-token/    # GRID token implementation
│   ├── oracle/          # Reading validation
│   ├── governance/      # REC issuance
│   └── blockbench/      # Performance benchmarks
├── tests/
│   ├── registry.test.ts
│   ├── trading.test.ts
│   ├── performance/     # Load testing
│   └── utils/           # Test helpers
├── sdk/                 # TypeScript client library
└── docs/
    └── academic/        # Performance white papers
```

---

## 13. Deployment Checklist

- [ ] Initialize Registry program
- [ ] Set oracle authority (API Gateway pubkey)
- [ ] Create GRID token mint
- [ ] Initialize Market account
- [ ] Deploy REC governance
- [ ] Configure batch clearing parameters
- [ ] Set market fee (0.25%)
- [ ] Verify upgrade authority (multi-sig)
- [ ] Deploy frontend with program IDs
- [ ] Monitor initial transactions (health checks)
