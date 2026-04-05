---
description: Run tests for all GridTokenX components
---

# Testing

Run tests across all GridTokenX components: Anchor programs, Rust services, and frontend.

## Quick Commands

// turbo

```bash
# All tests
just test

# All tests including integration tests
./scripts/run_integration_tests.sh

# Anchor tests only
cd gridtokenx-anchor && anchor test --skip-build

# API Gateway tests
cd gridtokenx-api && cargo test

# Trading Service tests
cd gridtokenx-trading-service && cargo test

# IAM Service tests
cd gridtokenx-iam-service && cargo test
```

## Test Categories

### 1. Unit Tests

Fast tests that don't require external services:

```bash
# Rust services unit tests
just test

# Individual service tests
cd gridtokenx-api && cargo test --lib
cd gridtokenx-iam-service && cargo test --lib
cd gridpointx-trading-service && cargo test --lib
```

### 2. Integration Tests

Require running services (PostgreSQL, Redis, Solana validator):

```bash
# Start required services
./scripts/app.sh start

# Run integration tests
./scripts/run_integration_tests.sh

# API Gateway integration tests
cd gridtokenx-api
cargo test --test '*' -- --ignored
```

### 3. Anchor Program Tests

```bash
cd gridtokenx-anchor

# Build and test
anchor test

# Skip build if already built
anchor test --skip-build

# With coverage
anchor test --coverage
```

### 4. End-to-End Tests

Full system tests simulating real user scenarios:

```bash
# E2E trading flow
./gridtokenx-api/tests/scripts/test_e2e_trading.sh

# High frequency trading test
./gridtokenx-api/tests/scripts/test_hft_throughput.sh

# Load test with 1000 users
./gridtokenx-api/tests/scripts/test_load_1000.sh

# Market administration test
./gridtokenx-api/tests/scripts/test_market_admin.sh
```

## Test Scripts Reference

| Script | Purpose |
|--------|---------|
| `test_api_integration.sh` | API endpoint integration |
| `test_e2e_trading.sh` | Complete trading flow |
| `test_dca_api.sh` | Dollar-cost averaging |
| `test_settlement_p2p.sh` | P2P settlement |
| `test_zone_sharding.sh` | Zone-based sharding |
| `test_hft_multi_user.sh` | Multi-user HFT |
| `test_village_scenario.sh` | Village microgrid |
| `simulate_grid_readings.sh` | Smart meter simulation |
| `register_55_users.sh` | Bulk user registration |

## Running Specific Tests

### Filter by Name
```bash
# Run tests matching pattern
cargo test test_user_registration
cargo test trading::order_matching
```

### Run with Output
```bash
# Show stdout during tests
cargo test -- --nocapture

# Show slow tests
cargo test -- --report-time
```

### Run with Coverage
```bash
# Install cargo-tarpaulin
cargo install cargo-tarpaulin

# Run with coverage
cargo tarpaulin --out Html
```

## Test Environment Setup

### Required Services
```bash
# Start minimal test environment
docker-compose up -d postgres redis

# Start Solana validator
solana-test-validator --reset
```

### Environment Variables
```bash
export TEST_MODE=true
export DATABASE_URL=postgresql://gridtokenx_user:gridtokenx_password@localhost:5434/gridtokenx
export REDIS_URL=redis://localhost:6379
export SOLANA_RPC_URL=http://localhost:8899
```

## Continuous Testing

### Watch Mode
```bash
# Install cargo-watch
cargo install cargo-watch

# Watch and run tests on change
cargo watch -x test
```

### Pre-commit Checks
```bash
# Format check
cargo fmt --check

# Lint check
cargo clippy -- -D warnings

# Run tests
just test
```

## Troubleshooting

### Database Connection Errors
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Test connection
docker exec gridtokenx-postgres pg_isready -U gridtokenx_user
```

### Solana Validator Issues
```bash
# Check validator health
curl http://localhost:8899/health

# Restart validator
pkill -f solana-test-validator
solana-test-validator --reset
```

### Test Timeout
```bash
# Increase test timeout
cargo test -- --test-threads=1

# Run tests sequentially
cargo test -- --test-threads=1
```

## Related Workflows

- [Start Development](./start-dev.md) - Start test environment
- [Database Management](./db-manage.md) - Database setup
- [Build & Deploy](./build-deploy.md) - Build before testing
