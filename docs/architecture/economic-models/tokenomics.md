# Tokenomics & Economic Model (GRX 2.0)

**Version:** 2.0 (Redesign)  
**Date:** April 6, 2026  
**Status:** 🚀 Active Design

---

## 1. Executive Summary

GridTokenX 2.0 transitions the platform from a centralized Proof-of-Authority (PoA) model to a decentralized, incentive-aligned **Tri-Token Economy**. This model realigns incentives for prosumers, decentralizes energy certification through **Proof of Provenance**, and creates a sustainable value capture mechanism for the protocol via the **GRX** token.

---

## 2. The Tri-Token System

### 2.1 GRX (Governance & Staking)

- **Role:** The value-capture, security, and governance centerpiece.
- **Supply:** Fixed at 1,000,000,000 GRX.
- **Utility:**
  - **Validator Staking:** Minimum **10,000 GRX** required to become a REC Validator.
  - **Prosumer Boost:** Stake GRX to earn a generation multiplier (up to 1.2x) on energy minting.
  - **Governance:** Vote on protocol fees, inflation rates, and treasury allocations.
- **Value Capture:** Receives protocol fees through buyback-and-burn and staking rewards.

### 2.2 GRID (Energy Utility)

- **Role:** Represents 1 kWh of certified renewable energy.
- **Supply:** Elastic (Mint-and-Burn).
- **Mechanism:** Minted when a Prosumer generates energy; burned when a Consumer uses it.
- **Provenance:** Every GRID token is co-signed by a staked Validator and verified by an Oracle.

### 2.3 Currency Token (Payment)

- **Role:** Stable medium of exchange (e.g., Thai Bath THBC).
- **Utility:** Used for P2P energy settlement and protocol fee collection.

---

## 3. Core Economic Mechanisms

### 3.1 Staked Proof of Provenance (PoP)

Decentralizing the "Source of Truth" for energy generation:

1. **Staking:** Validators lock GRX to gain the right to certify energy.
2. **Certification:** Validators co-sign `mint_tokens_direct` transactions after Oracle verification.
3. **Rewards:** Validators earn a share of the 1.0% trading fee.
4. **Slashing:** Fraudulent certification results in the loss of staked GRX.

### 3.2 Prosumer "Generation Boost"

Encouraging long-term alignment for energy producers:

- **Formula:** `Minted_GRID = Actual_kWh * (1 + sqrt(Staked_GRX / 100,000))`
- **Cap:** Maximum multiplier of **1.2x**.
- **Impact:** Higher yield for prosumers who stake GRX, reducing market sell pressure.

### 3.3 Protocol Fee Funnel

A mandatory **1.0% (100 bps)** fee is applied to all P2P trades, collected in the payment currency.

| Allocation | Destination        | Purpose                                      |
| ---------- | ------------------ | -------------------------------------------- |
| **50%**    | **Staking Yield**  | Rewards for Validators and Prosumer stakers  |
| **30%**    | **Treasury**       | Grid infrastructure and insurance fund       |
| **20%**    | **Buyback & Burn** | Automatic market purchase and burning of GRX |

### 3.4 BME Lite (Consumption Burn)

To link network usage directly to GRX scarcity:

- **Mechanism:** When `GRID` is burned (consumption), a fee of **0.01%** of the trade value (denominated in GRX) is also burned from the user's account or covered by the protocol.

---

## 4. Governance & Parameters

GRX holders govern the "Protocol Levers":

| Parameter           | Default Value | Description                              |
| ------------------- | ------------- | ---------------------------------------- |
| `min_stake_amount`  | 10,000 GRX    | Minimum stake to be an active Validator  |
| `market_fee_bps`    | 100 bps       | Transaction fee on P2P energy trades     |
| `unstaking_period`  | 14 Days       | Delay before staked GRX can be withdrawn |
| `boost_denominator` | 100,000       | Sensitivity of the Prosumer Boost curve  |

---

## 5. Security & Stability

- **Oracle Guard:** Minting only occurs if Oracle confidence score > 90%.
- **Anti-Gaming:** The Prosumer Boost is capped at 1.2x to prevent hyper-inflation of GRID tokens.
- **Flash Loan Protection:** The 14-day unstaking period prevents governance manipulation via flash loans.

---

## 6. Implementation Roadmap

1. **Phase 1 (Foundation):** Deploy GRX token and enable basic staking in Registry.
2. **Phase 2 (Decentralization):** Migrate REC Validation from PoA to Staked PoP.
3. **Phase 3 (Optimization):** Activate the Fee Funnel and Prosumer Boost multipliers.
