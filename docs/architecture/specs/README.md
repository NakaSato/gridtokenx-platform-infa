# Technical Specifications

Detailed technical specifications for GridTokenX platform components.

---

## 📋 Documents

| Document | Description | Key Topics |
|----------|-------------|------------|
| [**System Architecture**](./system-architecture.md) ⭐ | Complete platform architecture overview | System context, tech stack, integration flows, performance targets |
| [**Blockchain Architecture**](./blockchain-architecture.md) ⭐ | Solana/Anchor smart contract layer | Programs, tri-token model, provenance loop, sharding |
| [**Smart Contract Architecture**](./smart-contract-architecture.md) ⭐ | Anchor program design | 5 programs, PDAs, CPIs, account layouts |
| [**Authentication & JWT Design**](./authentication-jwt-design.md) ⭐ | Authentication and authorization | JWT, API keys, RBAC, security |
| [**Consensus Layer**](./consensus-layer.md) 🆕 | Solana consensus + Proof of Provenance | PoH, Tower BFT, PoP, finality, leader schedule |
| [**Runtime Layer (Sealevel)**](./runtime-sealevel.md) 🆕 | Parallel execution model | Sealevel runtime, account isolation, sharding, CPIs |
| [**Storage Layer**](./storage-layer.md) 🆕 | On-chain & off-chain state management | Dual-write pattern, PostgreSQL, Redis, synchronization |

---

## 🎯 Usage

These documents provide in-depth technical specifications for:
- System architecture and component interactions
- Blockchain layer design and smart contracts
- Security architecture and authentication
- Data models and API contracts
- **Consensus mechanisms** (Solana PoH + GridTokenX PoP)
- **Runtime execution** (Sealevel parallelism, account model)
- **Storage architecture** (hybrid on-chain/off-chain state)

---

## 🔗 Related

- [Implementation Guides](../guides/) - Workflow documentation
- [Architecture Diagrams](../README.md#3-high-level-architecture-c4-level-2) - Visual diagrams
- [Economic Models](../economic-models/) - Tokenomics

---

**Last Updated:** April 6, 2026
