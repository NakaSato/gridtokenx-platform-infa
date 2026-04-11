# Token Economics

## GridTokenX Token Economics Analysis

> *April 2026 Edition - Production Token Model*  
> **Version:** 3.0.0

---

> **Related Documentation:**  
> - [Business Model](./02-business-model.md) - Revenue model and pricing  
> - [System Architecture](./03-system-architecture.md) - Technical architecture  
> - [Process Flows](./06-process-flows.md) - Token minting and settlement flows  

---

## 1. Token Overview

### 1.1 Dual Token Model

GridTokenX employs a dual token architecture separating energy representation from platform governance:

```
┌────────────────────────────────────────────────────────────────────┐
│                    DUAL TOKEN ARCHITECTURE                          │
└────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐     ┌──────────────────────────┐
│   GRID (Energy Token)    │     │   GRX (Governance Token) │
│                          │     │                          │
│ Purpose: Energy credit   │     │ Purpose: Platform        │
│ Representation           │     │ Governance & Utility     │
│                          │     │                          │
│ Standard: SPL Token-2022 │     │ Standard: SPL Token-2022 │
│ Supply: Elastic (mint/   │     │ Supply: Fixed 1 billion  │
│ burn based on energy)    │     │ Initial allocation       │
│                          │     │                          │
│ Backing: 1 GRID = 1 kWh  │     │ Utility:                 │
│ verified renewable energy│     │ • Fee payment & discounts│
│                          │     │ • DAO voting rights      │
│ Functions:               │     │ • Staking for rewards    │
│ • Mint from production   │     │ • Premium feature access │
│ • Transfer in trades     │     │ • Treasury management    │
│ • Burn on consumption    │     │                          │
│ • Escrow for orders      │     │ Distribution:            │
│                          │     │ • 40% Community rewards  │
│                          │     │ • 25% Team & advisors    │
│                          │     │ • 20% Treasury reserve   │
│                          │     │ • 10% Liquidity pools    │
│                          │     │ • 5%  Early backers      │
└──────────────────────────┘     └──────────────────────────┘
```

### 1.2 GRID Token Specification

| Property | Value | Rationale |
|----------|-------|-----------|
| **Token Name** | GridTokenX Energy Token | Platform identity |
| **Symbol** | GRID | Distinct from GRX governance |
| **Standard** | SPL Token-2022 | Extended features (transfer hooks, metadata) |
| **Program ID** | `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` (Energy Token Program) | On-chain authority |
| **Decimals** | 9 | Precise energy measurement (Wh level) |
| **Supply Type** | Elastic | Mint/burn based on verified energy |
| **Mint Authority** | PDA `["token_info_2022"]` | Program-controlled, no single key |
| **Freeze Authority** | None | Freely transferable |
| **Backing** | 1 GRID = 1 kWh verified renewable energy | Oracle-validated meter readings |

### 1.3 GRX Token Specification

| Property | Value | Rationale |
|----------|-------|-----------|
| **Token Name** | GridTokenX Governance Token | Platform identity |
| **Symbol** | GRX | Distinct from GRID energy |
| **Standard** | SPL Token-2022 | Extended features |
| **Total Supply** | 1,000,000,000 GRX (1 billion) | Fixed, no inflation |
| **Decimals** | 9 | Standard SPL precision |
| **Transferable** | Yes | Free market trading |
| **Utility** | Governance voting, fee discounts, staking | Platform participation |

---

## 2. Token Supply Model

### 2.1 GRID Elastic Supply Mechanism

The GRID token supply is elastic, expanding and contracting based on verified renewable energy production:

