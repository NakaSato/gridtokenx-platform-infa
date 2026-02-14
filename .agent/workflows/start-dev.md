---
description: Start the GridTokenX development environment
---

# Start Development Environment

This workflow starts all required services for local development.

## Quick Command

// turbo
```bash
./scripts/start-dev.sh
```

## What This Script Does

1. **Cleanup** - Stops any existing validator and API Gateway processes
2. **Docker Services** - Ensures PostgreSQL and Redis are running
3. **Solana Validator** - Starts `solana-test-validator` with `--reset` flag
4. **Fund Wallets** - Airdrops SOL to default and dev wallets
5. **Create Token** - Creates SPL energy token with dev-wallet as mint authority
6. **Update Config** - Updates .env files with correct token mint address
7. **Build Gateway** - Compiles the API Gateway if needed
8. **Start Gateway** - Launches the API Gateway with proper environment

## Services Started

| Service | URL |
|---------|-----|
| Solana Validator | http://localhost:8899 |
| API Gateway | http://localhost:4000 |
| Swagger Docs | http://localhost:4000/api/docs |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

## Notes
- The script creates a fresh SPL token on each run
- Dev wallet keypair is at `gridtokenx-apigateway/dev-wallet.json` (or repo root `dev-wallet.json` when used by Docker)
- Token mint address is automatically updated in .env files
- **New Terminal tabs** will be opened for API Gateway, Simulator, and Trading UI
- Use `./scripts/stop-dev.sh` to stop background services (Validator, Postgres, Redis)
- You may need to manually close the extra Terminal tabs/windows