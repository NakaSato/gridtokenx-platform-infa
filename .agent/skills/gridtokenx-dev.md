---
name: gridtokenx-dev
description: Complete GridTokenX platform development guide. Covers P2P energy trading on Solana with Rust services, Anchor programs, PostgreSQL/Redis/Kafka infrastructure, and Next.js UIs.
user-invocable: true
---

# GridTokenX Platform Development Skill

## What this Skill is for

Use this Skill when the user asks for:

- **P2P Energy Trading** - Building decentralized energy marketplace features
- **Solana Integration** - Smart contracts, program deployment, blockchain interactions
- **Rust Backend Services** - API Gateway, IAM, Trading Service, Oracle Bridge
- **Database Operations** - PostgreSQL migrations, Redis caching, InfluxDB time-series
- **Frontend Development** - Next.js trading UI, admin portal, explorer
- **IoT Integration** - Smart meter simulators, oracle bridges, data ingestion
- **Infrastructure** - Docker Compose, Kafka messaging, monitoring with Prometheus/Grafana
- **Testing** - Unit tests, integration tests, e2e trading scenarios

## Platform Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GridTokenX Platform                       │
├─────────────────────────────────────────────────────────────┤
│  Frontend Layer                                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ Trading UI  │ │   Portal    │ │  Explorer   │            │
│  │  (Next.js)  │ │  (Next.js)  │ │  (Next.js)  │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
├─────────────────────────────────────────────────────────────┤
│  API Gateway (Rust/Axum) - Port 4000                        │
│  - Authentication & Authorization                            │
│  - Rate Limiting & Caching                                   │
│  - REST/GraphQL Endpoints                                    │
├─────────────────────────────────────────────────────────────┤
│  Microservices                                               │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ IAM Service │ │  Trading    │ │   Oracle    │            │
│  │  (Rust)     │ │  Service    │ │   Bridge    │            │
│  │  Port 8080  │ │  Port 8092  │ │  Port 4010  │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                  │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ PostgreSQL  │ │    Redis    │ │  InfluxDB   │            │
│  │  (Primary)  │ │   (Cache)   │ │ (Time-series)│            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
├─────────────────────────────────────────────────────────────┤
│  Messaging & Blockchain                                      │
│  ┌─────────────┐ ┌─────────────────────────────┐            │
│  │    Kafka    │ │   Solana Validator          │            │
│  │  (Events)   │ │   (Anchor Programs)         │            │
│  └─────────────┘ └─────────────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

## Default stack decisions (opinionated)

### 1. Backend Services: Rust First
- **API Gateway**: Axum framework for high performance
- **Microservices**: Rust with tokio async runtime
- **Database**: SQLx for compile-time verified queries
- **Caching**: Redis with connection pooling

### 2. Frontend: Next.js with Bun
- **Trading UI**: Next.js 14+ with App Router
- **State Management**: React Query + Zustand
- **Blockchain**: @solana/web3.js + Anchor client
- **Runtime**: Bun for faster dev server

### 3. Smart Contracts: Anchor
- **Framework**: Anchor for rapid development
- **Programs**: Registry, Trading, Oracle, Governance, Energy Token
- **Testing**: Anchor test framework + TypeScript
- **Deployment**: Fixed keypairs for consistent Program IDs

### 4. Infrastructure: Docker Compose
- **Development**: Docker Compose for all services
- **Database**: PostgreSQL 17 with replication
- **Cache**: Redis with replica
- **Messaging**: Kafka (KRaft mode, no Zookeeper)
- **Monitoring**: Prometheus + Grafana stack

### 5. Testing Strategy
- **Unit Tests**: Rust `cargo test`, LiteSVM for programs
- **Integration**: Docker Compose + test scripts
- **E2E**: Full platform scenarios with real validator
- **Load**: Custom scripts for throughput testing

## Operating procedure (how to execute tasks)

### 1. Classify the task layer

**Frontend Task** (Trading UI, Portal, Explorer):
- Use Next.js with Bun runtime
- Integrate with API Gateway endpoints
- Use Anchor-generated TypeScript clients

**Backend Task** (API, IAM, Trading, Oracle):
- Use Rust with Axum/warp for APIs
- SQLx for database operations
- Redis for caching
- Kafka for event streaming

**Smart Contract Task** (Anchor programs):
- Use Anchor framework
- Generate IDLs automatically
- Deploy with fixed keypairs
- Test with Anchor test framework