```
┌────────────────────────────────────────────────────────────────────┐
│                   ELASTIC SUPPLY MECHANISM                          │
└────────────────────────────────────────────────────────────────────┘

Energy Production (Physical)              Token Supply (Digital)
──────────────────────────                ────────────────────────

┌──────────────────┐                     ┌──────────────────┐
│ Smart Meter      │                     │                  │
│ ▼                │   MINT (1:1 kWh)    │   GRID Supply    │
│ ▼ Production     │ ──────────────────► │   ↑ Increases    │
│ ▼                │                     │                  │
└──────────────────┘                     └──────────────────┘

┌──────────────────┐                     ┌──────────────────┐
│ Energy Consumer  │                     │                  │
│ ▼                │   BURN (optional)   │   GRID Supply    │
│ ▼ Consumption    │ ──────────────────► │   ↓ Decreases    │
│ ▼                │                     │                  │
└──────────────────┘                     └──────────────────┘


Supply Equation:
─────────────────────────────────────────────────────────────────
S(t) = Σ(Minted_i) - Σ(Burned_j)

Where:
• S(t) = Total supply at time t
• Minted_i = Energy production verified for meter i
• Burned_j = Energy consumption retired for user j
```

### 2.2 Supply Growth Projection

Based on conservative adoption assumptions:

| Quarter | Prosumers | Monthly Mint (GRID) | Cumulative Supply | Notes |
|---------|-----------|---------------------|-------------------|-------|
| Y1 Q1 | 100 | 50,000 | 150,000 | Bangkok pilot launch |
| Y1 Q2 | 125 | 62,500 | 337,500 | 25% growth |
| Y1 Q3 | 156 | 78,000 | 571,500 | Solar seasonality (+10%) |
| Y1 Q4 | 195 | 97,500 | 864,000 | Word-of-mouth adoption |
| Y2 Q1 | 244 | 122,000 | 1,230,000 | Provincial expansion |
| Y2 Q2 | 305 | 152,500 | 1,687,500 | Platform maturity |

**Assumptions:**
- Starting prosumers: 100 (Bangkok pilot)
- Growth rate: 25% per quarter (conservative)
- Average surplus: 500 kWh/prosumer/month
- Seasonal variation: ±20% (Thailand solar conditions)
- Minting capacity: 6,665 GRID/sec (platform well above demand)

**Technical Validation:**
- Peak minting demand (Y2 Q2): 152,500 GRID/month = 0.059 GRID/sec
- Platform capacity: 6,665 GRID/sec theoretical
- **Headroom: 112,000x current demand**
- Bottleneck: Oracle submissions (15,000/sec theoretical, 8,000/sec sustained)

---

## 3. Token Flow Model

### 3.1 Complete Token Lifecycle

```
┌────────────────────────────────────────────────────────────────────┐
│                    COMPLETE TOKEN LIFECYCLE                         │
└────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────┐
                    │   ENERGY TOKEN      │
                    │   PROGRAM           │
                    │   (Mint/Burn)       │
                    └──────────┬──────────┘
                               │
                  ┌────────────┴────────────┐
                  │                         │
               MINT                       BURN
                  │                         │
                  ▼                         │
        ┌───────────────────┐              │
        │                   │              │
        │  PROSUMER WALLET  │              │
        │  (Token Holder)   │              │
        │                   │              │
        └────────┬──────────┘              │
                 │                         │
          ┌──────┼──────┐                 │
          │      │      │                 │
       HOLD   SELL  TRANSFER             │
          │      │      │                 │
          │      ▼      │                 │
          │ ┌─────────────┐              │
          │ │             │              │
          │ │ ESCROW      │              │
          │ │ (Order)     │              │
          │ │             │              │
          │ └──────┬──────┘              │
          │        │                     │
          │ ┌──────┴──────┐             │
          │ │             │             │
          │ MATCH      CANCEL           │
          │ │             │             │
          │ ▼             │             │
          │ ┌───────┐     │             │
          │ │       │     │             │
          │ │ BUYER │◄────┘             │
          │ │WALLET│                    │
          │ │      │                    │
          │ └──┬───┘                    │
          │    │                        │
          │    └───────────┬────────────┘
          │                │
          │                │ (Optional: Retire on Consumption)
          │                ▼
          │          ┌───────────┐
          │          │           │
          │          │   BURN    │
          │          │           │
          │          └───────────┘
          │
          └───────────────── To ERC Certificate
                            (Renewable energy proof)
```

