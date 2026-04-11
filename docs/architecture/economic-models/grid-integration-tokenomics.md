# Grid Infrastructure & Tokenomics Integration (GRX 2.0)

**Version:** 1.0 (Integration)  
**Date:** April 6, 2026  
**Topic:** Connecting Physical Energy Assets to the GRX 2.0 Economy

---

## 1. Overview

This document defines the integration points between the physical grid infrastructure (Smart Meters, Edge Gateways) and the decentralized GRX 2.0 tokenomics model. It bridges the gap between real-time power flow data and on-chain incentive mechanisms like **Staked Proof of Provenance (PoP)** and **Prosumer Boosts**.

---

## 2. Integrated Data Flow (The "Provenance Loop")

The GRX 2.0 economy relies on a multi-stage validation loop to ensure that every `GRID` token minted represents 1 kWh of actual renewable energy.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                  PROVENANCE LOOP - SEQUENCE DIAGRAM                      │
│                                                                         │
│  Smart Meter     Edge Gateway     Oracle Program    Staked Validator    │
│  / Simulator     / API Gateway                     / REC Validator      │
│       │               │                │                   │            │
│       │               │                │                   │            │
│       │ 1.Signed      │                │                   │            │
│       │  Reading      │                │                   │            │
│       │ (kWh,V,Hz)    │                │                   │            │
│       │──────────────→│                │                   │            │
│       │               │                │                   │            │
│       │               │ 2.Local        │                   │            │
│       │               │   Validation   │                   │            │
│       │               │ (Range Checks) │                   │            │
│       │               │───────┐        │                   │            │
│       │               │       │        │                   │            │
│       │               │←──────┘        │                   │            │
│       │               │                │                   │            │
│       │               │ 3.Submit for   │                   │            │
│       │               │   Verification │                   │            │
│       │               │───────────────→│                   │            │
│       │               │                │                   │            │
│       │               │                │ 4.Verified Data   │            │
│       │               │                │ (Confidence > 90) │            │
│       │               │←───────────────│                   │            │
│       │               │                │                   │            │
│       │               │ 5.Request      │                   │            │
│       │               │   Co-Signature │                   │            │
│       │               │──────────────────────────────────→│            │
│       │               │                │                   │            │
│       │               │                │ 6.Verify Stake    │            │
│       │               │                │    & Status       │            │
│       │               │                │──────────────────→│            │
│       │               │                │                   │            │
│       │               │                │ 7.Validator Active│            │
│       │               │                │←──────────────────│            │
│       │               │                │                   │            │
│       │               │ 8.Co-Sign Mint │                   │            │
│       │               │ (kWh × Boost)  │                   │            │
│       │               │───────────────────────────────────→│            │
│       │               │                │                   │            │
│       │               │                │ 9.Mint GRID       │            │
│       │               │                │    to Prosumer    │            │
│       │               │                │ (Energy Token Pgm)│            │
│       │               │                │───────┐           │            │
│       │               │                │       │           │            │
│       │               │                │←──────┘           │            │
│       │               │                │                   │            │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘


Step Details:

  STEP 1: Smart Meter → Edge Gateway
  ┌─────────────────────────────────────────────────┐
  • Cryptographically signed reading (Ed25519)     │
  • Payload: energy_generated, energy_consumed     │
  • Includes: voltage, frequency, timestamp         │
  • Keys stored in secure enclaves (or simulated)   │
  └─────────────────────────────────────────────────┘

  STEP 2: Local Validation (Edge Gateway)
  ┌─────────────────────────────────────────────────┐
  • Range checks on all physical measurements       │
  • Rejects out-of-bound values immediately         │
  • Fast, local rejection before blockchain submit  │
  └─────────────────────────────────────────────────┘

  STEP 3-4: Oracle Verification
  ┌─────────────────────────────────────────────────┐
  • Compares against historical patterns             │
  • Checks peer data from same grid zone            │
  • Outputs Confidence Score (0-100)                │
  • Only scores > 90 proceed to minting             │
  └─────────────────────────────────────────────────┘

  STEP 5-7: Validator Verification
  ┌─────────────────────────────────────────────────┐
  • Queries Registry Program for validator status   │
  • Verifies validator has sufficient GRX staked    │
  • Confirms validator is active (not slashed)      │
  └─────────────────────────────────────────────────┘

  STEP 8-9: Token Minting
  ┌─────────────────────────────────────────────────┐
  • Validator co-signs mint transaction             │
  • Energy Token Program applies Prosumer Boost     │
  • GRID tokens minted to prosumer wallet           │
  • 1 GRID = 1 kWh certified renewable energy       │
  └─────────────────────────────────────────────────┘
