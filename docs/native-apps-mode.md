# Native Apps Mode - OrbStack Infrastructure + Native Background Services

## Quick Reference

### Start Commands
```bash
# Full platform (OrbStack infra + native background apps)
./scripts/app.sh start --native-apps

# Without UIs
./scripts/app.sh start --native-apps --skip-ui

# Check what's running
./scripts/app.sh status

# Stop everything
./scripts/app.sh stop --all

# Stop native services only (keep OrbStack)
./scripts/app.sh stop
```

### Log Files
All logs: `scripts/logs/`
```bash
tail -f scripts/logs/api-gateway.log
tail -f scripts/logs/iam.log
tail -f scripts/logs/trading.log
tail -f scripts/logs/oracle-bridge.log
tail -f scripts/logs/validator.log
tail -f scripts/logs/*.log  # Watch all
```

### Service Ports
| Service | Port |
|---------|------|
| Kong Gateway | 4000 |
| Trading UI | 3000 |
| Explorer UI | 3001 |
| Portal | 3002 |
| Simulator UI | 8085 |
| Solana RPC | 8899 |
| PostgreSQL | 5434 |
| Redis | 6379 |

### Common Tasks
```bash
./scripts/app.sh doctor      # Check dependencies
./scripts/app.sh register    # Register admin user
./scripts/app.sh seed        # Seed test users
./scripts/app.sh init        # Initialize blockchain
just build-all               # Build all services
```

### Troubleshooting
```bash
lsof -ti:4000 | xargs kill -9  # Kill port
./scripts/app.sh stop --all    # Clean restart
rm -rf scripts/logs
./scripts/app.sh start --native-apps
ps aux | grep gridtokenx       # Check processes
```

---

## Overview

The `--native-apps` mode allows you to run GridTokenX with:
- **Docker containers**: Infrastructure services (PostgreSQL, Redis, Kafka, InfluxDB, Kong, Mailpit)
- **Native background processes**: Application services (Solana validator, Rust services, Python simulator, Next.js frontends)

This hybrid approach gives you the best of both worlds:
- ✅ Infrastructure isolation and consistency via Docker
- ✅ Native performance for application services
- ✅ Easy debugging with local log files
- ✅ No Docker networking complexities for app services

## Usage

### Start with Native Apps Mode

```bash
# Start everything: Docker infra + native app services (background)
./scripts/app.sh start --native-apps

# Start without UIs
./scripts/app.sh start --native-apps --skip-ui

# View status
./scripts/app.sh status
```

### What Runs Where?

#### Docker Containers
| Service | Container Name | Port |
|---------|---------------|------|
| PostgreSQL | `gridtokenx-postgres` | 5434 |
| Redis | `gridtokenx-redis` | 6379 |
| Redis Replica | `gridtokenx-redis-replica` | 6380 |
| Kafka | `gridtokenx-kafka` | 9092 |
| InfluxDB | `gridtokenx-influxdb` | 8086 |
| Kong Gateway | `gridtokenx-kong` | 4000 |
| Mailpit | `gridtokenx-mailpit` | 8025 (SMTP: 1025) |

#### Native Background Processes
| Service | Binary/Command | Port | Log File |
|---------|---------------|------|----------|
| Solana Validator | `solana-test-validator` | 8899/8900 | `scripts/logs/validator.log` |
| IAM Service | `gridtokenx-iam-service` | 8080/8090 | `scripts/logs/iam.log` |
| Trading Service | `gridtokenx-trading-service` | 8092/8093 | `scripts/logs/trading.log` |
| Oracle Bridge | `gridtokenx-oracle-bridge` | 4010 | `scripts/logs/oracle-bridge.log` |
| API Gateway | `api-gateway` | 4001 | `scripts/logs/api-gateway.log` |
| Simulator API | `uv run start` (Python) | 8082 | `scripts/logs/simulator-api.log` |
| Trading UI | `bun run dev` (Next.js) | 3000 | `scripts/logs/trading-ui.log` |
| Explorer UI | `bun run dev` (Next.js) | 3001 | `scripts/logs/explorer-ui.log` |
| Portal | `bun run dev` (Next.js) | 3002 | `scripts/logs/portal.log` |
| Simulator UI | `bun run dev` (Vite) | 8085 | `scripts/logs/simulator-ui.log` |

### View Logs

All services log to individual files in `scripts/logs/`:

```bash
# API Gateway logs
tail -f scripts/logs/api-gateway.log

# IAM Service logs
tail -f scripts/logs/iam.log

# Trading Service logs
tail -f scripts/logs/trading.log

# All services at once
tail -f scripts/logs/*.log
```

### Stop Services

```bash
# Stop all native services + Docker
./scripts/app.sh stop --all

# Stop only native services (keep Docker running)
./scripts/app.sh stop
```

