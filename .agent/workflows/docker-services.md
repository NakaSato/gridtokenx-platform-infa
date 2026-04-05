---
description: Manage Docker services (PostgreSQL, Redis, Kafka, etc.)
---

# Docker Services Management

Start, stop, and manage Docker containers for GridTokenX infrastructure.

## Quick Commands

// turbo

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Start specific service
docker-compose up -d postgres redis

# View logs
docker-compose logs -f
```

## Service Overview

| Service | Container Name | Port | Purpose |
|---------|---------------|------|---------|
| PostgreSQL | `gridtokenx-postgres` | 5434 | Primary database |
| PostgreSQL Replica | `gridtokenx-postgres-replica` | 5433 | Read replica |
| Redis | `gridtokenx-redis` | 6379 | Cache layer |
| Redis Replica | `gridtokenx-redis-replica` | 6380 | Cache replica |
| InfluxDB | `gridtokenx-influxdb` | 8086 | Time-series data |
| Kafka | `gridtokenx-kafka` | 9092 | Message broker |
| Kong | `gridtokenx-kong` | 4000 | API Gateway |
| Prometheus | `gridtokenx-prometheus` | 9090 | Metrics |
| Grafana | `gridtokenx-grafana` | 3001 | Visualization |
| Mailpit | `gridtokenx-mailpit` | 8025 | Email testing |

## Starting Services

### Start All Services

```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa
docker-compose up -d
```

### Start Core Services Only

```bash
# Database and cache only
docker-compose up -d postgres redis

# Wait for health checks
docker exec gridtokenx-postgres pg_isready -U gridtokenx_user
docker exec gridtokenx-redis redis-cli ping
```

### Start Monitoring Stack

```bash
docker-compose up -d prometheus grafana
```

### Start Messaging

```bash
docker-compose up -d kafka
```

## Stopping Services

### Stop All Services

```bash
docker-compose down
```

### Stop Specific Service

```bash
docker-compose stop postgres
docker-compose stop redis
```

### Stop and Remove Volumes

⚠️ **Warning**: This deletes all data!

```bash
docker-compose down -v
```

### Stop Specific Service with Volume

```bash
docker-compose down -v postgres
```

## Viewing Logs

### All Services

```bash
docker-compose logs -f
```

### Specific Service

```bash
docker-compose logs -f postgres
docker-compose logs -f kafka
```

### Last N Lines

```bash
docker-compose logs --tail=100 postgres
```

## Service Health Checks

### PostgreSQL

```bash
docker exec gridtokenx-postgres pg_isready -U gridtokenx_user -d gridtokenx
```

### Redis

```bash
docker exec gridtokenx-redis redis-cli ping
```

### Kafka

```bash
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

### InfluxDB

```bash
curl http://localhost:8086/health
```

## Database Operations

### Connect to PostgreSQL

```bash
docker exec -it gridtokenx-postgres \
  psql -U gridtokenx_user -d gridtokenx
```

### Backup Database

```bash
docker exec gridtokenx-postgres \
  pg_dump -U gridtokenx_user gridtokenx > backup.sql
```

### Restore Database

```bash
docker exec -i gridtokenx-postgres \
  psql -U gridtokenx_user -d gridtokenx < backup.sql
```

### Reset Database

```bash
# Stop services
docker-compose down -v

# Start fresh
docker-compose up -d postgres

# Run migrations
cd gridtokenx-api
sqlx database create
sqlx migrate run
```

## Kafka Operations

### List Topics

```bash
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --list
```

### Create Topic

```bash
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create --topic meter-readings \
  --partitions 3 --replication-factor 1
```

### Consume Messages

```bash
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic meter-readings --from-beginning
```

## Redis Operations

### Connect to Redis

```bash
docker exec -it gridtokenx-redis redis-cli
```

### View Keys

```bash
docker exec gridtokenx-redis redis-cli KEYS '*'
```

### Clear Cache

```bash
docker exec gridtokenx-redis redis-cli FLUSHALL
```

## Monitoring

### Prometheus

Access at http://localhost:9090

### Grafana

Access at http://localhost:3001
- Username: `admin`
- Password: `admin`

### Mailpit

Access at http://localhost:8025

## Resource Management

### View Container Stats

```bash
docker stats
```

### Limit Resources

Edit `docker-compose.yml`:

```yaml
services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs postgres

# Check disk space
df -h

# Check Docker daemon
docker info
```

### Port Already in Use

```bash
# Find process using port
lsof -i :5432

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Volume Issues

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect gridtokenx-postgres_data

# Remove volume
docker volume rm gridtokenx-postgres_data
```

### Network Issues

```bash
# List networks
docker network ls

# Inspect network
docker network inspect gridtokenx-network

# Reconnect container
docker network connect gridtokenx-network <container>
```

## Related Workflows

- [Database Management](./db-manage.md) - Database operations
- [Start Development](./start-dev.md) - Start full environment
- [Build & Deploy](./build-deploy.md) - Deploy with Docker
