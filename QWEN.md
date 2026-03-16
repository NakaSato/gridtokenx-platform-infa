# GridTokenX Platform - Project Context

## Project Overview

**GridTokenX** is a blockchain-powered P2P energy trading platform built on Solana with Anchor smart contracts. The platform enables prosumers (households with solar panels) to trade excess energy directly with consumers using a digital token (GRID) backed by real energy production.

### Core Architecture

The system bridges **Physical Infrastructure** (Smart Meters, Solar Inverters) with **Digital Finance** (Solana Blockchain) using an event-driven microservices architecture:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Frontend UI   │────▶│  API Gateway    │────▶│  Kafka Cluster  │
│   (Next.js)     │     │  (Rust/Axum)    │     │  (Event Stream) │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │                        │
                               ▼                        ▼
                        ┌─────────────┐          ┌─────────────┐
                        │  PostgreSQL │          │  InfluxDB   │
                        │  (Relational)│          │  (Time-series)│
                        └─────────────┘          └─────────────┘
                               │
                               ▼
                        ┌─────────────┐          ┌─────────────┐
                        │   Solana    │◀────────▶│   Anchor    │
                        │  Validator  │          │  Programs   │
                        └─────────────┘          └─────────────┘
```

### Technology Stack

| Layer | Technologies |
|-------|--------------|
| **Core** | Rust (Axum), TypeScript (Bun/Next.js), Python (FastAPI), Solana (Anchor) |
| **Database** | PostgreSQL 17 (Relational), InfluxDB 2.7 (Time-series), Redis 7 (Cache) |
| **Messaging** | Apache Kafka 3.7 (Event Streaming) |
| **Monitoring** | Prometheus, Grafana |
| **Infrastructure** | Docker, Docker Compose |

## Repository Structure

This is a **monorepo** with multiple submodules for different platform components:

```
gridtokenx-platform-infa/
├── gridtokenx-apigateway/        # Rust/Axum API Gateway (submodule)
├── gridtokenx-anchor/            # Solana/Anchor smart contracts (submodule)
├── gridtokenx-trading/           # Next.js trading UI (submodule)
├── gridtokenx-smartmeter-simulator/  # Python simulator + React UI (submodule)
├── gridtokenx-explorer/          # Blockchain explorer UI (submodule)
├── gridtokenx-portal/            # App portal (submodule)
├── gridtokenx-wasm/              # Shared WASM library (submodule)
├── docker/                       # Docker configuration
├── docs/                         # Architecture documentation
├── scripts/                      # Management scripts (app.sh, etc.)
└── test-ledger/                  # Solana test validator ledger
```

### Key Components & Ports

| Component | Directory | Port(s) |
|-----------|-----------|---------|
| API Gateway | `gridtokenx-apigateway/` | 4000 (via Nginx LB) |
| Trading UI | `gridtokenx-trading/` | 3000 |
| Smart Meter Simulator | `gridtokenx-smartmeter-simulator/` | 8082 (API) / 8080 (UI) |
| Explorer UI | `gridtokenx-explorer/` | 3001 |
| App Portal | `gridtokenx-portal/` | 3002 |
| PostgreSQL | Docker | 5432 (primary) / 5433 (replica) |
| Redis | Docker | 6379 (primary) / 6380 (replica) |
| InfluxDB | Docker | 8086 |
| Kafka | Docker | 9092 |
| Prometheus | Docker | 9090 |
| Grafana | Docker | 3001 |
| Mailpit (SMTP) | Docker | 8025 (Web) / 1025 (SMTP) |
| Solana Validator | Local | 8899 (RPC) / 8900 (WS) |

## Building and Running

### Prerequisites

- **Rust**: Nightly toolchain (for edition 2024 features)
- **Bun**: For frontend and scripts
- **Docker**: For databases and services
- **Solana CLI**: For local blockchain development
- **Anchor CLI**: For smart contract development
- **uv**: Python package manager (for simulator)

### Quick Start

1. **Clone & Initialize Submodules**:
   ```bash
   git clone <repo-url>
   cd gridtokenx-platform-infa
   git submodule update --init --recursive
   ```

2. **Setup Environment**:
   ```bash
   cp .env.example .env
   # Edit .env if needed (defaults work for local development)
   ```

3. **Start Platform** (Recommended):
   ```bash
   ./scripts/app.sh start
   ```

4. **Initialize Blockchain** (First time only):
   ```bash
   ./scripts/app.sh init
   ```

### Management Commands

#### Unified Management Script (`app.sh`)

```bash
./scripts/app.sh start            # Start all services
./scripts/app.sh start --skip-ui  # Start without frontend UIs
./scripts/app.sh stop             # Stop all services
./scripts/app.sh restart          # Restart all services
./scripts/app.sh status           # Check service status
./scripts/app.sh init             # Initialize & deploy smart contracts
./scripts/app.sh register         # Register admin user
./scripts/app.sh seed             # Seed database with test users
./scripts/app.sh logs [service]   # View logs (api, solana, postgres, redis)
./scripts/app.sh doctor           # Check system dependencies
```

#### Task Runner (`just`)

```bash
just                  # Show available commands
just check            # Run cargo check on api-gateway
just build            # Build api-gateway
just test             # Run tests
just migrate          # Run sqlx migrations
just migrate-new <name>  # Create new migration
just db-up            # Start PostgreSQL container
just db-down          # Stop PostgreSQL container
just prepare          # Prepare sqlx offline queries
just dev              # Start full development environment
just docker-up        # Start all docker services
just docker-down      # Stop all docker services
just clean            # Clean build artifacts
just fmt              # Format code
just clippy           # Run clippy lints
```

#### Nushell Helper (`grx.nu`)

For Nushell users, providing similar functionality to `just`.

### Manual Service Start

```bash
# Core services only
docker-compose up -d postgres redis mailpit nginx

