# GridTokenX Platform Agent Guide

Welcome, Agent. This document provides the essential context, architectural overview, and development guidelines for the **GridTokenX Platform**—a blockchain-powered Peer-to-Peer (P2P) energy trading system built on Solana.

---

## 1. Project Overview

GridTokenX enables decentralized energy trading between prosumers (producers) and consumers. It leverages the Solana blockchain for trustless settlement and high-performance smart contracts.

- **Primary Goal**: Secure, transparent, and efficient P2P energy exchange.
- **Key Concepts**: Virtual Power Plants (VPP), Renewable Energy Certificates (RECs), Recurring Orders (DCA), and Automated Market Clearing.

---

## 2. System Architecture

The platform follows a microservices architecture where **each service owns its blockchain interactions**. The API Gateway is a pure orchestrator with NO direct blockchain access.

### Edge-to-Blockchain Data Flow

**Complete Architecture:**

```
Edge Meter → Edge Gateway → API Gateway(Kong) → IAM Service ─┐
                                     → Trading Service─┼→ Solana Blockchain
                                     → Oracle Service─┘
                                     → API Service─┘
```

- **Edge Meter**: Physical smart meters and energy sensors
- **Edge Gateway**: Local aggregation, buffering, protocol translation, Ed25519 signing
- **API Gateway**: Pure orchestration and routing (NO blockchain code)
- **IAM Service**: Identity management + blockchain registration (Registry Program)
- **Trading Service**: Order matching + on-chain settlement (Trading Program)
- **Oracle Service**: Telemetry validation + token minting (Oracle + Energy Token Programs)
- **Solana Blockchain**: On-chain settlement, token transfers, smart contracts

### Service Responsibilities

| Service                           | Role                                | Blockchain Access?             | Messaging                     |
| :-------------------------------- | :---------------------------------- | :----------------------------- | :---------------------------- |
| `gridtokenx-api`                  | API Gateway & Orchestrator          | ❌ NO                          | Kafka consumer, Redis Pub/Sub |
| `gridtokenx-iam-service`          | Identity, Auth, KYC                 | ✅ YES (Registry, Governance)  | Kafka producer, RabbitMQ      |
| `gridtokenx-trading-service`      | Trading Engine, Matching            | ✅ YES (Trading, Energy Token) | Kafka producer, RabbitMQ      |
| `gridtokenx-oracle-bridge`        | Edge Validation, Settlement Signing | ❌ NO (signs for API Gateway)  | Kafka producer, RabbitMQ      |
| `gridtokenx-edge-gateway`         | Edge Aggregation                    | ❌ NO (sends to Oracle Bridge) | Local buffer only             |
| `gridtokenx-anchor`               | Solana Smart Contracts              | N/A (is the blockchain)        | N/A                           |
| `gridtokenx-smartmeter-simulator` | IoT Simulation                      | ❌ NO (sends to Oracle Bridge) | Kafka producer                |

### Docker Runtime

**OrbStack** is the required Docker runtime for GridTokenX. It provides:

- ⚡️ 2-second startup (vs Docker Desktop's ~30s)
- 🚀 Faster networking & disk I/O
- 🔋 Better battery life for MacBook development
- 🌐 Zero-config `.orbstack.local` DNS domains

> 📖 **Setup**: See [OrbStack Migration Guide](docs/ORBSTACK_MIGRATION.md)

### Core Services

| Service                           | Role                                  | Tech Stack       |
| :-------------------------------- | :------------------------------------ | :--------------- |
| `gridtokenx-api`                  | Primary Gateway & Orchestrator        | Rust (Axum)      |
| `gridtokenx-iam-service`          | Identity & Access Management          | Rust (gRPC)      |
| `gridtokenx-trading-service`      | High-frequency Trading Engine         | Rust             |
| `gridtokenx-oracle-bridge`        | IoT Data Validation & Kafka Publisher | Rust             |
| `gridtokenx-edge-gateway`         | Edge Aggregation & Preprocessing      | Rust             |
| `gridtokenx-anchor`               | Solana Smart Contracts                | Anchor Framework |
| `gridtokenx-smartmeter-simulator` | IoT Device Simulation                 | Python (FastAPI) |

### Frontend Components

- `gridtokenx-trading`: Main user trading interface (Next.js).
- `gridtokenx-explorer`: Platform-specific blockchain explorer.
- `gridtokenx-portal`: Administrative dashboard.

---

## 3. Technology Stack & Patterns

### Backend (Rust)

- **Web Framework**: [Axum](https://github.com/tokio-rs/axum).
- **Database (SQL)**: [SQLx](https://github.com/launchbadge/sqlx) for PostgreSQL.
- **Caching**: [Redis](https://redis.io/) (Hashes, Sorted Sets, Pub/Sub).
- **Messaging** (Hybrid Approach):
  - **Kafka**: Event sourcing, streaming, audit trails
  - **RabbitMQ**: Task queues, async jobs, guaranteed delivery
  - **Redis Streams**: Real-time pub/sub (legacy, being migrated)
- **Time-Series**: [InfluxDB](https://www.influxdata.com/) for meter readings.
- **gRPC**: [Tonic](https://github.com/hyperium/tonic) and [Buffa](https://github.com/NakaSato/buffa).
- **Error Handling**: Consistently use `anyhow::Result` for application logic.

### Messaging Strategy

| Use Case                        | Technology    | Reason                               |
| ------------------------------- | ------------- | ------------------------------------ |
| Event sourcing (orders, trades) | Kafka         | Replayable, multiple consumers       |
| Real-time WebSocket broadcast   | Redis Pub/Sub | Ultra-low latency                    |
| Email notifications             | RabbitMQ      | Guaranteed delivery, DLQ             |
| Settlement retries              | RabbitMQ      | Priority queues, exponential backoff |
| Session cache                   | Redis         | Sub-millisecond access               |
| Meter reading streaming         | Kafka         | High throughput, partitioning        |

**Documentation**: See [Hybrid Messaging Architecture](docs/architecture/messaging/HYBRID_MESSAGING_ARCHITECTURE.md)

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
- **Architecture**: Each microservice owns its blockchain domain - do NOT add blockchain code to API Gateway.

### Implementation Rules

1. **Service Boundaries**:
   - **API Gateway** (`gridtokenx-api`): Pure orchestration, NO blockchain code
   - **IAM Service** (`gridtokenx-iam-service`): User identity + Registry/Governance programs
   - **Trading Service** (`gridtokenx-trading-service`): Order matching + Trading program
   - **Oracle Bridge** (`gridtokenx-oracle-bridge`): Edge validation, Ed25519 signing, Kafka/RabbitMQ (NO blockchain)

2. **gRPC Communication**:
   - API Gateway calls microservices via ConnectRPC (gRPC over HTTP/2)
   - Each gRPC client uses connection pooling (default 8 connections, round-robin)
   - Services handle their own retry logic and error handling

3. **Blockchain Integration**:
   - Each service manages its own wallet/authority keypairs
   - Database operations must accompany on-chain transactions
   - Services handle their own transaction confirmation and retry logic

4. **Security**:
   - Encrypted sensitive data (like user private keys) must only be decrypted using the `WalletService` utility with the `master_secret`
   - Blockchain signing keys distributed per-service (not centralized)
   - Ed25519 signature verification at edge and oracle layers

5. **Testing**: New features **must** include integration tests in respective service test directories

6. **Wiki Maintenance Protocol (Karpathy Pattern)**:
   The repository maintains a persistent, compounding knowledge base in `.agent/knowledge/`.
   - **Compiling Knowledge**: Do not rely on re-deriving architecture from raw code. When major features (especially cross-service logic) are implemented, update/create a synthesis page in the wiki.
   - **Operations**:
     - **Ingest**: After a successful Task completion, append a log entry to `log.md` and update `index.md`.
     - **Query**: Use the wiki (`index.md`) as the first point of entry for understanding existing architectural decisions.
     - **Lint**: Periodically audit the wiki for orphan pages or contradictions between implementation and synthesis.
   - **Layering**: `AGENTS.md` (Schema) → `.agent/knowledge/` (Wiki) → Source Code (Raw).

### Useful File Paths

**API Gateway (Orchestration):**

- **Config**: `gridtokenx-api/src/core/config.rs`
- **Main Entry**: `gridtokenx-api/src/main.rs`
- **gRPC Clients**: `gridtokenx-api/src/infra/iam/client.rs`, `gridtokenx-api/src/infra/trading/client.rs`
- **Auth Middleware**: `gridtokenx-api/src/api/middleware/auth.rs`

**Microservices (Blockchain):**

- **IAM Service**: `gridtokenx-iam-service/src/domain/identity/`
- **Trading Service**: `gridtokenx-trading-service/src/`

**Edge & Validation:**

- **Oracle Bridge**: `gridtokenx-oracle-bridge/src/` (Ed25519, Kafka, RabbitMQ)
- **Edge Gateway**: `gridtokenx-edge-gateway/`

**Blockchain:**

- **Anchor Programs**: `gridtokenx-anchor/programs/`
- **Program Tests**: `gridtokenx-anchor/tests/`