### 3.2 Token Movement Summary

| Step | Action | From | To | CU Cost | Latency |
|------|--------|------|----|---------|---------|
| 1 | Oracle validates reading | — | Oracle Program | 8,000 CU | ~100ms |
| 2 | Registry calculates net generation | — | Registry Program | 3,500 CU | ~50ms |
| 3 | **Mint** (Registry → Energy Token CPI) | PDA authority | Prosumer wallet | 18,000 CU | ~250ms |
| 4 | **Escrow** (Order creation) | Prosumer wallet | Escrow PDA | 7,500 CU | ~150ms |
| 5 | **Match** orders | — | Trading Program | 15,000 CU | ~200ms |
| 6 | **Settlement** (Trading → Token transfer) | Escrow PDA | Buyer wallet | 15,200 CU | ~200ms |
| 7 | **ERC Issuance** (Governance verifies unclaimed) | Registry check | Governance Program | 11,200 CU w/ CPI | ~180ms |
| 8 | **Burn** (Optional retirement) | Holder wallet | Void | 14,000 CU | ~180ms |
| 9 | **Transfer** (Peer-to-peer) | Wallet | Wallet | 15,200 CU | ~150ms |

---

## 4. Price Discovery Mechanism

### 4.1 Continuous Double Auction (CDA) Order Book

GridTokenX uses a price-time priority order book for transparent price discovery:

```
┌────────────────────────────────────────────────────────────────────┐
│                 CDA ORDER BOOK MECHANICS                            │
└────────────────────────────────────────────────────────────────────┘

         SELL ORDERS (ASK)                     BUY ORDERS (BID)
         ─────────────────                     ────────────────

    Price (GRID/kWh)  │ Amount (kWh)     Price (GRID/kWh)  │ Amount (kWh)
    ──────────────────┼────────────      ──────────────────┼────────────
         3.50         │  100                  3.10         │  150
         3.40         │  250                  3.00         │  200   ◄ Best Bid
         3.30         │  180                  2.90         │  300
         3.20         │  500   ◄ Best Ask     2.80         │  100
                                              2.70         │  250


         SPREAD = Best Ask - Best Bid = 3.20 - 3.10 = 0.10 GRID/kWh
         MID PRICE = (Best Ask + Best Bid) / 2 = 3.15 GRID/kWh


Matching Rule:
─────────────────────────────────────────────────────────────────
If Best Bid ≥ Best Ask → Execute trade at (Best Bid + Best Ask) / 2

Example:
Bid 3.00 + Ask 2.80 → Match at (3.00 + 2.80) / 2 = 2.90 GRID/kWh
```

### 4.2 Price Equilibrium Model

```
┌────────────────────────────────────────────────────────────────────┐
│                    PRICE EQUILIBRIUM                                │
└────────────────────────────────────────────────────────────────────┘

    Price
    (GRID/kWh)
         │
      5  │
         │               Supply Curve
      4  │              /
         │             /
    3.15 │───────────●──────────────────  Equilibrium (P*)
         │          /│
      3  │         / │
         │        /  │  Demand Curve
      2  │       /   │ ╲
         │      /    │  ╲
      1  │     /     │   ╲
         │    /      │    ╲
         │───/───────┼────────────────────
                   Q*                      Quantity
                (Volume)                   (kWh)


Equilibrium Conditions:
─────────────────────────────────────────────────────────────────
At price P* = 3.15 GRID/kWh:
• Quantity supplied = Quantity demanded = Q*
• No excess supply or demand
• Market clears naturally

Price Ceiling (Too High):
• More sellers than buyers → Surplus tokens → Price drops

Price Floor (Too Low):
• More buyers than sellers → Token shortage → Price rises
```

### 4.3 Price Factors

