# GridTokenX Platform - AI Agent Context

## Project Overview

**GridTokenX** is a blockchain-powered Peer-to-Peer (P2P) energy trading platform built on Solana. It enables decentralized energy trading between prosumers (producers) and consumers using smart contracts for trustless settlement.

### Key Concepts
- **Virtual Power Plants (VPP)**: Aggregated distributed energy resources
- **Renewable Energy Certificates (RECs)**: Tokenized green energy credentials
- **Recurring Orders (DCA)**: Automated periodic energy purchases
- **Automated Market Clearing**: Real-time order matching and settlement

---

## System Architecture

### Microservices Overview

| Service | Directory | Role | Tech Stack | Port |
|---------|-----------|------|------------|------|
| **API Gateway** | `gridtokenx-api/` | Primary Gateway & Orchestrator | Rust (Axum) | 4000/4001 |
| **IAM Service** | `gridtokenx-iam-service/` | Identity & Access Management | Rust (gRPC) | 8080/8090 |
| **Trading Service** | `gridtokenx-trading-service/` | High-frequency Trading Engine | Rust | 8092/8093 |
| **Oracle Bridge** | `gridtokenx-oracle-bridge/` | IoT/Smart Meter Gateway | Rust | 4010 |
| **Anchor Programs** | `gridtokenx-anchor/` | Solana Smart Contracts | Anchor Framework | - |
| **Smart Meter Sim** | `gridtokenx-smartmeter-simulator/` | IoT Device Simulation | Python (FastAPI) | 8082 |

### Frontend Applications

| Application | Directory | Description | Port |
|-------------|-----------|-------------|------|
| **Trading UI** | `gridtokenx-trading/` | Main user trading interface | 3000 |
| **Explorer** | `gridtokenx-explorer/` | Blockchain explorer | 3001 |
| **Portal** | `gridtokenx-portal/` | Administrative dashboard | 3002 |
| **Simulator UI** | `gridtokenx-smartmeter-simulator/ui` | Smart meter control panel | 5173 |

### Infrastructure Services

| Service | Port | Purpose |
|---------|------|---------|
| **PostgreSQL** | 5434 | Primary relational database (with replica on 5433) |
| **Redis** | 6379 | Caching layer (with replica on 6380) |
| **InfluxDB** | 8086 | Time-series data for meter readings |
| **Kafka** | 9092 | Event streaming and messaging |
| **Kong** | 4000 | API Gateway management |
| **Prometheus** | 9090 | Metrics collection |
| **Grafana** | 3001 | Visualization dashboards |
| **Mailpit** | 8025 | Email testing (SMTP: 1025) |
| **Solana RPC** | 8899 | Local validator (WS: 8900) |

---

## Technology Stack

### Backend (Rust)
- **Web Framework**: Axum 0.8
- **Database**: SQLx 0.8 (PostgreSQL)
- **Caching**: Redis 0.32 (Tokio-based)
- **gRPC**: Tonic + ConnectRPC 0.2.1
- **Error Handling**: `anyhow::Result` for application logic
- **Validation**: Validator 0.19/0.20 with derive macros

### Blockchain (Solana)
- **Smart Contracts**: Anchor Framework 0.32.1
- **Token Standards**: SPL Token 8.0.0, SPL Token-2022
- **SDK**: `solana-sdk` 2.3.1, `anchor-client`
- **Programs**: Registry, Energy Token, Trading, Oracle, Governance

### Frontend
- **Framework**: Next.js with Bun runtime
- **Language**: TypeScript

### IoT/Simulation
- **Framework**: Python FastAPI
- **Runtime**: uv (Python package manager)

---

## Development Workflow

### Prerequisites

