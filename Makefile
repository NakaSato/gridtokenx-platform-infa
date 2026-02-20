# GridTokenX Platform - Docker Management
# Convenience Makefile for common Docker operations

.PHONY: help build up down stop logs clean restart ps health dev prod db-up db-down db-logs backup-db restore-db test stats pull validate setup-env

# Default target
help:
	@echo "GridTokenX Platform - Development & Docker Management"
	@echo ""
	@echo "Available commands:"
	@echo "  make dev         - Start all services in development mode (recommended)"
	@echo "  make prod        - Start all services in production mode (Docker)"
	@echo "  make up          - Alias for 'make prod'"
	@echo "  make down        - Stop all services"
	@echo "  make stop        - Stop development services."
	@echo "  make build       - Build all Docker images"
	@echo "  make logs        - View logs from all services"
	@echo "  make clean       - Stop services and remove volumes."
	@echo "  make restart     - Restart all services"
	@echo "  make ps          - Show status of all services"
	@echo "  make health      - Check health of all services"
	@echo ""
	@echo "Database commands:"
	@echo "  make db-up       - Start only database services (postgres, redis)"
	@echo "  make db-down     - Stop only database services"
	@echo "  make db-logs     - View logs for database services"
	@echo "  make backup-db   - Create database backup"
	@echo "  make restore-db  - Restore database (use: FILE=path/to/backup.sql)"
	@echo ""
	@echo "Service Endpoints (dev mode):"
	@echo "  Solana RPC:    http://localhost:8899"
	@echo "  API Gateway:   http://localhost:4000"
	@echo "  Simulator API: http://localhost:8000"
	@echo "  Simulator UI:  http://localhost:8080"
	@echo "  Trading UI:    http://localhost:3000"
	@echo "  Admin UI:      http://localhost:3001"
	@echo ""
	@echo "Service-specific commands:"
	@echo "  make logs-<service>    - View logs for specific service"
	@echo "  make restart-<service> - Restart specific service"
	@echo "  make build-<service>   - Rebuild specific service"

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
	@echo "  Solana RPC:    http://localhost:8899"
	@echo "  API Gateway:   http://localhost:4000"
	@echo "  Simulator API: http://localhost:8000"
	@echo "  Simulator UI:  http://localhost:8080"
	@echo "  Trading UI:    http://localhost:3000"
	@echo "  Admin UI:      http://localhost:3001"

# Start services in development mode
dev:
	@echo "Starting GridTokenX platform in development mode..."
	./scripts/start-dev.sh

# Stop all services
down:
	docker-compose down

# Stop development services
stop:
	@echo "Stopping development services..."
	@pkill -f "solana-test-validator" 2>/dev/null || true
	@pkill -f "api-gateway" 2>/dev/null || true
	@pkill -f "uvicorn" 2>/dev/null || true
	@pkill -f "start-simulator" 2>/dev/null || true
	@echo "✅ Development services stopped"
	@echo ""
	@echo "To stop Docker services, run: make down"

# View logs
logs:
	docker-compose logs -f

# Database-only management
db-up:
	docker-compose -f docker-compose.db.yml up -d

db-down:
	docker-compose -f docker-compose.db.yml down

db-logs:
	docker-compose -f docker-compose.db.yml logs -f

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