# Full stack
docker-compose up -d

# API Gateway (requires database running)
cd gridtokenx-apigateway
cargo run --bin api-gateway

# Solana Validator (separate terminal)
solana-test-validator --reset --ledger ../test-ledger
```

## Testing

### API Gateway Tests

```bash
# Unit tests
cd gridtokenx-apigateway
cargo test

# Integration tests
cargo test --test erc_lifecycle_test
cargo test --test token_minting_test
cargo test --test full_trading_cycle_test
cargo test --test smart_meter_flow_test

# With testcontainers
cargo test --features test-utils
```

### Anchor Smart Contract Tests

```bash
cd gridtokenx-anchor
anchor test --skip-build
```

### Benchmarks

```bash
cargo bench -p api-gateway
```

## Development Conventions

### Code Organization (API Gateway)

The API Gateway uses a **modular AppState pattern**:

```rust
// Modular sub-states wrapped in Arc for efficient sharing
pub struct AppState {
    pub core: Arc<CoreState>,
    pub auth: Arc<AuthState>,
    pub trading: Arc<TradingState>,
    // ...
}

// Extract only what you need in handlers
pub async fn my_handler(
    State(core): State<Arc<CoreState>>,
    ...
) -> Result<Json<Response>> {
    // ...
}
```

### Error Handling

- Use the central `ApiError` type for all errors
- Provide structured context using `.context()` or `.map_err()`
- Avoid `.unwrap()` in production code
- Use `anyhow` for application errors, `thiserror` for library errors

### Async Patterns

- All Solana RPC calls use the **nonblocking** client
- Avoid `spawn_blocking` for RPC calls
- Use `tokio::spawn` for fire-and-forget background tasks
- Database connection pool is tuned for high concurrency (see `src/constants.rs`)

### Database Migrations

Migrations are managed with `sqlx`:

```bash
# Create new migration
just migrate-new add_user_sessions

# Run migrations
just migrate

# Check migration status
just migrate-info

# Revert last migration
just migrate-revert
```

### Smart Contract Development

Program IDs are deterministic based on keypairs. The project uses persistent keypairs for consistent IDs:

| Program | ID |
|---------|-----|
| Registry | `DVoD5K5YRuXXF54a3b6r282jRD8RmtVHGfpw55DHFVDe` |
| Energy Token | `ExZKhghptUk675rjxgHPjJZjczgWWRRwzUTQnqjPTLno` |
| Trading | `3iFReh5tvdWkLt7eJcvGKsST7wcwZsSHk3z3xCfUwHLw` |
| Oracle | `Ad5crRxCcvKFAShAMYtRAD9XKak1cwH1FCE6TrpUA9i2` |
| Governance | `DksRNiZsEZ3zN8n8ZWfukFqi3z74e5865oZ8wFk38p4X` |

After deploying contracts, run `propagate_program_ids` to update all service `.env` files.

### Workspace Configuration

The root `Cargo.toml` defines a workspace with shared dependencies:

```toml
[workspace]
members = [
    "gridtokenx-anchor/programs/*",
    "gridtokenx-anchor/shared/*",
    "gridtokenx-apigateway",
]
# Excluded due to zeroize version conflicts:
exclude = ["gridtokenx-wasm", "gridtokenx-anchor/programs/trading"]
```

Note: `gridtokenx-wasm` and `trading` program compile separately via `anchor build` (BPF target).

## Monitoring & Observability

Once running, access monitoring tools:

| Tool | URL | Credentials |
|------|-----|-------------|
| Grafana | http://localhost:3001 | Admin / admin |
| Prometheus | http://localhost:9090 | - |
| Mailpit | http://localhost:8025 | - |

### Metrics

- Prometheus metrics enabled via `ENABLE_METRICS=true`
- Custom business metrics exported for trading volume, user activity
- Tracing enabled via `ENABLE_TRACING=true`

## Key Architecture Decisions

1. **Event-Driven Telemetry**: Smart meter data flows through Kafka for backpressure handling
2. **Hybrid Storage**: PostgreSQL for identity/relationships, InfluxDB for time-series energy data
3. **On-Chain Settlement**: Trading matches settle atomically on Solana
4. **Signed Readings**: Meters sign payloads with Ed25519 keys for authenticity
5. **Nginx Load Balancer**: Distributes traffic across multiple API Gateway instances

## Documentation

- `docs/` - Architecture documentation with C4 diagrams
- `docs/architecture/` - PUML diagrams for various subsystems
- `CONTRIBUTING.md` - Development setup guide
- `README.md` - High-level project overview

## Common Issues

### Solana Validator Not Starting
```bash
# Clean ledger and restart
rm -rf test-ledger
./scripts/app.sh start
```

### Database Connection Errors
```bash
# Ensure PostgreSQL is running
docker ps | grep postgres
just db-up
```

### Program Deployment Fails
```bash
# Ensure validator is running and wallet is funded
solana balance --url http://localhost:8899
solana airdrop 10 <address> --url http://localhost:8899
```

## License

Proprietary - GridTokenX
