# Tokenomics and Pricing Model
## GridTokenX Platform

---

## 1. Overview

GridTokenX implements a dual-token economic model with **dynamic pricing mechanisms** to facilitate transparent, efficient, and fair P2P energy trading. The system balances supply and demand through algorithmic pricing while maintaining market stability.

**Core Economic Principles:**
*   **Energy-Backed Tokens**: GRID tokens represent verified energy generation (1 GRID = 1 Wh).
*   **Real-Time Price Discovery**: Market-clearing prices adjust to grid conditions.
*   **Incentive Alignment**: Rewards renewable generation and demand-side flexibility.
*   **Network Effects**: Platform value grows with participant count and transaction volume.

---

## 2. Token Architecture

### 2.1 GRID Token (Energy Credit)

**Token Standard**: SPL Token-2022 (Solana Token Extensions Program)

**Specification:**
```json
{
  "name": "GridTokenX Energy Credit",
  "symbol": "GRID",
  "decimals": 9,
  "supply_type": "Uncapped (elastic)",
  "backing": "Physical energy generation (Wh)"
}
```

**Key Characteristics:**
*   **Unit Parity**: 1 GRID = 1 Wh (Watt-hour) of verified energy.
*   **Elastic Supply**: Minted when energy is produced; burned when consumed.
*   **Zero-Mint Protection**: `settled_net_generation` tracker prevents double-minting.
*   **Fractionalization**: Supports 9 decimals for micro-transactions (0.000000001 GRID).

### 2.2 Token Lifecycle

#### Minting (Energy Production)
```
┌──────────────┐
│ Meter Reads  │ 5 kWh solar generation
│  5000 Wh     │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Oracle     │ Validates reading
│  Verifies    │ timestamp + authenticity
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Registry   │ Updates total_generation
│  Program     │ Calculates unsettled balance
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Energy Token │ Mints 5,000,000,000 GRID
│  Program     │ (5000 Wh × 10^9 decimals)
└──────────────┘
```

**Minting Constraints:**
*   Only callable via Registry Program (CPI).
*   Requires positive `unsettled_balance = total_generation - total_consumption - settled_net_generation`.
*   Rate-limited to prevent flash attacks (min 60s between readings).

#### Burning (Energy Consumption)
*   **Grid Purchases**: When users buy from the grid, equivalent GRID tokens are burned.
*   **P2P Settlement**: After matching orders, buyer's consumption updates trigger burns.
*   **Supply Deflation**: Net consumption reduces circulating supply.

**Example:**
```rust
// User consumes 3 kWh from grid
let burn_amount = 3_000_000_000_000; // 3000 Wh × 10^9
token_interface::burn(ctx, burn_amount)?;
```

### 2.3 Renewable Energy Certificates (RECs)

**Purpose**: Proof of renewable energy generation for compliance and carbon accounting.

**REC → GRID Relationship:**
*   **1 REC = 1000 Wh** of certified renewable energy.
*   RECs are **non-fungible** (unique certificate IDs).
*   GRID tokens can be minted **with or without** REC backing.
*   REC-backed GRID trades at a **premium** (5-15%) in the marketplace.

**REC Lifecycle:**
1.  **Issuance**: Governance Program validates meter data and issues REC.
2.  **Trading**: REC holder can create sell orders with `validated_for_trading = true`.
3.  **Retirement**: After energy consumption, REC is retired (prevents double-claiming).

---

## 3. Pricing Mechanisms

### 3.1 Multi-Factor Pricing Model

The platform employs a **composite pricing algorithm** that combines multiple inputs:

$$
P_{final} = P_{base} \times M_{TOU} \times M_{seasonal} + A_{SD} + A_{congestion}
$$

Where:
*   $P_{base}$ = Base price per kWh (e.g., 3.50 THB/kWh)
*   $M_{TOU}$ = Time-of-Use multiplier (0.7x - 2.0x)
*   $M_{seasonal}$ = Seasonal adjustment (0.9x - 1.2x)
*   $A_{SD}$ = Supply/Demand adjustment (±0.5 THB/kWh)
*   $A_{congestion}$ = Grid congestion premium (0 - 1.0 THB/kWh)

**Price Bounds:**
*   **Minimum Floor**: 2.00 THB/kWh (prevents predatory pricing).
*   **Maximum Ceiling**: 8.00 THB/kWh (protects consumers during scarcity).

