---
description: Index of all GridTokenX development workflows
---

# GridTokenX Workflows Index

Complete guide to developing with the GridTokenX platform.

## Quick Start

New to GridTokenX? Start here:

1. [Environment Setup](./environment-setup.md) - Install dependencies and configure
2. [Project Overview](./project-overview.md) - Understand the architecture
3. [Start Development](./start-dev.md) - Launch the platform
4. [Admin Registration](./admin-register.md) - Create admin user

## Workflow Categories

### 🚀 Getting Started

| Workflow | Description |
|----------|-------------|
| [Project Overview](./project-overview.md) | Architecture and components |
| [Environment Setup](./environment-setup.md) | Installation and configuration |
| [Start Development](./start-dev.md) | Launch all services |
| [Stop Development](./stop-dev.md) | Stop all services |

### 🏗️ Development

| Workflow | Description |
|----------|-------------|
| [API Development](./api-development.md) | Build REST APIs with Rust/Axum |
| [Anchor Development](./anchor-development.md) | Smart contract development |
| [Database Migrations](./database-migrations.md) | Schema management with SQLx |
| [Smart Meter Simulator](./smart-meter-simulator.md) | Simulate IoT devices |

### 🧪 Testing & Quality

| Workflow | Description |
|----------|-------------|
| [Testing](./testing.md) | Run all tests (unit, integration, e2e) |
| [Build & Deploy](./build-deploy.md) | Build and deployment processes |

### 🔧 Operations

| Workflow | Description |
|----------|-------------|
| [Docker Services](./docker-services.md) | Manage Docker containers |
| [Database Management](./db-manage.md) | PostgreSQL operations |
| [Blockchain Init](./blockchain-init.md) | Initialize smart contracts |
| [Admin Registration](./admin-register.md) | User management |

### 📊 Observability

| Workflow | Description |
|----------|-------------|
| [Monitoring](./monitoring.md) | Metrics, logs, and dashboards |
| [SigNoz Setup](./signoz-setup.md) | Unified observability (logs, metrics, traces) |
| [Debugging](./debugging.md) | Troubleshoot issues |

## Common Tasks

### Daily Development

```bash
# Start development environment
./scripts/app.sh start

# Check status
./scripts/app.sh status

# Run tests
just test

# Stop services
./scripts/app.sh stop
```

### Database Operations

```bash
# Start PostgreSQL
just db-up

# Run migrations
just migrate

# Create new migration
just migrate-new add_table
```

### Blockchain Development

```bash
# Initialize blockchain
./scripts/app.sh init

# Build Anchor programs
cd gridtokenx-anchor && anchor build

# Deploy programs
anchor deploy
```

### Testing

```bash
# All tests
just test

# Integration tests
./scripts/run_integration_tests.sh

# Anchor tests
cd gridtokenx-anchor && anchor test
```

## Management Tools

### 1. Unified Script (`app.sh`)

```bash
./scripts/app.sh start    # Start all services
./scripts/app.sh stop     # Stop services
./scripts/app.sh status   # Check status
./scripts/app.sh init     # Initialize blockchain
./scripts/app.sh register # Register admin
./scripts/app.sh doctor   # System diagnostics
```

### 2. Task Runner (`just`)

```bash
just test        # Run tests
just build       # Build services
just migrate     # Run migrations
just db-up       # Start database
just signoz-up   # Start SigNoz observability
just clippy      # Lint code
just fmt         # Format code
```

### 3. Docker Compose

```bash
docker-compose up -d           # Start all containers
docker-compose down            # Stop containers
docker-compose logs -f         # View logs
docker-compose ps              # Check status
```

## Service Ports

| Service | Port | URL |
|---------|------|-----|
| API Gateway | 4000 | http://localhost:4000 |
| Trading UI | 3000 | http://localhost:3000 |
| PostgreSQL | 5434 | localhost:5434 |
| Redis | 6379 | localhost:6379 |
| **SigNoz** | 3030 | http://localhost:3030 |
| Grafana | 3001 | http://localhost:3001 |
| Prometheus | 9090 | http://localhost:9090 |
| Solana RPC | 8899 | http://localhost:8899 |

## Troubleshooting

Quick fixes for common issues:

```bash
# Services not starting
./scripts/app.sh doctor

# Database connection errors
just db-down && just db-up

# Port conflicts
lsof -ti:<PORT> | xargs kill -9

# Reset everything
docker-compose down -v
./scripts/app.sh stop
./scripts/app.sh start
```

## Getting Help

- Check [Debugging](./debugging.md) for troubleshooting guides
- View [Monitoring](./monitoring.md) for service health
- Read [Project Overview](./project-overview.md) for architecture details

## Contributing

When adding new features:

1. Create database migration if needed
2. Write tests (unit + integration)
3. Update API documentation
4. Run `just test` and `just clippy`
5. Test with `./scripts/app.sh start`

## Related Resources

- [GridTokenX Documentation](../docs/)
- [Anchor Documentation](https://www.anchor-lang.com/)
- [Axum Documentation](https://docs.rs/axum/)
- [Solana Documentation](https://docs.solana.com/)
