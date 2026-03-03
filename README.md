# GridTokenX Platform

A blockchain-powered P2P energy trading platform built on Solana with Anchor smart contracts.

## Architecture

![GridTokenX System Context](docs/proposal/slidev/public/context-diagram.svg)

## Technology Stack

- **Core**: Rust (Axum), TypeScript (Bun/Next.js), Python (FastAPI), Solana (Anchor)
- **Database**: PostgreSQL (Relational), InfluxDB (Time-series), Redis (Cache)
- **Messaging**: Kafka (Event Streaming)
- **Monitoring**: Prometheus, Grafana
- **Infrastructure**: Docker, Docker Compose

## Components

| Component | Directory | Port / Connection |
|-----------|-----------|-------------------|
| **API Gateway** | `gridtokenx-apigateway/` | 4000 (Local) / 4000 (Docker) |
| **Trading UI** | `gridtokenx-trading/` | 3000 (Next.js) |
| **Smart Meter Sim** | `gridtokenx-smartmeter-simulator/`| 8082 (API) / 8080 (UI) |
| **Anchor Programs** | `gridtokenx-anchor/` | Solana Local Validator |
| **WASM Library** | `gridtokenx-wasm/` | Shared logic |
| **PostgreSQL** | Docker | 5432 |
| **Redis** | Docker | 6379 |
| **InfluxDB** | Docker | 8086 |
| **Kafka** | Docker | 9092 |
| **Prometheus** | Docker | 9090 |
| **Grafana** | Docker | 3001 |
| **Mailpit** | Docker | 8025 (Web UI) / 1025 (SMTP) |

> [!NOTE]
> The **Admin Portal** and **Anchor Dashboard** are currently under active development.

## Management Tools

GridTokenX provides several tools to manage the development environment:

### 1. Unified Management Script (`app.sh`)
The recommended way to start and stop the entire platform.
```bash
./scripts/app.sh start    # Start all services (Validator, Docker, API, UIs)
./scripts/app.sh stop     # Stop all services
./scripts/app.sh status   # Check service and endpoint status
./scripts/app.sh init     # Initialize blockchain and deploy programs
```

### 2. Task Runner (`just`)
For common development tasks like testing and migrations.
```bash
just test                 # Run all tests
just migrate              # Run database migrations
just db-up / db-down      # Toggle database containers
just clippy               # Run lint checks
```

### 3. Shell Helper (`grx.nu`)
For Nushell users, providing similar functionality to `just`.

## Quick Start

1. **Clone & Fetch Submodules**:
   ```bash
   git clone <repo-url>
   cd gridtokenx-platform-infa
   git submodule update --init --recursive
   ```

2. **Setup Environment**:
   ```bash
   cp .env.example .env
   # Edit .env if needed
   ```

3. **Launch Platform**:
   ```bash
   ./scripts/app.sh start
   ```

## Testing

### Anchor Tests
```bash
cd gridtokenx-anchor
anchor test --skip-build
```

### API Gateway Tests
```bash
just test
```

## Monitoring

Once the platform is running, you can access monitoring tools:
- **Grafana**: [http://localhost:3001](http://localhost:3001) (Admin/admin)
- **Prometheus**: [http://localhost:9090](http://localhost:9090)
- **Mailpit**: [http://localhost:8025](http://localhost:8025)

## License

Proprietary - GridTokenX
