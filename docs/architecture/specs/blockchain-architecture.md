# ⛓ Blockchain Architecture Specification

**Version**: 2.2 (Microservices Standard)  
**Date**: April 10, 2026  
**Status**: ✅ Production Ready

---

## 1. Overview

The GridTokenX blockchain layer is the **immutable settlement and coordination engine** of the platform. Built on **Solana** using the **Anchor Framework (0.32.1)**, it provides the trustless infrastructure for energy tokenization, P2P trading, and decentralized protocol governance.

---

## 2. On-Chain Program Ecosystem

The platform consists of five primary programs that interact via Cross-Program Invocations (CPI).

| Program | Program ID | Primary Responsibility |
| :--- | :--- | :--- |
| **Registry** | `FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c` | Identity, User/Meter PDAs, Staking |
| **Energy Token**| `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` | GRID and REC mint/burn logic |
| **Trading** | `69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na` | Market shards, Order matching, Atomic settlements |
| **Oracle** | `JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop` | Telemetry verification, reading validation |
| **Governance** | `DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4` | DAO proposals, parameters, circuit breakers |

---

## 3. The Tri-Token Model

GridTokenX aligns physical grid needs with economic incentives through three distinct token standards.

### 3.1 GRID (Energy Utility Token)
-   **Standard**: SPL Token-2022
-   **Equation**: `1 GRID = 1 kWh` of verified renewable energy.
-   **Minting**: Authorized only after the **Oracle Program** verifies hardware-signed telemetry.

### 3.2 GRX (Governance & Staking)
-   **Standard**: SPL Token
-   **Supply**: Fixed 1,000,000,000.
-   **Yield**: Stakers earn a 50% share of all protocol trading fees.

### 3.3 Settlement Currency
-   **Standard**: SPL Token (USDC / THB-Stable)
-   **Utility**: The medium of exchange for all settlement windows.

---

## 4. Account Structures (PDAs)

GridTokenX uses **Program Derived Addresses (PDAs)** to ensure deterministic account management without storing private keys for vaults.

### 4.1 Registry PDAs
-   **UserAccount**: `seeds = [b"user", user_uuid]`
    -   Stores `authority`, `kyc_status`, and `staked_grx`.
-   **MeterAccount**: `seeds = [b"meter", meter_pubkey]`
    -   Links a physical device to its owner and recording zone.

### 4.2 Trading PDAs
-   **Market**: `seeds = [b"market", market_name]`
    -   Stores asset types, fee configuration, and matching rules.
-   **Escrow Vault**: `seeds = [b"escrow", market_pda]`
    -   The system-owned vault that locks tokens during active orders.

---

## 5. Settlement Provenance Loop

To maintain absolute data integrity, energy minting follows a strict cryptographic loop:

1.  **Ingestion**: **Oracle Bridge** receives signed telemetry from the physical Edge Gateway.
2.  **Aggregation**: Data is summarized into 15-minute settlement windows.
3.  **Cross-Signing**: The Oracle Bridge signs the summary with its authority key.
4.  **On-Chain Verification**: The **Oracle Program** verifies the signature against the registered public key.
5.  **CPI Minting**: Upon success, the Oracle Program invokes the **Energy Token Program** to mint $GRID tokens to the producer's wallet.

---

## 6. Security Controls

-   **Escrow-First Matching**: Trades only occur between fully collateralized orders.
-   **Circuit Breakers**: The **Governance Program** can trigger `maintenance_mode` to freeze high-risk programs.
-   **32-Slot Finality**: The `api-services` watcher requires 32 confirmation slots (Solana Finalized) before broadcasting a trade as complete.

---

## Related Documentation
-   [Platform Design Specification](../../PLATFORM_DESIGN.md)
-   [System Architecture Spec](./system-architecture.md)
-   [Trading Service Architecture](../services/TRADING_SERVICE_ARCHITECTURE.md)