### 3.2 Time-of-Use (TOU) Pricing

**Purpose**: Incentivize demand-side flexibility and load shifting.

#### Thailand-Specific TOU Tiers

| Period | Time Window | Multiplier | Typical Price | Rationale |
|--------|-------------|------------|---------------|-----------|
| **Off-Peak** | 22:00 - 06:00 | 0.7x | 2.45 THB/kWh | Low demand, encourage night charging |
| **Mid-Peak** | 06:00 - 09:00, 14:00 - 17:00 | 1.0x | 3.50 THB/kWh | Baseline demand |
| **On-Peak** | 09:00 - 14:00, 17:00 - 22:00 | 1.5x | 5.25 THB/kWh | High demand (AC, office hours) |
| **Super-Peak** | Critical Events | 2.0x | 7.00 THB/kWh | Grid emergency (rare) |

**Implementation:**
```rust
pub struct PriceTier {
    pub base_price: u64,        // Micro-units (6 decimals)
    pub multiplier: u16,        // 100 = 1.0x, 150 = 1.5x
    pub start_hour: u8,         // 0-23 (UTC+7 for Thailand)
    pub end_hour: u8,
    pub period: TimePeriod,     // OffPeak | MidPeak | OnPeak | SuperPeak
}
```

**User Impact:**
*   **Prosumers**: Sell surplus solar during on-peak hours for maximum revenue.
*   **Consumers**: Shift EV charging and laundry to off-peak for savings.

### 3.3 Seasonal Adjustments

**Purpose**: Account for climate-driven demand variations in Thailand.

| Season | Months | Multiplier | Driver |
|--------|--------|------------|--------|
| **Summer (Hot)** | Mar - May | 1.2x | High AC load, peak solar |
| **Rainy** | Jun - Oct | 1.0x | Moderate demand, reduced solar |
| **Cool** | Nov - Feb | 0.9x | Low AC load, pleasant weather |

**Algorithm:**
```rust
pub fn get_season(timestamp: i64, tz_offset: i16) -> Season {
    let local_time = adjust_to_local(timestamp, tz_offset);
    let month = get_month(local_time);
    
    match month {
        3..=5 => Season::Summer,    // Hot season
        6..=10 => Season::Rainy,    // Monsoon
        11 | 12 | 1 | 2 => Season::Cool, // Winter
        _ => Season::Summer,
    }
}
```

### 3.4 Supply-Demand Balancing

**Purpose**: Dynamically adjust prices to match real-time grid conditions.

**Formula:**
$$
A_{SD} = (D - S) \times \frac{S_{sensitivity}}{10000} \times P_{base}
$$

Where:
*   $D$ = Current demand (kWh)
*   $S$ = Current supply (kWh)
*   $S_{sensitivity}$ = Sensitivity parameter (default: 500 basis points = 5%)

**Examples:**

| Scenario | Supply (kWh) | Demand (kWh) | Net Imbalance | Adjustment |
|----------|--------------|--------------|---------------|------------|
| **Surplus** | 10,000 | 8,000 | -2,000 | -0.35 THB/kWh (price drops) |
| **Balanced** | 10,000 | 10,000 | 0 | 0 THB/kWh |
| **Deficit** | 8,000 | 10,000 | +2,000 | +0.35 THB/kWh (price rises) |

**Implementation:**
```rust
pub fn calculate_supply_demand_adjustment(config: &PricingConfig) -> i64 {
    let demand = config.current_demand as i64;
    let supply = config.current_supply as i64;
    let imbalance = demand - supply;
    
    let sensitivity = config.supply_demand_sensitivity as i64;
    let base_price = config.base_price as i64;
    
    // Adjustment = imbalance × (sensitivity / 10000) × base_price
    (imbalance * sensitivity * base_price) / (10000 * 1000)
}
```

### 3.5 Grid Congestion Pricing

**Purpose**: Manage network constraints and encourage local trading.

**Congestion Factor:**
*   **Normal (100)**: No congestion, 1.0x multiplier.
*   **Moderate (120)**: 10-20% line loading, 1.2x multiplier.
*   **High (150)**: 20-40% overload risk, 1.5x multiplier.
*   **Critical (200)**: Emergency conditions, 2.0x multiplier.

