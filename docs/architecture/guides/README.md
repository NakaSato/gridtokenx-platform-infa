# Implementation Guides

Step-by-step workflow documentation and implementation guides.

---

## 📚 Guides

| Guide | Description | Performance | Key Phases |
|-------|-------------|-------------|------------|
| [**User Registration Workflow**](./user-registration-workflow.md) ⭐ | Complete user onboarding flow | ~400ms total | 4 phases: registration, email verification, meter registration, first reading |
| [**P2P Trading Flow**](./p2p-trading-flow.md) ⭐ | Energy trading lifecycle | ~1.6s total | 4 phases: order creation, matching, settlement, post-settlement |
| [**Data Flow: Simulator → Blockchain**](./data-flow-simulator-to-blockchain.md) ⭐ | Smart meter data pipeline | ~30ms API, ~320ms blockchain | 5 phases: simulation, API, minting, confirmation, notification |

---

## 🎯 Usage

These guides are designed for:
- **New developers**: Understanding core workflows
- **Integration testing**: Validating system behavior
- **Performance optimization**: Identifying bottlenecks
- **API development**: Understanding request/response patterns

---

## 🔗 Related

- [Technical Specifications](../specs/) - Architecture documentation
- [Architecture Diagrams](../README.md#3-high-level-architecture-c4-level-2) - Visual diagrams
- [Smart Contracts](../../../gridtokenx-anchor/) - Anchor programs

---

**Last Updated:** April 6, 2026