| Factor Type | Factors | Impact on Price |
|-------------|---------|-----------------|
| **Supply** | Solar production, weather, # prosumers, equipment uptime | ↑ Supply → ↓ Price |
| **Demand** | Consumer demand, time of day, ESG awareness, grid prices | ↑ Demand → ↑ Price |
| **External** | Grid electricity prices, government policy, market sentiment | Correlation |

---

## 5. Incentive Mechanisms

### 5.1 Stakeholder Incentive Matrix

```
┌────────────────────────────────────────────────────────────────────┐
│                   STAKEHOLDER INCENTIVES                            │
└────────────────────────────────────────────────────────────────────┘

PROSUMER INCENTIVES                          CONSUMER INCENTIVES
───────────────────                          ───────────────────

Revenue from surplus energy sales            Lower energy costs vs. grid (20-40%)
     │                                            │
     ▼                                            ▼
┌─────────────────────────┐            ┌─────────────────────────┐
│ Formula:                 │            │ Formula:                 │
│ Revenue = (Surplus ×     │            │ Savings = (Grid Price    │
│   Market Price) - Fees   │            │   - Platform Price) × kWh│
│                          │            │                          │
│ Example (100 kWh):       │            │ Example (100 kWh):       │
│ Surplus: 100 kWh         │            │ Grid: 4.0 THB/kWh       │
│ Price: 3.0 GRID/kWh     │            │ Platform: 3.0 GRID/kWh  │
│ Value: 300 GRID          │            │ Savings: 0.5 THB/kWh    │
│ Fee: 0.75 GRID (0.25%)  │            │ Total: 50 THB saved     │
│ Net: 299.25 GRID         │            │                          │
└─────────────────────────┘            └─────────────────────────┘

ERC CERTIFICATE PREMIUM                    STAKING DISCOUNTS
─────────────────────────                  ──────────────────

Premium pricing for verified green energy  Lock GRX for fee discounts
     │                                            │
     ▼                                            ▼
┌─────────────────────────┐            ┌─────────────────────────┐
│ Standard: 3.0 GRID/kWh  │            │ 100 GRX → 10% discount  │
│ With ERC: 3.5 GRID/kWh  │            │ 500 GRX → 25% discount  │
│ Premium: +16% revenue   │            │ 1000 GRX → 50% discount │
│                          │            │ Lock: 30-180 days       │
│ ERC Cost: 5+2 GRID      │            │ Early unlock: 10% penalty│
└─────────────────────────┘            └─────────────────────────┘
```

### 5.2 Prosumer Revenue Analysis

**Standard Trade (No ERC):**

| Component | Value |
|-----------|-------|
| Surplus energy | 100 kWh |
| Market price | 3.0 GRID/kWh |
| Gross revenue | 300 GRID |
| Platform fee (0.25%) | -0.75 GRID |
| **Net revenue** | **299.25 GRID** |

**With ERC Certificate (Premium):**

| Component | Value |
|-----------|-------|
| Surplus energy | 100 kWh |
| Premium price | 3.5 GRID/kWh (+17%) |
| Gross revenue | 350 GRID |
| Platform fee (0.25%) | -0.875 GRID |
| ERC validation fee | -2 GRID |
| **Net revenue** | **347.125 GRID (+16%)** |

---

## 6. Token Velocity & Quantity Theory

### 6.1 Token Velocity Analysis

Token velocity measures how frequently each GRID token changes hands:

```
┌────────────────────────────────────────────────────────────────────┐
│                    TOKEN VELOCITY MODEL                             │
└────────────────────────────────────────────────────────────────────┘

Velocity Equation:
─────────────────────────────────────────────────────────────────
V = GDP / M

Where:
• V = Token velocity (turnovers per period)
• GDP = Total trading volume (GRID/period)
• M = Average circulating supply (GRID)

Example Calculation:
─────────────────────────────────────────────────────────────────
Monthly trading volume: 10,000 GRID
Average supply: 5,000 GRID
Velocity: V = 10,000 / 5,000 = 2.0 turnovers/month

Implications:
─────────────────────────────────────────────────────────────────
Low Velocity (V < 1):
• Tokens held long-term
• Price stability
• Lower liquidity

Optimal Velocity (V = 2-4):
• Active trading market
• Healthy price discovery
• Good liquidity

High Velocity (V > 5):
• Speculative trading
• Price volatility
• Reduced utility as energy credit
```