**Wheeling Charges (Zone-Based):**

| Trading Distance | Fee (THB/kWh) | Technical Loss |
|------------------|---------------|----------------|
| **Intra-Zone** (< 500m) | 0.50 | 1% |
| **Adjacent Zone** (< 2 km) | 1.00 | 2% |
| **Cross-Zone** (2-5 km) | 1.50 | 4% |
| **Remote Zone** (> 5 km) | 2.00 | 6% |

**Example:**
```python
# Simulator configuration
wheeling_intra_zone = 0.50      # THB/kWh
wheeling_adjacent_zone = 1.00
wheeling_cross_zone = 1.50
wheeling_remote_zone = 2.00

# Technical losses
loss_intra_zone = 0.01     # 1%
loss_adjacent_zone = 0.02  # 2%
loss_cross_zone = 0.04     # 4%
loss_remote_zone = 0.06    # 6%
```

---

## 4. Market Mechanisms

### 4.1 Order Book (Continuous Trading)

**Model**: Continuous double auction (similar to traditional exchanges).

**Order Types:**
1.  **Limit Order**: Specify exact price (e.g., "Sell 5 kWh at 4.20 THB/kWh").
2.  **Market Order** (future): Execute at best available price.

**Matching Logic:**
```rust
if buy_order.price_per_kwh >= sell_order.price_per_kwh {
    execute_trade(sell_order.price_per_kwh); // Execute at seller's price
}
```

**Execution Price**: Trades execute at the **seller's ask price** (maker price priority).

### 4.2 Batch Clearing (Market-Based Matching)

**Purpose**: Aggregate small orders and find market equilibrium price.

**Configuration:**
```rust
pub struct BatchConfig {
    pub enabled: bool,
    pub max_batch_size: u16,           // 100 orders per batch
    pub batch_timeout_seconds: u32,    // 300s (5 min window)
    pub min_batch_size: u16,           // 5 orders minimum
    pub price_improvement_threshold: u8, // 5% min improvement
}
```

**Clearing Algorithm:**
1.  **Aggregation**: Collect all orders within 5-minute window.
2.  **Supply Curve**: Sort sell orders by price (ascending).
3.  **Demand Curve**: Sort buy orders by price (descending).
4.  **Intersection**: Find price where supply = demand.
5.  **Execution**: Match all orders at clearing price.

**Visual:**
```
Price
  ↑
8 │                  ● Buy Orders (demand curve)
7 │              ●
6 │          ●
5 │      ●  ← Clearing Price = 5.00 THB/kWh
4 │  ●
3 │● Sell Orders (supply curve)
2 │
  └──────────────────────────→ Quantity (kWh)
    1  2  3  4  5  6  7  8
```

**Benefits:**
*   **Price Improvement**: Buyers may get better prices than limit orders.
*   **Reduced Spreads**: Single clearing price eliminates bid-ask gap.
*   **Gas Efficiency**: One transaction matches multiple orders.

### 4.3 Automated Market Maker (AMM)

**Purpose**: Provide instant liquidity for small trades without waiting for order matches.

**Model**: Bonding curve with energy-specific parameters.

**Curve Types:**
1.  **Linear Solar**: Moderate slope, suitable for stable solar generation.
2.  **Steep Wind**: High volatility, rapid price changes for wind energy.
3.  **Flat Battery**: Low slope, storage-backed for price stability.

**Pricing Formula (Linear):**
$$
P(q) = P_{base} + slope \times q
$$

Where:
*   $P_{base}$ = Starting price (e.g., 3.50 THB/kWh)
*   $slope$ = Price increment per kWh (e.g., 0.02 THB/kWh²)
*   $q$ = Quantity purchased/sold

**Example:**
```rust
// Buying 10 kWh from AMM
let base_price = 3_500_000; // 3.50 THB (micro-units)
let slope = 20_000;         // 0.02 THB/kWh
let quantity = 10_000;      // 10 kWh (milli-kWh)

// Total cost = base × qty + (slope × qty²) / 2
let total_cost = (base_price * quantity) + (slope * quantity * quantity) / (2 * 1000);
```

