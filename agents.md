# GridTokenX Platform Agent Guide

Welcome, Agent. This document provides the essential context, architectural overview, and development guidelines for the **GridTokenX Platform**—a blockchain-powered Peer-to-Peer (P2P) energy trading system built on Solana.

---

## 1. Project Overview
GridTokenX enables decentralized energy trading between prosumers (producers) and consumers. It leverages the Solana blockchain for trustless settlement and high-performance smart contracts.

- **Primary Goal**: Secure, transparent, and efficient P2P energy exchange.
- **Key Concepts**: Virtual Power Plants (VPP), Renewable Energy Certificates (RECs), Recurring Orders (DCA), and Automated Market Clearing.

---

## 2. System Architecture

The platform follows a microservices architecture coordinated via a unified management script.

### Docker Runtime

**OrbStack** is the required Docker runtime for GridTokenX. It provides:
- ⚡️ 2-second startup (vs Docker Desktop's ~30s)
- 🚀 Faster networking & disk I/O
- 🔋 Better battery life for MacBook development
- 🌐 Zero-config `.orbstack.local` DNS domains

> 📖 **Setup**: See [OrbStack Migration Guide](docs/ORBSTACK_MIGRATION.md)

### Core Services
| Service | Role | Tech Stack |
|:---|:---|:---|
| `gridtokenx-api` | Primary Gateway & Orchestrator | Rust (Axum) |
| `gridtokenx-iam-service` | Identity & Access Management | Rust (gRPC) |
| `gridtokenx-trading-service` | High-frequency Trading Engine | Rust |
| `gridtokenx-oracle-bridge` | IoT/Smart Meter Gateway | Rust |
| `gridtokenx-anchor` | Solana Smart Contracts | Anchor Framework |
| `gridtokenx-smartmeter-simulator` | IoT Device Simulation | Python (FastAPI) |

### Frontend Components
- `gridtokenx-trading`: Main user trading interface (Next.js).
- `gridtokenx-explorer`: Platform-specific blockchain explorer.
- `gridtokenx-portal`: Administrative dashboard.

---

## 3. Technology Stack & Patterns

### Backend (Rust)
- **Web Framework**: [Axum](https://github.com/tokio-rs/axum).
- **Database (SQL)**: [SQLx](https://github.com/launchbadge/sqlx) for PostgreSQL.
- **Caching/Messaging**: [Redis](https://redis.io/) (Streams and Pub/Sub).
- **Time-Series**: [InfluxDB](https://www.influxdata.com/) for meter readings.
- **gRPC**: [Tonic](https://github.com/hyperium/tonic) and [Buffa](https://github.com/NakaSato/buffa).
- **Error Handling**: Consistently use `anyhow::Result` for application logic.

### Blockchain (Solana)
- **Smart Contracts**: [Anchor](https://www.anchor-lang.com/).
- **Tokens**: SPL Token standards.
- **Interaction**: `solana-sdk` and `anchor-client`.

---

## 4. Development Workflow

### Essential Management
The primary tool for service management is the unified script:
```bash
./scripts/app.sh start    # Start all infrastructure and services
./scripts/app.sh stop     # Gracefully stop the platform
./scripts/app.sh init     # Initialize Solana and deploy contracts
```

### Task Automation
We use `just` as a task runner for common development actions:
```bash
just test        # Run the full test suite
just migrate     # Apply PostgreSQL database migrations
just db-up       # Launch auxiliary services (DB, Redis, Kafka)
```

---

## 5. Agent Instructions & Best Practices

### Contextual Awareness
- **Workflows**: Always check `.agent/workflows/*.md` for specific SOPs (Standard Operating Procedures).
- **Schema**: Database schemas are located in `gridtokenx-api/migrations/`.
- **Reference Implementation**: When implementing new blockchain features, refer to `MarketClearingService` in `gridtokenx-api/src/domain/trading/clearing/blockchain.rs`.

### Implementation Rules
1. **Dependency Injection**: Services must be initialized in `startup.rs` and injected via `Arc<T>`.
2. **On-Chain Consistency**: Every database-level order creation must be accompanied by an on-chain transaction if `enable_real_blockchain` is TRUE.
3. **Security**: Encrypted sensitive data (like user private keys) must only be decrypted using the `WalletService` utility with the `master_secret`.
4. **Testing**: New features **must** include integration tests in `gridtokenx-api/tests/integration/`.

### Useful File Paths
- **Config**: `gridtokenx-api/src/core/config.rs`
- **Main Entry**: `gridtokenx-api/src/main.rs`
- **Solana Instructions**: `gridtokenx-api/src/infra/blockchain/rpc/instructions.rs`