**Infrastructure Task** (Docker, databases, monitoring):
- Use Docker Compose
- Follow replication patterns
- Configure health checks
- Set up monitoring dashboards

### 2. Implementation patterns

#### API Endpoint Pattern
```rust
// Use Axum for REST APIs
use axum::{Router, routing::get, Json};

pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/api/v1/users", get(list_users))
        .route("/api/v1/orders", post(create_order))
        .with_state(state)
}
```

#### Database Pattern
```rust
// Use SQLx with compile-time verification
use sqlx::PgPool;

pub async fn create_user(pool: &PgPool, email: &str) -> Result<Uuid, sqlx::Error> {
    let id = Uuid::new_v4();
    sqlx::query!("INSERT INTO users (id, email) VALUES ($1, $2)", id, email)
        .execute(pool)
        .await?;
    Ok(id)
}
```

#### Anchor Program Pattern
```rust
// Use Anchor for smart contracts
use anchor_lang::prelude::*;

declare_id!("FmvDiFUWsqo7z7XnVniKbZDcz32U5HSDVwPug89c");

#[program]
pub mod registry {
    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        ctx.accounts.registry.authority = *ctx.accounts.signer.key;
        Ok(())
    }
}
```

### 3. Testing requirements

Always include tests:

```bash
# Backend tests
cargo test

# Frontend tests
bun test

# Anchor tests
anchor test

# Integration tests
./scripts/run_integration_tests.sh
```

### 4. Deliverables expectations

When implementing features, provide:

- **Code changes** with clear file paths
- **Migration files** for database schema changes
- **Test files** covering core functionality
- **Environment variable** updates if needed
- **Documentation** updates for new features

## Progressive disclosure (read when needed)

### Workflows
- [Project Overview](../workflows/project-overview.md)
- [Environment Setup](../workflows/environment-setup.md)
- [Start Development](../workflows/start-dev.md)
- [Testing](../workflows/testing.md)
- [Blockchain Init](../workflows/blockchain-init.md)
- [API Development](../workflows/api-development.md)
- [Anchor Development](../workflows/anchor-development.md)
- [Database Migrations](../workflows/database-migrations.md)
- [Docker Services](../workflows/docker-services.md)
- [Monitoring](../workflows/monitoring.md)
- [Debugging](../workflows/debugging.md)

### Skills
- [Solana Development](./SKILL.md) - General Solana patterns
- [Anchor Programs](./programs-anchor.md) - Anchor specifics
- [IDL Codegen](./idl-codegen.md) - Client generation
- [Resources](./resources.md) - External references

## Common commands

```bash
# Start platform
./scripts/app.sh start

# Stop platform
./scripts/app.sh stop

# Check status
./scripts/app.sh status

# Run tests
just test

# Build all
just build-all

# Database migrations
just migrate
just migrate-new <name>

# Docker operations
docker-compose up -d
docker-compose down
docker-compose logs -f
```

## Service ports reference

| Service | Port | URL |
|---------|------|-----|
| API Gateway | 4000 | http://localhost:4000 |
| Trading UI | 3000 | http://localhost:3000 |
| PostgreSQL | 5434 | localhost:5434 |
| Redis | 6379 | localhost:6379 |
| InfluxDB | 8086 | http://localhost:8086 |
| Kafka | 9092 | localhost:9092 |
| Grafana | 3001 | http://localhost:3001 |
| Prometheus | 9090 | http://localhost:9090 |
| Solana RPC | 8899 | http://localhost:8899 |
| Smart Meter API | 8082 | http://localhost:8082 |
| Smart Meter UI | 5173 | http://localhost:5173 |

## Security considerations

### Backend Security
- Validate all user inputs
- Use parameterized queries (SQLx handles this)
- Implement rate limiting
- Use JWT for authentication
- Encrypt sensitive data at rest

### Smart Contract Security
- Validate all account owners
- Use PDAs for program accounts
- Implement proper access control
- Use Anchor constraints
- Test edge cases thoroughly

### Infrastructure Security
- Use secrets management (not hardcoded credentials)
- Enable TLS in production
- Configure CORS properly
- Implement health checks
- Monitor for anomalies

## Performance guidelines

### Backend
- Use connection pooling (database, Redis)
- Implement caching strategies
- Use async/await for I/O
- Profile with `cargo flamegraph`

### Frontend
- Use React Query for data fetching
- Implement optimistic updates
- Lazy load components
- Bundle analysis with `bun build`

### Blockchain
- Optimize compute units (CU)
- Use PDAs efficiently
- Batch operations when possible
- Consider priority fees