**AMM Parameters:**
```rust
pub struct AmmPool {
    pub energy_reserve: u64,    // GRID tokens in pool
    pub currency_reserve: u64,  // USDC/THB in pool
    pub bonding_slope: u64,     // Curve steepness
    pub bonding_base: u64,      // Base price
    pub fee_bps: u16,           // Pool fee (30 bps = 0.3%)
}
```

---

## 5. Fee Structure

### 5.1 Platform Fees

| Fee Type | Rate | Recipient | Purpose |
|----------|------|-----------|---------|
| **Trading Fee** | 0.25% | Platform | Order matching, infrastructure |
| **AMM Swap Fee** | 0.30% | Liquidity Providers | Compensate pool LPs |
| **REC Issuance** | 10 THB/cert | Governance | Certificate validation |
| **Wheeling Charge** | Variable | Grid Operator | Network usage |

**Example Trade:**
```
Sell Order: 100 kWh @ 4.00 THB/kWh
Buyer Pays: 400 THB
Platform Fee (0.25%): 1.00 THB
Wheeling Charge (Adjacent Zone): 100 THB
Seller Receives: 399 THB - 100 THB = 299 THB
Net Price: 2.99 THB/kWh (after fees)
```

### 5.2 Gas Fee Subsidy

**Challenge**: Blockchain transaction fees on Solana (~0.000005 SOL/tx ≈ 0.0001 THB).

**Solution**: Platform subsidizes gas fees for the first 100 transactions per user.

**Implementation:**
*   API Gateway pre-funds user wallets with 0.01 SOL.
*   Monthly fee cap: 100 THB/user for unlimited transactions.

---

## 6. Economic Incentives

### 6.1 Prosumer Rewards

**Goal**: Maximize renewable energy generation and grid contribution.

**Incentive Structure:**

| Milestone | Reward | Mechanism |
|-----------|--------|-----------|
| **First 1 MWh Generated** | 10% bonus GRID | Airdrop |
| **REC Certification** | 5-15% price premium | Market pricing |
| **Peak Hour Contribution** | 1.5x TOU multiplier | Dynamic pricing |
| **Local Trading** | Lower wheeling fees | Zone-based discount |

**Example:**
```
User generates 1000 kWh with REC:
- Base minting: 1,000,000,000,000 GRID
- First MWh bonus: +100,000,000,000 GRID (10%)
- Total received: 1,100,000,000,000 GRID

Sells during peak hours @ 5.25 THB/kWh:
- Revenue: 5,250 THB
- Trading fee: 13.13 THB (0.25%)
- Net: 5,236.87 THB
```

### 6.2 Demand Response

**Goal**: Incentivize load shifting to off-peak hours.

**Programs:**
1.  **Time-Based Pricing**: Automatic via TOU multipliers.
2.  **Peak Shaving Events**: Manual participation for 20% discounts.
3.  **Battery Arbitrage**: Buy low (off-peak), sell high (on-peak).

**Battery Arbitrage Example:**
```
Off-Peak Buy (22:00): 100 kWh @ 2.45 THB/kWh = 245 THB
Store in home battery (efficiency: 90%)
On-Peak Sell (12:00): 90 kWh @ 5.25 THB/kWh = 472.50 THB
Profit: 472.50 - 245 = 227.50 THB (93% ROI per cycle)
```

### 6.3 Liquidity Mining (Future)

**Concept**: Reward users who provide liquidity to AMM pools.

**Mechanism:**
*   Deposit GRID + USDC into AMM pool.
*   Receive LP tokens representing share of pool.
*   Earn 0.30% fee on all swaps proportional to LP stake.
*   Additional governance token rewards (future DAO launch).

---

## 7. Token Supply Dynamics

### 7.1 Supply Equation

$$
Supply_{GRID} = \sum_{meters} (Generation - Consumption - Settled)
$$

**Key Properties:**
*   **Elastic**: Supply grows/shrinks with net energy flow.
*   **Self-Correcting**: High surplus → token inflation → price drop → demand increase.
*   **Balanced**: Long-term equilibrium where generation ≈ consumption.

### 7.2 Supply Scenarios

| Scenario | Generation | Consumption | Net Supply | Price Impact |
|----------|------------|-------------|------------|--------------|
| **Solar Boom** | ↑↑ 150% | → 100% | +50% GRID | -20% price |
| **Peak Demand** | → 100% | ↑↑ 130% | -30% GRID | +30% price |
| **Balanced Grid** | → 100% | → 100% | 0% | Stable |

