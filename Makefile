# GridTokenX Platform - Docker Management
# Convenience Makefile for common Docker operations

.PHONY: help build up down logs clean restart ps health dev prod

# Default target
help:
	@echo "GridTokenX Platform - Docker Management"
	@echo ""
	@echo "Available commands:"
	@echo "  make build       - Build all Docker images"
	@echo "  make up          - Start all services in production mode"
	@echo "  make down        - Stop all services"
	@echo "  make logs        - View logs from all services"
	@echo "  make clean       - Stop services and remove volumes (⚠️  deletes data)"
	@echo "  make restart     - Restart all services"
	@echo "  make ps          - Show status of all services"
	@echo "  make health      - Check health of all services"
	@echo "  make dev         - Start all services in development mode"
	@echo "  make prod        - Start all services in production mode"
	@echo ""
	@echo "Service-specific commands:"
	@echo "  make logs-<service>    - View logs for specific service"
	@echo "  make restart-<service> - Restart specific service"
	@echo "  make build-<service>   - Rebuild specific service"
	@echo ""
	@echo "Examples:"
	@echo "  make logs-explorer"
	@echo "  make restart-apigateway"
	@echo "  make build-trading"

# Build all images
build:
	docker-compose build

# Start all services (production)
up: prod

# Start services in production mode
prod:
	@echo "Starting GridTokenX platform in production mode..."
	docker-compose up -d
	@echo ""
	@echo "Services started! Access points:"
	@echo "  Explorer:      http://localhost:3000"
	@echo "  Trading:       http://localhost:3001"
	@echo "  Website:       http://localhost:3002"
	@echo "  API Gateway:   http://localhost:8080"
	@echo "  Smart Meter:   http://localhost:8000/docs"

# Start services in development mode
dev:
	@echo "Starting GridTokenX platform in development mode..."
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
	@echo ""
	@echo "Development mode - hot reload enabled"

# Stop all services
down:
	docker-compose down

# View logs
logs:
	docker-compose logs -f

# Clean everything (including volumes)
clean:
	@echo "⚠️  This will remove all containers, networks, and volumes!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "Cleanup complete!"; \
	else \
		echo "Cancelled."; \
	fi

# Restart all services
restart:
	docker-compose restart

# Show service status
ps:
	docker-compose ps

# Check health status
health:
	@echo "Checking service health..."
	@docker-compose ps --format json | jq -r '.[] | "\(.Service): \(.State) - \(.Health)"'

# Service-specific logs
logs-%:
	docker-compose logs -f $*

# Service-specific restart
restart-%:
	docker-compose restart $*

# Service-specific build
build-%:
	docker-compose build $*

# Database backup
backup-db:
	@echo "Creating database backup..."
	@mkdir -p backups
	@docker-compose exec -T postgres pg_dump -U gridtokenx gridtokenx > backups/backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup created in backups/ directory"

# Database restore (use: make restore-db FILE=backups/backup.sql)
restore-db:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: Please specify FILE=path/to/backup.sql"; \
		exit 1; \
	fi
	@echo "Restoring database from $(FILE)..."
	@cat $(FILE) | docker-compose exec -T postgres psql -U gridtokenx gridtokenx
	@echo "Database restored!"

# Run tests
test:
	@echo "Running tests..."
	docker-compose exec apigateway cargo test
	docker-compose exec explorer npm test

# Show resource usage
stats:
	docker stats

# Pull latest images
pull:
	docker-compose pull

# Validate docker-compose configuration
validate:
	docker-compose config

# Setup environment file
setup-env:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from template"; \
		echo "⚠️  Please edit .env and set your configuration values"; \
	else \
		echo ".env file already exists"; \
	fi
