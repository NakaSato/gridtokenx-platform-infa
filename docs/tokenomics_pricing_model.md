# Tokenomics and Pricing Model
## GridTokenX Platform

---

## 1. Executive Summary

The **GridTokenX Tokenomics Model** is designed to incentivize the generation of renewable energy while ensuring fair and efficient market clearing. It employs a **dual-token system** (Energy Token + Stablecoin) and dynamic pricing mechanisms to balance grid supply and demand.

**Core Philosophy**: Energy is a tangible asset; the token model must reflect physical reality (generation/consumption) rather than speculative value.

---

## 2. Token Definitions

### 2.1 GRID Token (Energy Asset)
*   **Type**: SPL Token-2022 (Solana).
*   **Role**: Represents verified energy verification (1 GRID = 1 kWh).
*   **Minting**: Algorithmic minting upon Oracle verification of smart meter surplus.
*   **Burning**: Burned/Settled when consumed or traded for stablecoins.
*   **Supply**: Elastic; expands with solar generation, contracts with consumption.

### 2.2 Payment Token (USDC/SOL)
*   **Type**: SPL Token (Stablecoin).
*   **Role**: Medium of exchange for purchasing energy.
*   **Stability**: Ensures predictable pricing for consumers.

---

## 3. Pricing Mechanisms

### 3.1 Dynamic Market Price (P2P)
The P2P market price ($P_{mkt}$) floats freely but is influenced by the **Demand/Supply Ratio ($R_{ds}$)**.

$$ R_{ds} = \frac{\text{Total Buy Volume}}{\text{Total Sell Volume}} $$

$$ P_{mkt} = P_{base} \times (1 + \alpha \cdot \log_{10}(R_{ds})) $$

*   $\alpha$: Sensitivity coefficient (default: 0.2).
*   Ideally, $P_{mkt}$ stays within $\pm 20\%$ of $P_{base}$ to prevent volatility.

---

## 4. Market Structure

### 4.1 Order Book (Primary Market)
*   **Mechanism**: On-chain Limit Order Book (CLOB).
*   **Matching**: Double Auction (buyers want low, sellers want high).
*   **Clearing**: Best execution price.

---

## 5. Economic Incentives & Fees

### 6.1 Transaction Fee
*   **Rate**: 25 basis points (0.25%).
*   **Payer**: Taker (Buyer).
*   **Distribution**:
    *   40% -> Grid Maintenance Fund (DSO).
    *   40% -> Platform Development (Treasury).
    *   20% -> Insurance Fund (Default protection).

### 6.2 Recursive Incentives (REC)
Producers generating "Green" energy (Solar) receive separate **Renewable Energy Certificates (RECs)** standardizing their contribution to carbon reduction. These are separate NFT assets tradable on carbon markets.

---

## 7. Economic Stress Testing

To validate the robustness of the model, we simulate extreme market conditions.

### 7.1 Scenario A: Flash Crash (Solar Surplus)
**Event**: Sunny Sunday afternoon; industrial demand drops, solar generation peaks.
*   **Input**: Supply rises 300%, Demand drops 50%.
*   **Model Reaction**:
    *   $R_{ds}$ crashes to 0.16.
    *   $P_{mkt}$ drops to $0.85 \times P_{base}$.
    *   **Result**: Low prices incentivize battery storage systems to absorb cheap energy.

### 7.2 Scenario B: Hyper-Inflation (Grid Failure)
**Event**: Major power plant outage; grid reliance on microgrids spikes.
*   **Input**: Supply drops 80%, Demand constant.
*   **Model Reaction**:
    *   $R_{ds}$ spikes to 5.0.
    *   $P_{mkt}$ hits cap (e.g., $3.0 \times P_{base}$).
    *   **Circuit Breaker**: Trading halts if price exceeds regulatory ceiling, forcing manual load shedding.


---

## 8. Conclusion

The GridTokenX economic model balances **free-market dynamics** with **grid stability** requirements. By anchoring token supply to physical generation and using elasticity-based formulae, it avoids the "ponzi" mechanics of pure DeFi tokens while providing fair compensation to prosumers.
