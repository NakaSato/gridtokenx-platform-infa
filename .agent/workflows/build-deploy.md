---
description: Build and deploy GridTokenX services
---

# Build & Deploy

Build all services and deploy to development or production environments.

## Quick Commands

// turbo

```bash
# Build all Rust services
just build-all

# Docker build all
docker-compose build

# Deploy to production
./scripts/deploy.sh production
```

## Local Development Build

### 1. Build Rust Services

```bash
# Build all services
just build-all

# Individual builds
cd gridtokenx-api && cargo build
cd gridtokenx-iam-service && cargo build
cd gridtokenx-trading-service && cargo build
cd gridtokenx-oracle-bridge && cargo build
```

### 2. Build Frontend

```bash
# Trading UI
cd gridtokenx-trading
bun install
bun run build

# Portal
cd gridtokenx-portal
bun install
bun run build

# Explorer
cd gridtokenx-explorer
bun install
bun run build
```

### 3. Build Smart Meter Simulator

```bash
cd gridtokenx-smartmeter-simulator
uv sync
```

## Docker Build

### Build All Services

```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa

# Build all containers
docker-compose build

# Build with no cache
docker-compose build --no-cache

# Build specific service
docker-compose build api-gateway
docker-compose build trading-service
docker-compose build iam-service
```

### Docker Build Targets

| Service | Dockerfile | Image Name |
|---------|------------|------------|
| API Gateway | `gridtokenx-api/Dockerfile` | `gridtokenx-api-gateway` |
| IAM Service | `gridtokenx-iam-service/Dockerfile` | `gridtokenx-iam-service` |
| Trading Service | `gridtokenx-trading-service/Dockerfile` | `gridtokenx-trading-service` |
| Oracle Bridge | `gridtokenx-oracle-bridge/Dockerfile` | `gridtokenx-oracle-bridge` |
| Trading UI | `gridtokenx-trading/Dockerfile` | `gridtokenx-trading` |
| Smart Meter | `gridtokenx-smartmeter-simulator/Dockerfile` | `gridtokenx-smartmeter-simulator` |

## Production Deployment

### Prerequisites

- Production environment variables
- Docker and Docker Compose
- Kubernetes cluster (optional)
- SSL certificates

### 1. Configure Production Environment

```bash
# Copy production env
cp .env.production.example .env.production

# Edit with production values
# - Database credentials
# - JWT secrets
# - API keys
# - Blockchain endpoints
```

### 2. Deploy with Docker Compose

```bash
# Production build
docker-compose -f docker-compose.yml \
  --env-file .env.production \
  build --no-cache

# Start services
docker-compose -f docker-compose.yml \
  --env-file .env.production \
  up -d
```

### 3. Run Migrations

```bash
# Database migrations
docker exec gridtokenx-api-gateway \
  sqlx migrate run --database-url $DATABASE_URL
```

### 4. Deploy Smart Contracts

```bash
# Deploy to production cluster
cd gridtokenx-anchor
./scripts/deploy-production.sh
```

## Kubernetes Deployment (Optional)

### 1. Build and Push Images

```bash
# Tag images
docker tag gridtokenx-api-gateway:latest \
  registry.example.com/gridtokenx/api-gateway:v1.0.0

# Push to registry
docker push registry.example.com/gridtokenx/api-gateway:v1.0.0
```

### 2. Apply Kubernetes Manifests

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/api-gateway.yaml
kubectl apply -f k8s/trading-service.yaml
```

## Build Optimization

### Rust Build Cache

```bash
# Use cargo cache
cargo install cargo-cache
cargo-cache

# Shared target directory
export CARGO_TARGET_DIR=/shared/target
```

### Docker Layer Caching

```dockerfile
# Copy Cargo.toml first for layer caching
COPY Cargo.toml Cargo.lock ./
RUN cargo build --release
COPY src/ ./src/
```

## Verification

### Health Checks

```bash
# API Gateway
curl http://localhost:4000/health

# Trading Service
curl http://localhost:8092/health

# IAM Service
curl http://localhost:8080/health
```

### Log Inspection

```bash
# Docker logs
docker logs -f gridtokenx-api-gateway
docker logs -f gridtokenx-trading-service

# Kubernetes logs
kubectl logs -f deployment/api-gateway
```

## Rollback

### Docker Compose

```bash
# Rollback to previous version
docker-compose pull
docker-compose up -d
```

### Kubernetes

```bash
kubectl rollout undo deployment/api-gateway
kubectl rollout status deployment/api-gateway
```

## Related Workflows

- [Testing](./testing.md) - Test before deployment
- [Start Development](./start-dev.md) - Start deployed services
- [Database Management](./db-manage.md) - Run migrations
