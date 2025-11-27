# GridTokenX Platform - Docker Guide

This guide provides comprehensive instructions for running the GridTokenX platform using Docker and Docker Compose.

## 📋 Prerequisites

- Docker Engine 20.10 or higher
- Docker Compose 2.0 or higher
- At least 8GB of RAM available for Docker
- 20GB of free disk space

## 🏗️ Architecture Overview

The GridTokenX platform consists of the following services:

| Service | Technology | Port | Description |
|---------|-----------|------|-------------|
| **explorer** | Next.js | 3000 | Blockchain explorer interface |
| **trading** | Next.js | 3001 | Energy trading platform |
| **website** | Next.js (Bun) | 3002 | Marketing website |
| **apigateway** | Rust (Axum) | 8080 | API Gateway and backend services |
| **smartmeter-simulator** | Python (FastAPI) | 8000 | Smart meter data simulator |
| **postgres** | PostgreSQL 16 | 5432 | Database for API Gateway |
| **redis** | Redis 7 | 6379 | Cache for API Gateway |
| **anchor** | Node.js/Solana | 8899, 8900 | Solana program development (optional) |

## 🚀 Quick Start

### 1. Environment Setup

Copy the environment template and configure your values:

```bash
cp .env.example .env
```

Edit `.env` and set secure values for:
- `POSTGRES_PASSWORD` - Database password
- `JWT_SECRET` - Secret key for JWT tokens
- `NEXT_PUBLIC_SOLANA_RPC_URL` - Solana RPC endpoint

### 2. Build All Services

```bash
docker-compose build
```

This will build Docker images for all services. First build may take 10-20 minutes.

### 3. Start All Services

```bash
docker-compose up -d
```

Services will start in the background. Check status with:

```bash
docker-compose ps
```

### 4. View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f explorer
docker-compose logs -f apigateway
```

### 5. Access Services

Once all services are healthy:

- **Explorer**: http://localhost:3000
- **Trading Platform**: http://localhost:3001
- **Website**: http://localhost:3002
- **API Gateway**: http://localhost:8080
- **Smart Meter API**: http://localhost:8000/docs

## 🔧 Development Mode

For development with hot reload and source code mounting:

```bash
# Start with development overrides
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Or use the shorthand
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

In development mode:
- Source code is mounted as volumes
- Changes trigger automatic reloads
- Debug logging is enabled
- Build artifacts are preserved between restarts

## 📦 Individual Service Management

### Start specific services

```bash
# Start only explorer and its dependencies
docker-compose up explorer

# Start API gateway with database
docker-compose up apigateway postgres redis
```

### Rebuild a specific service

```bash
docker-compose build explorer
docker-compose up -d explorer
```

### Stop services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (⚠️ deletes data)
docker-compose down -v
```

## 🔍 Troubleshooting

### Service won't start

1. Check logs:
   ```bash
   docker-compose logs <service-name>
   ```

2. Verify environment variables:
   ```bash
   docker-compose config
   ```

3. Check service health:
   ```bash
   docker-compose ps
   ```

### Database connection issues

1. Ensure PostgreSQL is healthy:
   ```bash
   docker-compose ps postgres
   ```

2. Check database logs:
   ```bash
   docker-compose logs postgres
   ```

3. Verify DATABASE_URL in `.env` matches the PostgreSQL configuration

### Port conflicts

If ports are already in use, modify the port mappings in `docker-compose.yml`:

```yaml
services:
  explorer:
    ports:
      - "3010:4000"  # Changed from 3000 to 3010
```

### Out of memory

Increase Docker's memory limit in Docker Desktop settings or:

```bash
# Stop non-essential services
docker-compose stop anchor
```

### Build failures

1. Clear Docker build cache:
   ```bash
   docker-compose build --no-cache <service-name>
   ```

2. Remove old images:
   ```bash
   docker system prune -a
   ```

## 🧪 Running Tests

### API Gateway Tests

```bash
docker-compose exec apigateway cargo test
```

### Explorer Tests

```bash
docker-compose exec explorer npm test
```

### Anchor Tests

```bash
docker-compose run --rm anchor anchor test
```

## 🔐 Security Considerations

### Production Deployment

Before deploying to production:

1. **Change all default passwords** in `.env`
2. **Use strong JWT secrets** (32+ characters)
3. **Enable HTTPS** with a reverse proxy (nginx, Traefik)
4. **Restrict database access** - don't expose port 5432 publicly
5. **Use secrets management** - consider Docker secrets or external vaults
6. **Enable firewall rules** - only expose necessary ports
7. **Regular updates** - keep base images updated

### Environment Variables

Never commit `.env` files to version control. The `.env.example` template is safe to commit.

## 📊 Monitoring

### Health Checks

All services include health checks. View status:

```bash
docker-compose ps
```

Healthy services show `healthy` or `running` status.

### Resource Usage

Monitor resource consumption:

```bash
docker stats
```

### Database Backups

Backup PostgreSQL data:

```bash
docker-compose exec postgres pg_dump -U gridtokenx gridtokenx > backup.sql
```

Restore from backup:

```bash
cat backup.sql | docker-compose exec -T postgres psql -U gridtokenx gridtokenx
```

## 🛠️ Advanced Configuration

### Custom Network Configuration

Modify `docker-compose.yml` to use custom networks:

```yaml
networks:
  gridtokenx-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

### Volume Management

List volumes:

```bash
docker volume ls | grep gridtokenx
```

Inspect volume:

```bash
docker volume inspect gridtokenx-platform_postgres_data
```

### Scaling Services

Scale specific services (stateless only):

```bash
docker-compose up -d --scale smartmeter-simulator=3
```

## 📝 Service-Specific Notes

### Explorer

- Uses Bun runtime for optimal performance
- Requires Solana RPC endpoint configuration
- Standalone Next.js output for minimal image size

### Trading Platform

- Integrates with Pyth Network for price feeds
- Requires Solana wallet adapter configuration
- Supports WebSocket connections for real-time updates

### API Gateway

- Rust-based for high performance
- Includes database migrations on startup
- Supports JWT authentication

### Smart Meter Simulator

- Optional Kafka integration for event streaming
- Optional InfluxDB for time-series data
- FastAPI with auto-generated OpenAPI docs

### Anchor (Optional)

- For Solana program development and testing
- Commented out by default in docker-compose.yml
- Uncomment if needed for local Solana development

## 🤝 Contributing

When adding new services:

1. Create a `Dockerfile` in the service directory
2. Add `.dockerignore` to exclude unnecessary files
3. Update `docker-compose.yml` with the new service
4. Add environment variables to `.env.example`
5. Update this README with service details

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [GridTokenX Documentation](../gridtokenx-internal/docs/)
- [Solana Documentation](https://docs.solana.com/)

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review service logs: `docker-compose logs <service>`
3. Verify environment configuration: `docker-compose config`
4. Check Docker resources: `docker stats`
5. Consult the GridTokenX internal documentation

## 📄 License

See the main project LICENSE file for details.