```

### 2.1 Stage 1: Physical Generation
- **Hardware:** Smart Meters (ESP32-based) or high-fidelity Simulators (Pandapower).
- **Security:** Readings are cryptographically signed at the source using Ed25519 keys stored in secure enclaves (or simulated equivalents).
- **Payload:** Includes `energy_generated`, `energy_consumed`, `voltage`, and `frequency`.

### 2.2 Stage 2: Oracle Verification
- **Role:** The `Oracle` program acts as the bridge. It compares incoming readings against historical patterns and peer data from the same grid zone.
- **Output:** A **Confidence Score**. Only readings with a score > 90 proceed to automatic minting.

### 2.3 Stage 3: Validator Co-Signing (The Decentralized Gate)
- **Role:** Instead of a central API key, a **Staked REC Validator** must sign the transaction.
- **Incentive:** Validators earn a portion of the 1.0% trading fee for every kWh they accurately certify.
- **Risk:** Validators co-signing fraudulent data face **GRX slashing** triggered by the Oracle or peer audits.

---

## 3. Implementing the "Prosumer Boost"

The Prosumer Boost is a real-time calculation performed during the minting process, rewarding prosumers for their long-term alignment (staking GRX).

### 3.1 Integration Logic
When the Edge Gateway prepares the `mint_tokens_direct` instruction:
1. **Fetch Stake:** The gateway queries the `Registry` program for the user's `staked_grx` amount.
2. **Calculate Multiplier:** 
   - `Multiplier = 1 + sqrt(staked_grx / 100,000)`
   - *Example:* Staking 40,000 GRX yields a `1 + sqrt(0.4) ≈ 1.63x`? (Wait, let's use the 1.2x cap).
   - *Corrected:* `Multiplier = min(1.2, 1 + sqrt(staked_grx / 100,000))`
3. **Execute Mint:** The `Energy Token` program receives the `actual_kWh` and applies the multiplier on-chain to mint the final `GRID` amount.

---

## 4. Consumption Integration (BME Lite)

The integration of the "Consumption Burn" (BME Lite) occurs during the **Atomic Settlement** of an energy trade.

### 4.1 Trade Settlement Hook
In the `Trading` program's `release_escrow` instruction:
- **Input:** 100 kWh trade at $0.10/kWh ($10 total).
- **Protocol Fee (1.0%):** $0.10 (collected in Currency Token).
- **BME Lite Burn (0.01%):** $0.001 worth of GRX is burned from the Consumer's linked account.
- **Infrastructure Impact:** This creates a direct correlation between grid utilization (trading volume) and GRX scarcity.

---

## 5. Grid Edge Resilience

To ensure the grid remains functional even during blockchain congestion:
- **Aggregated Minting:** Edge Gateways can batch 15-minute readings into 1-hour "Minting Bundles" to reduce transaction costs and validator overhead.
- **Offline Buffer:** If the Solana network or the Validator set is unreachable, the Edge Gateway buffers readings locally and synchronizes them once connectivity is restored, ensuring no prosumer rewards are lost.

---

## 6. Summary of Component Roles

| Component | Role in GRX 2.0 | Integration point |
|-----------|-----------------|-------------------|
| **Smart Meter** | Data Source | Ed25519 Signing |
| **Edge Gateway** | Orchestrator | Minting & Boost Calculation |
| **Oracle Program** | Verifier | Confidence Scoring |
| **Validator Node** | Auditor | Co-signing & Staking |
| **Registry Program** | State Storage | Stake & Status Tracking |
| **Trading Program** | Value Capture | Fee Funnel & BME Lite |

---

## Related Documentation
- [Tokenomics & Economic Model (GRX 2.0)](./tokenomics.md)
- [Complete End-to-End Flow: Simulator to Blockchain](../specs/system-architecture.md#secure-telemetry-pipeline)
- [P2P Trading Flow](../specs/system-architecture.md#3-high-level-architecture-c4-level-2)
