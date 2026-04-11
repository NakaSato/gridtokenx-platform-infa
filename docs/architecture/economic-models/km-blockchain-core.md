# KM: Blockchain Core Architecture (GridTokenX)

**Subject:** Decentralized Energy Trading & Settlement Layer  
**Core Technologies:** Solana, Anchor, SPL Token-2022  
**Architecture Pattern:** Program-Derive-Address (PDA) First, Zero-Copy State

---

## 1. Executive Summary

The GridTokenX Blockchain Core provides an immutable, high-throughput layer for certifying energy provenance and settling P2P trades. It transitions from a Proof-of-Authority (PoA) model to a decentralized **Tri-Token Economy (GRX 2.0)**, linking physical grid edge data to on-chain financial incentives.

---

## 2. Core Program Ecosystem

The system is decomposed into five specialized programs (smart contracts) to minimize security surface area and maximize maintainability.

| Program | ID (Mainnet-beta/Devnet) | Role |
|---------|-------------------------|------|
| **Registry** | `FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c` | **Identity:** Users, Smart Meters, and GRX Staking State. |
| **Energy Token**| `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` | **Utility:** Mint/Burn logic for GRID (Energy) tokens. |
| **Trading** | `69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na` | **Settlement:** Zone-based P2P Order Book & Atomic Swap. |
| **Oracle** | `JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop` | **Verification:** Validates physical readings vs. grid patterns. |
| **Governance** | `DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4` | **Control:** DAO-managed protocol parameters & slashing. |

---

## 3. The Tri-Token Economy (GRX 2.0)

A unique economic design balancing utility, governance, and stability.

1. **GRX (GridTokenX Gov):** Fixed supply. Used for **Validator Staking** (min 10k) and **Prosumer Boost**.
2. **GRID (Energy Utility):** Elastic supply. 1 Token = 1 kWh. Minted upon proven generation.
3. **Currency Token:** Standard stablecoin (e.g., USDC) for settlement and fee collection.

---

## 4. Key Technical Patterns

### 4.1 Proof of Provenance (PoP) Loop
The critical path for energy certification:
1. **Source:** Signed reading from ESP32/Pandapower.
2. **Validation:** Oracle verifies data integrity and provides a confidence score.
3. **Certification:** A **Staked Validator** co-signs the minting transaction.
4. **Minting:** Registry calculates the **Prosumer Boost** and Energy Token program mints `GRID`.

### 4.2 Account Sharding
To overcome Solana's account lock contention:
- Registry and Trading state is distributed across **16 shards**.
- Global counters are aggregated from shards, allowing parallel updates for users and trades.

### 4.3 High-Performance State (Zero-Copy)
- All large accounts use `zero_copy` and `repr(C)` for 8-byte alignment.
- Memory layout is optimized for direct `bytemuck` mapping, reducing deserialization costs and enabling sub-500ms transaction processing.

---

## 5. Security & Risk Management

- **Slashing:** Malicious/Inaccurate Validators lose their staked GRX via Governance intervention.
- **Access Control:** Critical minting/burning is restricted to **PDA Signers** (e.g., the Registry Program signs for Energy Token).
- **Graceful Degradation:** Edge gateways batch readings to handle temporary chain congestion without losing prosumer revenue.

---

## 6. Performance Benchmarks

- **Throughput:** ~530-1,000 TPS (Load dependent).
- **Latency:** ~320ms for asynchronous minting.
- **Efficiency:** 104-byte compact `UserAccount` design for low rent costs.

---

## 🔗 Internal References
- [Blockchain Architecture Overview](../specs/blockchain-architecture.md)
- [Tokenomics 2.0 Design](./tokenomics.md)
- [Grid-Blockchain Integration](./grid-integration-tokenomics.md)
