# GridTokenX Architecture Documentation

**Version:** 2.0  
**Last Updated:** March 16, 2026  
**Status:** ✅ Complete & Up-to-Date

---

## Overview

This folder contains the complete technical architecture documentation for the GridTokenX P2P energy trading platform. All documents are maintained as the **single source of truth** for system design, implementation, and operations.

---

## Core Architecture Documents

### 1. [User Registration Workflow](./user-registration-workflow.md) ⭐
**4 Phases | ~50ms email verification | ~400ms meter registration**

Complete user onboarding flow from sign-up to active trading:
- User registration with auto-generated Solana wallet
- Email verification (token-based)
- Meter registration (database + on-chain)
- First reading submission

**Key Topics:**
- Argon2id password hashing
- AES-256-GCM wallet encryption (secret sharding)
- JWT token generation
- 20 GRX initial airdrop
- On-chain meter registration via Registry program

**Related:** [Authentication & JWT Design](./authentication-jwt-design.md)

---

### 2. [Data Flow: Simulator to Blockchain](./data-flow-simulator-to-blockchain.md) ⭐
**5 Phases | ~30ms API latency | ~320ms blockchain send**

End-to-end flow of smart meter readings through the platform:
- Smart Meter Simulator (Python/FastAPI)
- API Gateway (Rust/Axum)
- Async blockchain minting
- On-chain state updates
- Transaction confirmation monitoring

**Key Topics:**
- HTTP transport layer (aiohttp)
- O(1) API latency design
- Async token minting (tokio::spawn)
- Registry program integration
- Energy Token program minting
- WebSocket real-time notifications

**Performance:**
- API Response: ~30ms (O(1))
- Blockchain Send: ~320ms (non-blocking)
- Transaction Confirmation: ~750ms (background)

---

### 3. [P2P Trading Flow](./p2p-trading-flow.md) ⭐
**4 Phases | ~350ms order creation | ~950ms settlement**

Complete P2P energy trading lifecycle:
- Order creation (limit/market orders)
- Order matching (price-time priority)
- On-chain settlement (atomic escrow)
- Post-settlement (balance updates, notifications)

**Key Topics:**
- Sharded matching engine (zone-based)
- P2P cost calculation (wheeling charges, loss factors)
- HMAC-SHA256 order signatures
- Escrow PDA management
- Atomic swaps via CPI
- Real-time WebSocket updates

**Smart Contracts:**
- Trading Program: `5yakTtiNHXHonCPqkwh1M22jujqugCJhEkYaHAoaB6pG`
- Energy Token: `ExZKhghptUk675rjxgHPjJZjczgWWRRwzUTQnqjPTLno`

**Performance:**
- Order Creation: ~350ms
- Order Matching: ~350ms
- On-Chain Settlement: ~950ms
- **Total Flow: ~1.6 seconds**

---

### 4. [Authentication & JWT Design](./authentication-jwt-design.md) ⭐
**3 Methods | HS256 JWT | Role-Based Access Control**

Comprehensive authentication and authorization architecture:
- JWT authentication (standard users)
- API key authentication (AMI/smart meters)
- Engineering key (debugging/impersonation)
- Role-based access control (RBAC)

**Key Topics:**
- JWT structure (HS256, 24h expiry)
- Claims design (sub, username, role, exp, iat, iss)
- Permission matrix (Admin, User, AMI roles)
- Argon2id password security
- API key HMAC-SHA256 validation
- Impersonation for debugging

**Security:**
- Password hashing: Argon2id (64MB memory, 3 iterations)
- JWT secret: 256-bit random key
- Wallet encryption: AES-256-GCM with secret sharding

---

### 5. [Smart Contract Architecture](./smart-contract-architecture.md) ⭐
**5 Programs | Anchor Framework | Cross-Program Invocations**

Complete Solana smart contract architecture:
- Registry Program (user/meter identity)
- Energy Token Program (GRID token)
- Trading Program (order book, escrow, settlement)
- Oracle Program (price feeds, grid data)
- Governance Program (protocol upgrades)

**Key Topics:**
- Program Derived Addresses (PDA)
- Account layouts and state management
- Instruction handlers and CPIs
- Event emission for off-chain indexing
- Error codes and validation
- Anchor test examples (TypeScript)

**Program IDs:**
| Program | ID |
|---------|-----|
| Registry | `DVoD5K5YRuXXF54a3b6r282jRD8RmtVHGfpw55DHFVDe` |
| Energy Token | `ExZKhghptUk675rjxgHPjJZjczgWWRRwzUTQnqjPTLno` |
| Trading | `5yakTtiNHXHonCPqkwh1M22jujqugCJhEkYaHAoaB6pG` |
| Oracle | `Ad5crRxCcvKFAShAMYtRAD9XKak1cwH1FCE6TrpUA9i2` |
| Governance | `DksRNiZsEZ3zN8n8ZWfukFqi3z74e5865oZ8wFk38p4X` |

