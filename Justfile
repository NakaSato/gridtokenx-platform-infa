# GridTokenX Justfile - Development Commands

set shell := ["nu", "-c"]

# Default command - show help
default:
    @echo "Available commands:"
    @echo "  just check              - Run cargo check on api-gateway"
    @echo "  just build              - Build api-gateway"
    @echo "  just test               - Run tests"
    @echo "  just migrate            - Run sqlx migrations"
    @echo "  just db-up              - Start PostgreSQL container"
    @echo "  just db-down            - Stop PostgreSQL container"
    @echo "  just prepare            - Prepare sqlx offline queries"
    @echo "  just dev                - Start full development environment"
    @echo "  just docker-up          - Start all docker services"
    @echo "  just docker-down        - Stop all docker services"
    @echo "  just clean              - Clean build artifacts"
    @echo "  just fmt                - Format code"
    @echo "  just clippy             - Run clippy lints"

# Check the api-gateway code
check:
    cd gridtokenx-apigateway && cargo check

# Build the api-gateway
build:
    cd gridtokenx-apigateway && cargo build

# Run tests
test:
    cd gridtokenx-apigateway && cargo test

# Run migrations
migrate:
    cd gridtokenx-apigateway && sqlx migrate run

# Create a new migration
migrate-new name:
    cd gridtokenx-apigateway && sqlx migrate add {{name}}

# Revert last migration
migrate-revert:
    cd gridtokenx-apigateway && sqlx migrate revert

# Start PostgreSQL
db-up:
    docker-compose up -d postgres

# Stop PostgreSQL
db-down:
    docker-compose down postgres

# Prepare sqlx offline queries
prepare:
    cd gridtokenx-apigateway && cargo sqlx prepare

# Start full development environment (db + api)
dev:
    docker-compose up -d postgres redis
    sleep 5
    cd gridtokenx-apigateway && cargo run

# Start all docker services
docker-up:
    docker-compose up -d

# Stop all docker services
docker-down:
    docker-compose down

# Clean build artifacts
clean:
    cd gridtokenx-apigateway && cargo clean
    rm -rf target

# Format code
fmt:
    cd gridtokenx-apigateway && cargo fmt

# Run clippy lints
clippy:
    cd gridtokenx-apigateway && cargo clippy -- -D warnings

# Check database migration status
migrate-info:
    cd gridtokenx-apigateway && sqlx migrate info

# Run api-gateway locally (requires db to be running)
run:
    cd gridtokenx-apigateway && cargo run

# Run in release mode
run-release:
    cd gridtokenx-apigateway && cargo run --release

# Watch for changes and rebuild
watch:
    cd gridtokenx-apigateway && cargo watch -x check

# Docker rebuild
docker-rebuild:
    docker-compose down
    docker-compose build --no-cache
    docker-compose up -d
