---
description: GridTokenX Platform - Complete Project Overview
---

# GridTokenX Platform Overview

A blockchain-powered P2P energy trading platform built on Solana with Anchor smart contracts.

## Architecture

GridTokenX enables peer-to-peer energy trading using:
- **Solana Blockchain** - Smart contracts for trustless trading
- **PostgreSQL** - Primary relational database (with replication)
- **Redis** - Caching layer (with replication)
- **InfluxDB** - Time-series data for energy readings
- **Kafka** - Event streaming and messaging
- **Kong** - API Gateway management

## Project Structure

| Directory | Component | Technology |
|-----------|-----------|------------|
| `gridtokenx-api/` | API Gateway (Primary) | Rust/Axum |
| `gridtokenx-iam-service/` | Identity & Access Management | Rust |
| `gridtokenx-trading-service/` | Trading Engine | Rust |
| `gridtokenx-oracle-bridge/` | Oracle & IoT Gateway | Rust |
| `gridtokenx-anchor/` | Smart Contracts | Anchor/Solana |
| `gridtokenx-trading/` | Trading UI | Next.js/Bun |
| `gridtokenx-portal/` | Admin Portal | Next.js |
| `gridtokenx-explorer/` | Blockchain Explorer | Next.js |
| `gridtokenx-smartmeter-simulator/` | Meter Simulator | Python/FastAPI |
| `gridtokenx-wasm/` | Shared WASM Library | Rust/WASM |

## Service Ports

| Service | Port | URL |
|---------|------|-----|
| API Gateway | 4000 | http://localhost:4000 |
| Trading UI | 3000 | http://localhost:3000 |
| Smart Meter API | 8082 | http://localhost:8082 |
| Smart Meter UI | 5173 | http://localhost:5173 |
| PostgreSQL | 5434 | localhost:5434 |
| Redis | 6379 | localhost:6379 |
| InfluxDB | 8086 | http://localhost:8086 |
| Kafka | 9092 | localhost:9092 |
| Prometheus | 9090 | http://localhost:9090 |
| Grafana | 3001 | http://localhost:3001 |
| Mailpit | 8025 | http://localhost:8025 |
| Solana RPC | 8899 | http://localhost:8899 |

## Management Tools

### 1. Unified Script (`app.sh`)
```bash
./scripts/app.sh start    # Start all services
./scripts/app.sh stop     # Stop all services
./scripts/app.sh status   # Check service status
./scripts/app.sh init     # Initialize blockchain
```

### 2. Task Runner (`just`)
```bash
just test        # Run all tests
just migrate     # Run database migrations
just db-up       # Start PostgreSQL
just clippy      # Run lint checks
```

### 3. Shell Helper (`grx.nu`)
For Nushell users with similar functionality to `just`.

## Quick Start

1. **Clone & Initialize**:
```bash
git clone <repo-url>
cd gridtokenx-platform-infa
git submodule update --init --recursive
```

2. **Setup Environment**:
```bash
cp .env.example .env
```

3. **Launch Platform**:
```bash
./scripts/app.sh start
```

## Related Workflows

- [Start Development](./start-dev.md) - Start all services
- [Stop Development](./stop-dev.md) - Stop all services
- [Database Management](./db-manage.md) - Database commands
- [Blockchain Init](./blockchain-init.md) - Initialize smart contracts
- [Testing](./testing.md) - Run tests
- [Build & Deploy](./build-deploy.md) - Build and deployment