## Benefits

### 1. **Better Performance**
- No Docker overhead for CPU-intensive services (Solana validator, Rust services)
- Direct filesystem access for databases and caches
- Faster inter-process communication

### 2. **Easier Debugging**
- Log files are immediately accessible locally
- Use native debugging tools (gdb, lldb, strace)
- No need to exec into Docker containers

### 3. **Development Workflow**
- Quick restarts without Docker rebuild
- Easy to attach debuggers (VS Code, CLion)
- Hot reload works normally for Next.js apps

### 4. **Resource Management**
- Better visibility into resource usage via `top`, `htop`
- Easier to kill individual services
- No Docker memory limits

## Prerequisites

Ensure you have all dependencies installed:

```bash
./scripts/app.sh doctor
```

Required:
- Docker (for infrastructure services)
- Rust toolchain (for building Rust services)
- Bun (for Next.js frontends)
- Python + uv (for smart meter simulator)
- Solana CLI (for validator)
- Anchor (for blockchain programs)

## First-Time Setup

1. **Build all Rust services**:
   ```bash
   just build-all
   ```

2. **Install frontend dependencies**:
   ```bash
   cd gridtokenx-trading && bun install
   cd gridtokenx-explorer && bun install
   cd gridtokenx-portal && bun install
   cd gridtokenx-smartmeter-simulator/ui && bun install
   ```

3. **Install Python dependencies**:
   ```bash
   cd gridtokenx-smartmeter-simulator
   uv sync
   ```

4. **Start platform**:
   ```bash
   ./scripts/app.sh start --native-apps
   ```

## Troubleshooting

### Service Won't Start

Check the log file:
```bash
tail -f scripts/logs/<service>.log
```

Common issues:
- **Port already in use**: Run `./scripts/app.sh stop` first
- **Missing dependencies**: Run `./scripts/app.sh doctor`
- **Binary not found**: Run `just build-all`

### Clean Restart

```bash
# Stop everything
./scripts/app.sh stop --all

# Clean logs
rm -rf scripts/logs

# Start fresh
./scripts/app.sh start --native-apps
```

### View Running Processes

```bash
# Check status
./scripts/app.sh status

# Or manually
ps aux | grep gridtokenx
ps aux | grep "bun run dev"
ps aux | grep uvicorn
```

## Comparison with Other Modes

| Mode | Docker Services | Native Services | Use Case |
|------|----------------|----------------|----------|
| `start` | Infrastructure | App services in terminals | Full development |
| `start --docker-only` | Infrastructure only | None | Infrastructure setup |
| `start --skip-ui` | Infrastructure | Backend only | Backend development |
| `start --native-apps` | Infrastructure | Background processes | **Production-like setup** |

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│              Docker Infrastructure               │
│  ┌──────────┐  ┌──────┐  ┌──────┐  ┌──────────┐│
│  │PostgreSQL│  │Redis │  │Kafka │  │ InfluxDB ││
│  └──────────┘  └──────┘  └──────┘  └──────────┘│
│  ┌──────────┐  ┌──────────┐                     │
│  │   Kong   │  │ Mailpit  │                     │
│  └──────────┘  └──────────┘                     │
└────────────────────┬────────────────────────────┘
                     │ (localhost ports)
┌────────────────────┴────────────────────────────┐
│          Native Background Processes              │
│  ┌──────────────────┐  ┌──────────────────────┐ │
│  │Solana Validator  │  │   IAM Service (Rust) │ │
│  └──────────────────┘  └──────────────────────┘ │
│  ┌──────────────────┐  ┌──────────────────────┐ │
│  │Trading Service   │  │  Oracle Bridge (Rust)│ │
│  └──────────────────┘  └──────────────────────┘ │
│  ┌──────────────────┐  ┌──────────────────────┐ │
│  │  API Gateway     │  │ Simulator (Python)   │ │
│  └──────────────────┘  └──────────────────────┘ │
│  ┌──────────────────────────────────────────┐   │
│  │  Next.js Apps (Trading, Explorer, Portal)│   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
                     │
                     ▼
            User Access (Browser)
        http://localhost:3000-3002, 4000, 8085
```

## Best Practices

1. **Always stop properly**: Use `./scripts/app.sh stop` to ensure clean shutdown
2. **Monitor logs**: Keep an eye on log files for errors
3. **Build before starting**: Run `just build-all` before first use
4. **Check dependencies**: Run `./scripts/app.sh doctor` if issues occur
5. **Use status command**: `./scripts/app.sh status` shows what's running

## Migration from Docker-Only

If you're currently running with `./scripts/app.sh start` and want to switch:

```bash
# Stop current setup
./scripts/app.sh stop --all

# Start with native apps
./scripts/app.sh start --native-apps
```

The database and configuration are shared, so no data migration is needed.
