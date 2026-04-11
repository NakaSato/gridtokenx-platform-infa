# 🏁 Oracle Bridge Design Specification & Summary

**Version**: 2.2 (Standardized)  
**Status**: ✅ Production Ready / Design Freeze

---

## 1. Executive Summary

The **Oracle Bridge** has evolved into the **cryptographic trust anchor** of the GridTokenX Platform. It serves as the bridge between the physical "Layer 0" (Edge Devices) and the digital Exchange Platform. Its primary mission is to ensure that every kilowatt-hour (kWh) recorded on-chain has been verified at the physical source.

---

## 2. Evolutionary Design (V1 → V2)

The transition to the current microservices-based architecture focused on replacing placeholders with robust cryptographic primitives.

| Aspect | Legacy Design (V1) | Production Design (V2.2) |
| :--- | :--- | :--- |
| **Integrity** | Hardcoded signature strings | **Ed25519** Cryptographic Signing |
| **Connectivity** | Synchronous HTTP | **ConnectRPC (gRPC over HTTP/2)** |
| **Throughput** | Sequential ingestion | **Zone-Based Sharded Ingestion** (10 zones) |
| **Trust Model** | Trust-on-first-use | **Registry-verified PDAs** |
| **Resilience** | In-memory only | **Kafka & RabbitMQ Persistence** |

---

## 3. Cryptographic Chain of Trust

GridTokenX implements a rigorous verification loop to prevent telementry spoofing and data tampering:

1.  **Hardware Bound**: Edge Gateways (RPi Zero) use hardware-derived Ed25519 keys for signing.
2.  **Stateless Verification**: The Oracle Bridge verifies signatures in ~5ms without needing a database lookup for every packet (leveraging a high-throughput Redis public-key cache).
3.  **Aggregate Authority**: 15-minute settlement windows are Net-calculated and signed by the **Oracle Bridge Authority Key**, authorizing the **Energy Token Program** to mint tokens.

---

## 4. Operational Ingestion Flow

-   **Path A: Real-time (Low Latency)**: Edge sends individual readings every 5-30s via ConnectRPC.
-   **Path B: Batch (High Durability)**: Edge buffers readings locally and sends signed batches every 15 minutes.
-   **Output Convergence**: Both paths converge in the **Kafka `meter.readings`** topic for downstream persistence.

---

## 5. Intelligence Layer (NILM)

The Bridge's integration with the **Sparse Mixture of Experts (MoE)** model allows it to perform appliance-level disaggregation without off-loading heavy computation to the core database servers. This "Edge-at-the-Bridge" approach enables:
-   **High Resolution**: Captures transient events (V-I trajectory) at high frequency.
-   **Demand Response**: Provides the matching engine with specific appliance consumption data (e.g., EV Charger vs. Aircon).

---

## Related Documentation
-   [Oracle Bridge Detail Spec](./ORACLE_BRIDGE_ARCHITECTURE.md)
-   [System Architecture Spec](../specs/system-architecture.md)
-   [Blockchain Architecture Spec](../specs/blockchain-architecture.md)