### 7.3 Circulating Supply Monitoring

**Metrics:**
*   **Total Minted**: Cumulative GRID tokens created.
*   **Total Burned**: Cumulative GRID tokens destroyed.
*   **Circulating Supply**: `Total Minted - Total Burned`.
*   **Velocity**: `Transaction Volume / Circulating Supply` (daily).

**Dashboard Display:**
```json
{
  "total_minted": "15,234,567,890,123 GRID",
  "total_burned": "12,456,789,012,345 GRID",
  "circulating_supply": "2,777,778,877,778 GRID",
  "daily_velocity": "1.3x",
  "market_cap_thb": "9,722,222 THB" // @ 3.50 THB/kWh
}
```

---

## 8. Risk Management

### 8.1 Price Stability Mechanisms

**Circuit Breakers:**
*   **Price Floor**: Minimum 2.00 THB/kWh prevents market crashes.
*   **Price Ceiling**: Maximum 8.00 THB/kWh protects consumers.
*   **Volatility Limits**: Max 20% price change per hour.

**Reserve Pool (Future):**
*   Platform maintains USDC reserve to buy GRID during crashes.
*   Sells GRID during scarcity to stabilize prices.

### 8.2 Oracle Validation

**Problem**: Prevent fake meter readings that could inflate token supply.

**Solutions:**
1.  **Rate Limiting**: Min 60s between readings.
2.  **Anomaly Detection**: Reject readings exceeding ±50% deviation.
3.  **Monotonic Increase**: Total generation must always increase.
4.  **Timestamp Validation**: No future readings allowed.

### 8.3 Smart Contract Safeguards

**Access Control:**
*   Only Registry Program can mint GRID tokens.
*   Only designated oracle (API Gateway) can submit readings.
*   Emergency pause function for critical bugs.

**Reentrancy Protection:**
*   Solana's single-threaded execution eliminates reentrancy risk.
*   All CPI calls use signer checks.

---

## 9. Economic Projections

### 9.1 Year 1 Targets

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Active Users** | 1,000 | Pilot deployment (UTCC campus) |
| **Daily Trading Volume** | 50 MWh | 50 kWh/user avg |
| **Average Price** | 3.80 THB/kWh | Competitive with grid tariff |
| **Platform Revenue** | 18,250 THB/month | 50,000 kWh × 3.80 THB × 0.0025 fee × 30 days |

### 9.2 Token Velocity Model

**Assumption**: Average GRID token held for 3 days before trading.

$$
Velocity = \frac{365}{3} = 121.67x \text{ per year}
$$

**Required Circulating Supply:**
$$
Supply = \frac{Daily\ Volume}{Velocity} = \frac{50,000\ kWh}{121.67 / 365} = 150,000\ kWh
$$

---

## 10. Comparison with Traditional Markets

| Feature | GridTokenX | Traditional Utility | Difference |
|---------|------------|---------------------|------------|
| **Pricing** | Real-time, dynamic | Fixed tariff | +25% price variance |
| **Settlement** | Instant (Solana) | Monthly billing | 30-day faster |
| **Transparency** | Full on-chain audit | Opaque black box | 100% verifiable |
| **Access** | P2P direct trade | Utility monopoly | Democratized |
| **Fees** | 0.25% trading fee | 10-15% distribution markup | 97.5% savings |

---

## 11. Future Enhancements

1.  **Futures Contracts**: Hedge against future price volatility.
2.  **Options Trading**: Call/put options for energy credits.
3.  **Carbon Credit Integration**: Bundle GRID + carbon offsets.
4.  **Cross-Chain Bridge**: Trade energy tokens on Ethereum/Polygon.
5.  **DAO Governance**: Community-controlled pricing parameter updates.

---

## 12. Conclusion

GridTokenX's tokenomics model creates a **self-sustaining energy economy** where:
*   Prices reflect real-time supply and demand.
*   Prosumers are financially rewarded for renewable generation.
*   Consumers benefit from competitive prices and transparency.
*   The platform captures value through minimal fees while maximizing participant welfare.

By aligning economic incentives with grid sustainability, GridTokenX accelerates the transition to decentralized renewable energy systems.