**OrbStack Required**: GridTokenX uses [OrbStack](https://orbstack.dev/) as its Docker runtime for better performance.

```bash
# Install OrbStack
brew install --cask orbstack

# Verify installation
orb status
```

> 📖 **Migration**: See [OrbStack Migration Guide](docs/ORBSTACK_MIGRATION.md)

### Primary Management Script

The unified script for service orchestration:

```bash
./scripts/app.sh start        # Start all services (OrbStack, Solana, API, UIs)
./scripts/app.sh stop         # Stop all services
./scripts/app.sh restart      # Restart all services
./scripts/app.sh status       # Check service health and endpoints
./scripts/app.sh init         # Initialize blockchain & deploy programs
./scripts/app.sh register     # Register admin user
./scripts/app.sh seed         # Seed database with test users
./scripts/app.sh doctor       # System diagnostics (includes OrbStack check)
./scripts/app.sh logs [svc]   # View service logs
```

**Start Options:**
```bash
./scripts/app.sh start --skip-ui      # Skip frontend UIs
./scripts/app.sh start --skip-solana  # Skip Solana validator
./scripts/app.sh start --docker-only  # Only Docker services
```

### Task Runner (`just`)

```bash
just test           # Run all Rust tests (api, iam, trading)
just test-all       # Include integration tests with Solana validator
just build          # Build API gateway
just build-all      # Build all Rust services
just check          # Run cargo check on API gateway
just check-all      # Check all Rust services
just migrate        # Run SQLx database migrations
just migrate-new <name>  # Create new migration
just migrate-revert # Revert last migration
just migrate-info   # Show migration status
just db-up          # Start PostgreSQL container
just db-down        # Stop PostgreSQL container
just prepare        # Prepare SQLx offline queries
just dev            # Start full dev environment (DB + API)
just docker-up      # Start all Docker services
just docker-down    # Stop all Docker services
just docker-rebuild # Full rebuild without cache
just clean          # Clean build artifacts
just clean-all      # Clean everything including logs
just fmt            # Format code (cargo fmt)
just clippy         # Run lint checks (-D warnings)
just run            # Run API gateway locally
just run-release    # Run in release mode
just watch          # Watch for changes and rebuild
```

### Nushell Helper (`grx.nu`)

For Nushell users with similar functionality to `just`.

---

## Quick Start Guide

### 1. Clone & Initialize

```bash
git clone <repo-url>
cd gridtokenx-platform-infa
git submodule update --init --recursive
```

### 2. Setup Environment

```bash
cp .env.example .env
# Edit .env if needed (default values work for local development)
```

### 3. Launch Platform

```bash
./scripts/app.sh start
```

Wait for all services to be ready, then verify:
```bash
./scripts/app.sh status
```

### 4. Initialize Blockchain (First Time Only)

```bash
./scripts/app.sh init
```

### 5. Register Admin User

```bash
./scripts/app.sh register
# Or manually:
curl -X POST http://localhost:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"P@ssw0rd123!","username":"admin"}'
```

---

## Testing

### Unit & Integration Tests

```bash
# All Rust service tests
just test

# Including Solana validator integration tests
./scripts/run_integration_tests.sh

# Individual service tests
cd gridtokenx-api && cargo test
cd gridtokenx-iam-service && cargo test
cd gridtokenx-trading-service && cargo test
```

### Anchor (Smart Contract) Tests

```bash
cd gridtokenx-anchor
anchor test --skip-build
```

### Test Categories

| Test Type | Command | Description |
|-----------|---------|-------------|
| Unit Tests | `just test` | Fast, no external dependencies |
| Integration Tests | `./scripts/run_integration_tests.sh` | Requires Solana validator |
| Anchor Tests | `anchor test` | Smart contract tests |
| Load Tests | `benchmarks/` | Performance benchmarks |

---

## Database Management

### Migrations

```bash
# Run all pending migrations
just migrate

# Create new migration
just migrate-new add_user_table

# Revert last migration
just migrate-revert

# Check migration status
just migrate-info
```

### Direct Database Access

```bash
# Connect to PostgreSQL
docker exec -it gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx

# Start/Stop database
just db-up
just db-down
```

### SQLx Offline Mode

For CI builds without database connection:
```bash
# Generate .sqlx cache (requires running DB)
cd gridtokenx-api && cargo sqlx prepare

# Build with offline mode
SQLX_OFFLINE=true cargo build
```

---

## Blockchain Development

### Anchor Programs

```bash
cd gridtokenx-anchor

# Build all programs
anchor build

# Deploy specific program
anchor deploy --program-name registry

# Run tests
anchor test

# Start local validator
solana-test-validator --reset
```

### Program IDs (Localnet)

| Program | Program ID |
|---------|------------|
| Registry | `FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c` |
| Energy Token | `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` |
| Trading | `69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na` |
| Oracle | `JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop` |
| Governance | `DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4` |

### Key Scripts

```bash
# Initialize governance
npx ts-node scripts/init-governance.ts

# Initialize market
npx ts-node scripts/init-market.ts

# Initialize oracle
npx ts-node scripts/init-oracle.ts

# Mint test tokens
npx ts-node scripts/mint-tokens.ts

# Extract PDAs
npx ts-node scripts/get_pdas.ts
```

---

## Monitoring & Observability

### Dashboards

| Tool | URL | Credentials |
|------|-----|-------------|
| **Grafana** | http://localhost:3001 | admin / admin |
| **Prometheus** | http://localhost:9090 | - |
| **SigNoz** | http://localhost:3030 | - |
| **Mailpit** | http://localhost:8025 | - |

### SigNoz (OpenTelemetry-Native Observability)

GridTokenX supports **SigNoz** as an alternative/complement to the Prometheus-Grafana stack for unified logs, metrics, and traces.

#### Deployment Options

**Option 1: Install Script (Recommended)**
```bash
git clone -b main https://github.com/SigNoz/signoz.git
cd signoz/deploy/
./install.sh
```

**Option 2: Docker Standalone**
```bash
docker run -d \
  --name signoz \
  -p 3030:3030 \
  signoz/signoz-standalone:latest
```

**Option 3: Docker Compose (Manual Control)**
```bash
git clone https://github.com/SigNoz/signoz.git
cd signoz/deploy/
docker compose up -d
```

#### OpenTelemetry Integration

GridTokenX services are instrumented with OpenTelemetry for distributed tracing.

**Environment Variables:**
```bash
# Add to .env for OTLP export
OTEL_ENABLED=true
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_SERVICE_NAME=gridtokenx-api
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=development
OTEL_TRACES_SAMPLER=always_on
```

**Rust Services Configuration:**
```toml
# Cargo.toml
[dependencies]
opentelemetry = { workspace = true }
opentelemetry-otlp = { workspace = true }
opentelemetry_sdk = { workspace = true }
tracing-opentelemetry = { workspace = true }
```

**Automatic Tracing:**
- All HTTP requests are automatically traced via `otel_tracing_middleware`
- Spans include: method, route, status code, duration, client IP
- Errors (5xx) are automatically recorded in spans

**Manual Instrumentation:**
```rust
use tracing::instrument;

#[instrument(name = "user.login", skip(password))]
async fn login(username: &str, password: &str) -> Result<User> {
    // Function body
}

// Custom spans
let _span = tracing::info_span!("order.process", order_id = "123").entered();
```

**Documentation:** See `docs/opentelemetry-integration.md` for complete guide.

#### Pre-configured Dashboards

GridTokenX includes 5 pre-built dashboards in `docker/signoz/dashboards/`:

| Dashboard | File | Description |
|-----------|------|-------------|
| **Platform Overview** | `platform-overview.json` | Service health, requests, latency, errors |
| **API Performance** | `api-performance.json` | Endpoint metrics, latency heatmaps, HTTP stats |
| **Trading Operations** | `trading-operations.json` | Orders, matching, settlement metrics |
| **Blockchain Monitor** | `blockchain-monitor.json` | Solana transactions, program calls, RPC |
| **Infrastructure** | `infrastructure.json` | PostgreSQL, Redis, Kafka, containers |

**Import Dashboards:**
1. Access SigNoz UI at http://localhost:3030
2. Go to **Dashboards** → **Create Dashboard** → **Import Dashboard**
3. Upload each JSON file from `docker/signoz/dashboards/`

#### Alerting Rules

Pre-configured alerts in `docker/signoz/alerts/gridtokenx-alerts.yml`:

- **Service Health**: Service down, high error rate
- **Performance**: High latency (P95/P99), slow endpoints
- **Trading**: Trading errors, settlement failures, matching latency
- **Blockchain**: Transaction failures, high priority fees, RPC errors
- **Infrastructure**: DB connections, Redis memory, Kafka lag, container resources
- **Security**: Auth failures, rate limiting triggered

#### Metrics Endpoints

- **API Gateway**: `http://localhost:4001/metrics`
- **PostgreSQL Exporter**: http://localhost:9187
- **Redis Exporter**: http://localhost:9121
- **Kafka Exporter**: http://localhost:9308
- **Node Exporter**: http://localhost:9100
- **cAdvisor**: http://localhost:8080

### Alertmanager

- **URL**: http://localhost:9093
- **Config**: `gridtokenx-api/docker/alertmanager/alertmanager.yml`

---

## Implementation Guidelines

### Code Organization

#### API Gateway Structure (`gridtokenx-api/src/`)

```
src/
├── main.rs           # Application entry point
├── startup.rs        # Service initialization & DI
├── lib.rs
├── api/              # HTTP route handlers
├── core/             # Configuration, errors, types
├── domain/           # Business logic
│   ├── trading/      # Trading domain (orders, matching, clearing)
│   ├── identity/     # User management, auth
│   ├── energy/       # Energy tokenization, RECs
│   └── events/       # Domain events
├── infra/            # Infrastructure adapters
│   ├── blockchain/   # Solana RPC, Anchor client
│   ├── database/     # SQLx repositories
│   ├── cache/        # Redis operations
│   └── messaging/    # Kafka producers/consumers
├── services/         # Application services
└── utils/            # Shared utilities
```

### Key Principles

1. **Dependency Injection**: Services initialized in `startup.rs`, injected via `Arc<T>`
2. **On-Chain Consistency**: Database operations must accompany on-chain transactions when `enable_real_blockchain=true`
3. **Security**: Sensitive data (private keys) encrypted using `WalletService` with `master_secret`
4. **Error Handling**: Use `anyhow::Result` for application logic, custom error types for domain errors
5. **Testing**: New features require integration tests in `gridtokenx-api/tests/integration/`

### Reference Implementations

- **Blockchain Integration**: `gridtokenx-api/src/domain/trading/clearing/blockchain.rs` (MarketClearingService)
- **Configuration**: `gridtokenx-api/src/core/config.rs`
- **Solana Instructions**: `gridtokenx-api/src/infra/blockchain/rpc/instructions.rs`
- **Main Entry**: `gridtokenx-api/src/main.rs`

### Database Schema

Migrations located in: `gridtokenx-api/migrations/`

---

## Environment Variables

### Critical Variables

```bash
# Blockchain
SOLANA_CLUSTER=localnet
SOLANA_RPC_URL=http://localhost:8899
SOLANA_WS_URL=ws://localhost:8900

# Program IDs (update after `app.sh init`)
SOLANA_REGISTRY_PROGRAM_ID=...
SOLANA_TRADING_PROGRAM_ID=...
SOLANA_ORACLE_PROGRAM_ID=...
SOLANA_GOVERNANCE_PROGRAM_ID=...
SOLANA_ENERGY_TOKEN_PROGRAM_ID=...
ENERGY_TOKEN_MINT=...

# Database
DATABASE_URL=postgresql://gridtokenx_user:gridtokenx_password@localhost:5434/gridtokenx
REDIS_URL=redis://localhost:6379

# Security
JWT_SECRET=<min 32 chars>
ENCRYPTION_SECRET=<min 32 chars>
API_KEY_SECRET=<secret>

# Feature Flags
TOKENIZATION_ENABLE_REAL_BLOCKCHAIN=true
ENABLE_BLOCKCHAIN_INTEGRATION=true
```

See `.env.example` for complete list.

---

## Troubleshooting

### Common Issues

```bash
# Check system dependencies
./scripts/app.sh doctor

# Services not responding
./scripts/app.sh status

# Database connection errors
just db-down && just db-up

# Port conflicts
lsof -ti:<PORT> | xargs kill -9

# Reset blockchain state
pkill -f solana-test-validator
rm -rf test-ledger
./scripts/app.sh init

# Full reset
docker-compose down -v
./scripts/app.sh stop --all
./scripts/app.sh start
```

### Log Access

```bash
# API Gateway logs
./scripts/app.sh logs api

# Solana validator logs
./scripts/app.sh logs solana
# Or: tail -f scripts/logs/validator.log

# PostgreSQL logs
docker logs -f gridtokenx-postgres

# All Docker logs
docker-compose logs -f
```

---

## Workflows

Detailed SOPs available in `.agent/workflows/`:

| Workflow | Description |
|----------|-------------|
| `environment-setup.md` | Installation and configuration |
| `start-dev.md` / `stop-dev.md` | Launch/stop platform |
| `api-development.md` | Build REST APIs |
| `anchor-development.md` | Smart contract workflow |
| `database-migrations.md` | Schema management |
| `testing.md` | Run all test types |
| `blockchain-init.md` | Initialize contracts |
| `monitoring.md` | Metrics and dashboards |
| `debugging.md` | Troubleshooting guide |

---

## External Resources

- [Anchor Documentation](https://www.anchor-lang.com/)
- [Axum Documentation](https://docs.rs/axum/)
- [Solana Documentation](https://docs.solana.com/)
- [SQLx Documentation](https://github.com/launchbadge/sqlx)
- [GridTokenX Docs](./docs/)

---

## License

Proprietary - GridTokenX