### 6.2 Quantity Theory of Money Application

The relationship between token supply and price level:

```
Equation of Exchange:
─────────────────────────────────────────────────────────────────
M × V = P × Q

Where:
• M = Money supply (GRID tokens)
• V = Velocity of money
• P = Price level (GRID/kWh)
• Q = Real output (kWh traded)

Rearranged for Price:
─────────────────────────────────────────────────────────────────
P = (M × V) / Q

Example:
M = 10,000 GRID (supply)
V = 2.0 (turnovers/month)
Q = 5,000 kWh (traded)
P = (10,000 × 2.0) / 5,000 = 4.0 GRID/kWh

Implications:
• If supply doubles (M → 2M) with constant V and Q → Price halves
• If velocity increases (trading activity) → Price increases
• If energy production grows (Q ↑) → Price decreases (deflationary)
```

---

## 7. Staking Economics

### 7.1 Staking Mechanism

Users can stake GRX tokens to receive platform fee discounts:

| Stake Amount | Fee Discount | Lock Period | APY Equivalent |
|--------------|--------------|-------------|----------------|
| 100 GRX | 10% | 30 days | ~12% |
| 500 GRX | 25% | 90 days | ~15% |
| 1,000 GRX | 50% | 180 days | ~20% |

**APY Calculation:**

```
APY = (Fee Savings × 365) / (Stake × Lock Days)

Example (500 GRX stake, 25% discount):
• Average monthly fees: 10 GRX
• Monthly savings: 10 × 0.25 = 2.5 GRX
• Lock period: 90 days
• APY = (2.5 × 12) / 500 = 6.0%

Note: Actual APY varies by trading volume and fee generation
```

### 7.2 Staking Incentives

**Benefits of Staking:**
- Reduced trading fees (10-50% discount)
- Governance voting power (proportional to stake)
- Priority access to premium features
- Revenue share from platform fees (future)

**Risks of Staking:**
- Lock-up period (cannot trade staked tokens)
- Early unlock penalty (10% of stake)
- Opportunity cost (tokens not earning elsewhere)

---

## 8. Cross-Chain Payment Flow

### 8.1 Thai Baht Chain Integration

GridTokenX supports cross-chain payments via Thai Baht Chain (THBC):

```
┌────────────────────────────────────────────────────────────────────┐
│                CROSS-CHAIN PAYMENT FLOW                             │
└────────────────────────────────────────────────────────────────────┘

    Consumer         Thai Baht           Bridge           Trading
       │               Chain             Service          Program
       │                 │                  │                │
       │  (1) Send THB   │                  │                │
       │ ───────────────►│                  │                │
       │                 │                  │                │
       │                 │  (2) Lock THB    │                │
       │                 │ ────────────────►│                │
       │                 │                  │                │
       │                 │                  │  (3) Proof     │
       │                 │                  │ ───────────────►
       │                 │                  │                │
       │                 │                  │                │  (4) Execute
       │   ◄─────────────│──────────────────│────────────────│   Trade
       │   GRID Tokens   │                  │                │
       │                 │                  │                │
       │                 │                  │  (5) Convert   │
       │                 │  (6) Release GRX │  THB → GRID    │
       │                 │ ◄────────────────│ ◄──────────────│
       │                 │                  │                │
       │                 │  (7) Credit GRID │                │
       │                 │ ─────────────────│────────────────│──► Prosumer
       │                 │                  │                │
```

### 8.2 Cross-Chain Security

| Security Measure | Implementation | Purpose |
|-----------------|----------------|---------|
| Multi-sig bridge | 5-of-7 validator consensus | Prevent single point of failure |
| Hash time-lock | HTLC pattern | Atomic cross-chain swap |
| Collateralization | Bridge holds 110% reserve | Over-collateralized backing |
| Timeout refund | 24-hour expiry | Refund if trade fails |

