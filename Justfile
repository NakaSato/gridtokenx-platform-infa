# GridTokenX Justfile - Development Commands

set shell := ["nu", "-c"]

# Default command - show help
default:
    @echo "Available commands:"
    @echo "  just check              - Run cargo check on api-gateway"
    @echo "  just build              - Build api-gateway"
    @echo "  just test               - Run tests"
    @echo "  just migrate            - Run sqlx migrations"
    @echo "  just db-up              - Start PostgreSQL container (OrbStack)"
    @echo "  just db-down            - Stop PostgreSQL container"
    @echo "  just prepare            - Prepare sqlx offline queries"
    @echo "  just dev                - Start full development environment"
    @echo "  just orb-up             - Start all OrbStack services"
    @echo "  just orb-down           - Stop all OrbStack services"
    @echo "  just signoz-up          - Start SigNoz observability"
    @echo "  just signoz-down        - Stop SigNoz"
    @echo "  just tempo-up           - Start Grafana Tempo (tracing)"
    @echo "  just tempo-down         - Stop Tempo"
    @echo "  just observability-up   - Start Tempo + SigNoz"
    @echo "  just clean              - Clean build artifacts"
    @echo "  just fmt                - Format code"
    @echo "  just clippy             - Run clippy lints"

# Check the api-gateway code
check:
    (cd gridtokenx-api; cargo check)

# Build the api-gateway
build:
    (cd gridtokenx-api; cargo build)

# Check all codebases
check-all:
    (cd gridtokenx-api; cargo check)
    (cd gridtokenx-iam-service; cargo check)
    (cd gridtokenx-trading-service; cargo check)

# Build all binaries
build-all:
    (cd gridtokenx-api; cargo build)
    (cd gridtokenx-iam-service; cargo build)
    (cd gridtokenx-trading-service; cargo build)

# Run all microservice tests
test:
    (cd gridtokenx-api; cargo test)
    (cd gridtokenx-iam-service; cargo test)
    (cd gridtokenx-trading-service; cargo test)

# Run all tests including integration tests requiring solana validator
test-all:
    ./scripts/run_integration_tests.sh

# Run migrations (Primary Gateway)
migrate:
    (cd gridtokenx-api; sqlx migrate run)

# Create a new migration
migrate-new name:
    (cd gridtokenx-api; sqlx migrate add {{name}})

# Revert last migration
migrate-revert:
    (cd gridtokenx-api; sqlx migrate revert)

# Start PostgreSQL (OrbStack)
db-up:
    docker compose up -d postgres

# Stop PostgreSQL
db-down:
    docker compose down postgres

# Prepare sqlx offline queries
prepare:
    (cd gridtokenx-api; cargo sqlx prepare)

# Start full development environment (db + api)
dev:
    docker compose up -d postgres redis
    sleep 5
    (cd gridtokenx-api; cargo run)

# Start all OrbStack services
orb-up:
    docker compose up -d

# Stop all OrbStack services
orb-down:
    docker compose down

# Clean build artifacts
clean:
    (cd gridtokenx-api; cargo clean)
    rm -rf target

# Clean all build artifacts
clean-all:
    cargo clean
    rm -rf target
    rm -rf scripts/logs

# Format all code
fmt:
    cargo fmt

# Run clippy lints
clippy:
    (cd gridtokenx-api; cargo clippy -- -D warnings)

# Check database migration status
migrate-info:
    (cd gridtokenx-api; sqlx migrate info)

# Run api-gateway locally (requires db to be running)
run:
    (cd gridtokenx-api; cargo run --bin api-gateway)

# Run in release mode
run-release:
    (cd gridtokenx-api; cargo run --release)

# Watch for changes and rebuild
watch:
    (cd gridtokenx-api; cargo watch -x check)

# OrbStack rebuild (All Services)
orb-rebuild:
    docker compose down
    docker compose build --no-cache
    docker compose up -d

# Start SigNoz observability platform
signoz-up:
    docker compose up -d signoz

# Stop SigNoz observability platform
signoz-down:
    docker compose stop signoz

# View SigNoz logs
signoz-logs:
    docker compose logs -f signoz

# Start Grafana Tempo (distributed tracing)
tempo-up:
    docker compose up -d tempo

# Stop Grafana Tempo
tempo-down:
    docker compose stop tempo

# View Tempo logs
tempo-logs:
    docker compose logs -f tempo

# Start all observability (Tempo + SigNoz)
observability-up:
    docker compose up -d tempo signoz

# Stop all observability
observability-down:
    docker compose stop tempo signoz