---

## Supporting Documentation

Located in `/docs/` (root):

### [Benchmark Frameworks](../benchmark_frameworks.md)
Performance benchmarking methodology and results for:
- API Gateway throughput
- Blockchain transaction latency
- Matching engine performance
- Database query optimization

### [Data Collection Methodology](../data_collection_methodology.md)
Smart meter data collection, preprocessing, and validation:
- Data sources and sampling rates
- Quality assurance procedures
- Anomaly detection algorithms
- Privacy and security considerations

### [Tokenomics & Pricing Model](../tokenomics_pricing_model.md)
GRID token economics and P2P pricing:
- Token utility and distribution
- Dynamic pricing algorithms
- Wheeling charges and loss factors
- Grid fee structures

### [Presentation: System Design](../presentation_system_design.md)
High-level system design presentation:
- Context diagrams (C4 Level 1)
- Container diagrams (C4 Level 2)
- Component diagrams (C4 Level 3)
- User journey maps

---

## Architecture Diagrams

Available in `./` folder (PUML + PNG + SVG):

### Backend Architecture
- `architecture_backend.puml` - API Gateway, databases, services
- `architecture_protocols.puml` - Protocol layers (HTTP, WebSocket, Solana)
- `architecture_protocols_detailed.puml` - Detailed protocol interactions

### Blockchain Architecture
- `architecture_blockchain.puml` - Solana programs and PDAs
- `on_chain_minting.puml` - Token minting flow on-chain
- `anchor_minting.puml` - Anchor program minting instructions

### Trading Architecture
- `matching_engine_trading.puml` - Order matching engine
- `atomic_settlement.puml` - Atomic settlement sequence
- `atomic_settlement_sequence.puml` - Detailed settlement steps

### Simulator Architecture
- `architecture_simulator.puml` - Smart meter simulator design
- `preprocessing_methodology.puml` - Data preprocessing pipeline

### User & Wallet Integration
- `user_web2_web3_connection.puml` - Web2 ↔ Web3 identity bridge
- `wallet_address_connection.puml` - Wallet address derivation
- `energy_minting_lifecycle.puml` - Energy token lifecycle

---

## Document Changelog

| Date | Document | Changes |
|------|----------|---------|
| 2026-03-16 | All Core Docs | ✅ Created comprehensive v2.0 documentation |
| 2026-03-16 | Duplicates Removed | ❌ Deleted outdated: smart_contract_design.md, p2p_matching_plan.md, system_architecture_design.md, presentation_architecture.md |

---

## Quick Reference

### Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| API Response Time | < 50ms | ~30ms ✅ |
| Blockchain Send Time | < 500ms | ~320ms ✅ |
| Order Matching | < 500ms | ~350ms ✅ |
| Settlement | < 1.5s | ~950ms ✅ |
| Throughput | 1000+ req/s | 1000+ ✅ |

### Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Next.js 16, React, TailwindCSS, Mapbox GL |
| **Backend** | Rust (Axum), TypeScript, Python (FastAPI) |
| **Database** | PostgreSQL 17, InfluxDB 2.7, Redis 7 |
| **Messaging** | Apache Kafka 3.7 |
| **Blockchain** | Solana (Anchor), SPL Token-2022, Metaplex |
| **Infrastructure** | Docker, Docker Compose, Nginx |

### Key Design Principles

1. **O(1) API Latency** - Async operations for blockchain interactions
2. **Database-First** - Persist before async operations (durability)
3. **Event-Driven** - Kafka for telemetry, WebSocket for real-time
4. **Hybrid Architecture** - Off-chain orchestration, on-chain settlement
5. **Security by Design** - Argon2id, AES-256-GCM, HMAC-SHA256
6. **Scalability** - Sharded matching, connection pooling, caching

---

## Related Repositories

| Repository | Purpose |
|------------|---------|
| `gridtokenx-api` | Rust API Gateway |
| `gridtokenx-anchor` | Solana/Anchor smart contracts |
| `gridtokenx-trading` | Next.js trading UI |
| `gridtokenx-smartmeter-simulator` | Python simulator + React UI |
| `gridtokenx-explorer` | Blockchain explorer UI |
| `gridtokenx-portal` | Admin portal |
| `gridtokenx-wasm` | Shared WASM library |

---

## Contact & Support

For questions or contributions:
- **Documentation Issues**: Create issue in main repository
- **Technical Questions**: Contact GridTokenX Engineering Team
- **Security Reports**: Follow responsible disclosure policy

---

**Last Reviewed:** March 16, 2026  
**Next Review:** April 1, 2026  
**Maintained By:** GridTokenX Engineering Team