---

## 9. Economic Attack Vectors

### 9.1 Threat Analysis

| Attack Type | Description | Prevention | Status |
|-------------|-------------|------------|--------|
| **Double-Spending** | Spend same tokens twice | Escrow pattern, atomic transfers | ✅ Mitigated |
| **Double-Minting** | Mint tokens for same energy twice | Dual high-water marks | ✅ Mitigated |
| **Wash Trading** | Trade with own accounts | Self-trade check, KYC | ✅ Mitigated |
| **Price Manipulation** | Artificial price inflation | CDA order book, market depth | ⚠️ Monitoring |
| **Sybil Attack** | Create fake accounts | KYC verification, stake requirement | ✅ Mitigated |
| **Oracle Manipulation** | Submit fake meter readings | BFT consensus (3f+1), Ed25519 | ✅ Mitigated |

### 9.2 Dual High-Water Mark Prevention

```
┌────────────────────────────────────────────────────────────────────┐
│              DUAL HIGH-WATER MARK MECHANISM                         │
└────────────────────────────────────────────────────────────────────┘

MeterAccount State:
─────────────────────────────────────────────────────────────────
{
  total_production: u64,           // Cumulative energy produced
  total_consumption: u64,          // Cumulative energy consumed
  settled_net_generation: u64,     // Already minted (GRID tokens)
  claimed_erc_generation: u64,     // Already claimed (ERC certificates)
}

Minting Formula:
─────────────────────────────────────────────────────────────────
new_mint = (total_production - total_consumption) - settled_net_generation

If new_mint ≤ 0 → No tokens minted (nothing new to claim)
After mint: settled_net_generation += new_mint

ERC Claim Formula:
─────────────────────────────────────────────────────────────────
available_for_erc = (total_production - total_consumption) - claimed_erc_generation

If available_for_erc ≤ 0 → No ERC certificates can be issued
After claim: claimed_erc_generation += energy_amount

Dual-Track Prevention:
─────────────────────────────────────────────────────────────────
• Energy cannot be minted as GRID AND claimed as ERC simultaneously
• Both high-water marks must be checked before issuance
• Maximum mintable = min(available_for_mint, available_for_erc)
```

---

## 10. Token Distribution

### 10.1 GRX Initial Allocation

| Recipient | Percentage | Amount (GRX) | Vesting |
|-----------|-----------|--------------|---------|
| Community rewards | 40% | 400,000,000 | 4 years linear |
| Team & advisors | 25% | 250,000,000 | 1 year cliff, 3 years linear |
| Treasury reserve | 20% | 200,000,000 | Governance controlled |
| Liquidity pools | 10% | 100,000,000 | Immediate |
| Early backers | 5% | 50,000,000 | 6 months cliff, 2 years linear |

### 10.2 Distribution Timeline

```
┌────────────────────────────────────────────────────────────────────┐
│                  GRX DISTRIBUTION TIMELINE                          │
└────────────────────────────────────────────────────────────────────┘

  100% │
       │
   80% │    ┌─────────────────────────────────────┐
       │    │  Community Rewards (40%)            │
   60% │    │  ┌─────────────────────────────┐   │
       │    │  │  Treasury (20%)             │   │
   40% │    │  │  ┌───────────────────┐     │   │
       │    │  │  │ Team (25%)        │     │   │
   20% │    │  │  │ ┌───────────┐    │     │   │
       │    │  │  │ │Liquidity  │    │     │   │
    0% │____│__│__│_│___________│____│_____│___│
       Launch  6m  1y  1.5y  2y  2.5y  3y  4y
```

---

**Document Information:**

| Field | Value |
|-------|-------|
| **Version** | 3.0.0 |
| **Last Updated** | April 2026 |
| **Status** | Production-Ready |
| **Authors** | GridTokenX Research Team |
