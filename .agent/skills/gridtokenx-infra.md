---
name: gridtokenx-infra
description: Infrastructure and DevOps for GridTokenX. Covers Docker Compose, PostgreSQL replication, Redis clustering, Kafka messaging, monitoring stack, and deployment strategies.
user-invocable: true
---

# GridTokenX Infrastructure Skill

## What this Skill is for

Use this Skill when the user asks for:

- **Docker Compose** configuration and management
- **Database setup** (PostgreSQL, Redis, InfluxDB)
- **Message broker** configuration (Kafka)
- **Monitoring stack** (Prometheus, Grafana, Mailpit)
- **Service orchestration** and health checks
- **Network configuration** and inter-service communication
- **Volume management** and data persistence
- **Production deployment** strategies

## Infrastructure overview

```
┌─────────────────────────────────────────────────────────────┐
│                  Docker Compose Network                      │
│                   gridtokenx-network                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │   PostgreSQL     │  │  PostgreSQL      │                │
│  │   (Primary)      │─▶│  (Replica)       │                │
│  │   :5432          │  │  :5432           │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │     Redis        │  │   Redis          │                │
│  │   (Primary)      │─▶│   (Replica)      │                │
│  │   :6379          │  │   :6379          │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │      Kafka       │  │    InfluxDB      │                │
│  │   (KRaft Mode)   │  │  (Time-series)   │                │
│  │   :9092          │  │   :8086          │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │    Prometheus    │  │     Grafana      │                │
│  │   (Metrics)      │  │  (Dashboards)    │                │
│  │   :9090          │  │   :3000          │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │      Mailpit     │  │      Kong        │                │
│  │   (Email Test)   │  │  (API Gateway)   │                │
│  │   :8025          │  │   :4000          │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Docker Compose patterns

### Service definition template

```yaml
# docker-compose.yml
services:
  service-name:
    image: <image>:<tag>
    container_name: gridtokenx-<service>
    environment:
      - KEY=value
      - KEY2=${ENV_VAR}
    ports:
      - "<host>:<container>"
    volumes:
      - <host-path>:<container-path>
    networks:
      - gridtokenx-network
    depends_on:
      service-dep:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "command", "to", "check"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
    restart: unless-stopped
```

### Health check patterns

```yaml
# PostgreSQL health check
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U gridtokenx_user -d gridtokenx"]
  interval: 10s
  timeout: 5s
  retries: 5

# Redis health check
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 10s
  timeout: 3s
  retries: 5

# HTTP endpoint health check
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 5

# Custom script health check
healthcheck:
  test: ["CMD-SHELL", "/scripts/healthcheck.sh"]
  interval: 30s
  timeout: 10s
  retries: 5
```

## Database configurations

### PostgreSQL with Replication

```yaml
# Primary PostgreSQL
postgres:
  image: postgres:17-alpine
  container_name: gridtokenx-postgres
  environment:
    POSTGRES_DB: gridtokenx
    POSTGRES_USER: gridtokenx_user
    POSTGRES_PASSWORD: gridtokenx_password
    TZ: UTC
  command:
    - "postgres"
    - "-c"
    - "max_connections=200"
    - "-c"
    - "shared_buffers=256MB"
    - "-c"
    - "wal_level=replica"
    - "-c"
    - "max_wal_senders=10"
    - "-c"
    - "synchronous_commit=off"
  ports:
    - "5434:5432"
  volumes:
    - postgres_data:/var/lib/postgresql/data
    - ./scripts/setup-replication.sh:/docker-entrypoint-initdb.d/setup-replication.sh:ro
  networks:
    - gridtokenx-network
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U gridtokenx_user -d gridtokenx"]
    interval: 10s
    timeout: 5s
    retries: 5

# Replica PostgreSQL
postgres-replica:
  image: postgres:17-alpine
  container_name: gridtokenx-postgres-replica
  environment:
    POSTGRES_DB: gridtokenx
    POSTGRES_USER: gridtokenx_user
    POSTGRES_PASSWORD: gridtokenx_password
    PRIMARY_HOST: postgres
  entrypoint: ["/bin/sh", "/scripts/init-replica.sh"]
  ports:
    - "5433:5432"
  volumes:
    - postgres_replica_data:/var/lib/postgresql/data
    - ./scripts/init-replica.sh:/scripts/init-replica.sh:ro
  networks:
    - gridtokenx-network
  depends_on:
    postgres:
      condition: service_healthy
```

### Redis with Replication

```yaml
# Primary Redis
redis:
  image: redis:7-alpine
  container_name: gridtokenx-redis
  ports:
    - "6379:6379"
  volumes:
    - redis_data:/data
  networks:
    - gridtokenx-network
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 3s
    retries: 5

# Redis Replica
redis-replica:
  image: redis:7-alpine
  container_name: gridtokenx-redis-replica
  command: redis-server --replicaof redis 6379
  ports:
    - "6380:6379"
  volumes:
    - redis_replica_data:/data
  networks:
    - gridtokenx-network
  depends_on:
    - redis
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 3s
    retries: 5
```

### InfluxDB Configuration

```yaml
influxdb:
  image: influxdb:2.7-alpine
  container_name: gridtokenx-influxdb
  ports:
    - "8086:8086"
  environment:
    DOCKER_INFLUXDB_INIT_MODE: setup
    DOCKER_INFLUXDB_INIT_USERNAME: gridtokenx_user
    DOCKER_INFLUXDB_INIT_PASSWORD: gridtokenx_password
    DOCKER_INFLUXDB_INIT_ORG: gridtokenx
    DOCKER_INFLUXDB_INIT_BUCKET: energy_readings
    DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: your-influxdb-token
  volumes:
    - influxdb_data:/var/lib/influxdb2
    - influxdb_config:/etc/influxdb2
  networks:
    - gridtokenx-network
  restart: unless-stopped
  healthcheck:
    test: "curl -f http://localhost:8086/health || exit 1"
    interval: 30s
    timeout: 10s
    retries: 5
```

## Kafka Configuration (KRaft Mode)

```yaml
kafka:
  image: apache/kafka:3.7.0
  container_name: gridtokenx-kafka
  ports:
    - "9092:9092"
    - "29092:29092"
  environment:
    TZ: UTC
    # KRaft Configuration (No Zookeeper needed)
    KAFKA_NODE_ID: 1
    KAFKA_PROCESS_ROLES: broker,controller
    KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
    KAFKA_LISTENERS: PLAINTEXT://:9092,PLAINTEXT_HOST://:29092,CONTROLLER://:9093
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092
    KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
    KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
    KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
    # Topic Configuration
    KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
    KAFKA_NUM_PARTITIONS: 3
    KAFKA_DEFAULT_REPLICATION_FACTOR: 1
    # Performance
    KAFKA_LOG_RETENTION_HOURS: 168
    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    # Cluster ID for KRaft
    CLUSTER_ID: "MkU3OEVBNTcwNTJENDM2Qk"
  volumes:
    - kafka_data:/var/lib/kafka/data
  networks:
    - gridtokenx-network
  restart: unless-stopped
  healthcheck:
    test: ["CMD-SHELL", "/opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 5
    start_period: 30s
```

## Monitoring Stack

### Prometheus Configuration

```yaml
prometheus:
  image: prom/prometheus:latest
  container_name: gridtokenx-prometheus
  volumes:
    - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus_data:/prometheus
  ports:
    - "9090:9090"
  networks:
    - gridtokenx-network
  restart: unless-stopped
```

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'api-gateway'
    static_configs:
      - targets: ['api-gateway:4001']
    metrics_path: '/metrics'
  
  - job_name: 'trading-service'
    static_configs:
      - targets: ['trading-service:8092']
    metrics_path: '/metrics'
  
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']
  
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```

### Grafana Configuration

```yaml
grafana:
  image: grafana/grafana:latest
  container_name: gridtokenx-grafana
  volumes:
    - grafana_data:/var/lib/grafana
    - ./grafana/provisioning:/etc/grafana/provisioning
  ports:
    - "3001:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin
    - GF_USERS_ALLOW_SIGN_UP=false
  networks:
    - gridtokenx-network
  depends_on:
    - prometheus
  restart: unless-stopped
```

### Mailpit (Email Testing)

```yaml
mailpit:
  image: axllent/mailpit:latest
  container_name: gridtokenx-mailpit
  ports:
    - "1025:1025"  # SMTP
    - "8025:8025"  # Web UI
  environment:
    MP_MAX_MESSAGES: 5000
    MP_DATABASE: /data/mailpit.db
    MP_SMTP_AUTH_ACCEPT_ANY: 1
    MP_SMTP_AUTH_ALLOW_INSECURE: 1
  volumes:
    - mailpit_data:/data
  networks:
    - gridtokenx-network
  restart: unless-stopped
  healthcheck:
    test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8025/api/v1/info"]
    interval: 30s
    timeout: 10s
    retries: 3
```

## Network Configuration

```yaml
networks:
  gridtokenx-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

## Volume Management

```yaml
volumes:
  postgres_data:
    driver: local
  postgres_replica_data:
    driver: local
  redis_data:
    driver: local
  redis_replica_data:
    driver: local
  influxdb_data:
    driver: local
  kafka_data:
    driver: local
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
  mailpit_data:
    driver: local
```

## Service-specific configurations

### API Gateway

```yaml
api-gateway:
  build:
    context: ./
    dockerfile: gridtokenx-api/Dockerfile
  container_name: gridtokenx-api-gateway
  ports:
    - "4000:4001"
  environment:
    DATABASE_URL: postgresql://gridtokenx_user:gridtokenx_password@postgres:5432/gridtokenx
    REDIS_URL: redis://redis:6379
    INFLUXDB_URL: http://influxdb:8086
    KAFKA_BOOTSTRAP_SERVERS: kafka:9092
    SOLANA_RPC_URL: http://host.docker.internal:8899
    JWT_SECRET: ${JWT_SECRET}
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
    kafka:
      condition: service_healthy
  networks:
    - gridtokenx-network
  extra_hosts:
    - "host.docker.internal:host-gateway"
  restart: unless-stopped
```

### Kong API Gateway

```yaml
kong:
  image: kong/kong-gateway:latest
  container_name: gridtokenx-kong
  environment:
    KONG_DATABASE: "off"
    KONG_DECLARATIVE_CONFIG: /usr/local/kong/declarative/kong.yml
    KONG_PROXY_ACCESS_LOG: /dev/stdout
    KONG_ADMIN_ACCESS_LOG: /dev/stdout
    KONG_PROXY_ERROR_LOG: /dev/stderr
    KONG_ADMIN_ERROR_LOG: /dev/stderr
    KONG_ADMIN_LISTEN: 0.0.0.0:8001
    KONG_PROXY_LISTEN: 0.0.0.0:4000
  ports:
    - "4000:4000"
    - "8001:8001"
  volumes:
    - ./docker/kong/kong.yml:/usr/local/kong/declarative/kong.yml:ro
  networks:
    - gridtokenx-network
  depends_on:
    - postgres
    - redis
  restart: unless-stopped
```

## Common operations

### Start services

```bash
# Start all services
docker-compose up -d

# Start specific services
docker-compose up -d postgres redis

# Start with rebuild
docker-compose up -d --build

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f api-gateway
```

### Stop services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v

# Stop specific service
docker-compose stop postgres
```

### Service management

```bash
# Check service status
docker-compose ps

# Restart service
docker-compose restart api-gateway

# View service logs
docker-compose logs --tail=100 postgres

# Execute command in container
docker-compose exec postgres psql -U gridtokenx_user -d gridtokenx
```

### Health checks

```bash
# Check PostgreSQL
docker exec gridtokenx-postgres pg_isready -U gridtokenx_user -d gridtokenx

# Check Redis
docker exec gridtokenx-redis redis-cli ping

# Check Kafka
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Check InfluxDB
curl http://localhost:8086/health
```

## Database operations

### PostgreSQL backup

```bash
# Backup database
docker exec gridtokenx-postgres \
  pg_dump -U gridtokenx_user gridtokenx > backup.sql

# Restore database
docker exec -i gridtokenx-postgres \
  psql -U gridtokenx_user gridtokenx < backup.sql
```

### PostgreSQL maintenance

```bash
# Vacuum database
docker exec gridtokenx-postgres \
  psql -U gridtokenx_user -d gridtokenx -c "VACUUM ANALYZE"

# Check database size
docker exec gridtokenx-postgres \
  psql -U gridtokenx_user -d gridtokenx -c "SELECT pg_size_pretty(pg_database_size('gridtokenx'))"

# List tables
docker exec gridtokenx-postgres \
  psql -U gridtokenx_user -d gridtokenx -c "\dt"
```

### Redis operations

```bash
# Connect to Redis
docker exec -it gridtokenx-redis redis-cli

# View all keys
docker exec gridtokenx-redis redis-cli KEYS '*'

# Clear all data
docker exec gridtokenx-redis redis-cli FLUSHALL

# Check memory usage
docker exec gridtokenx-redis redis-cli INFO memory
```

### Kafka operations

```bash
# List topics
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Create topic
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create --topic meter-readings \
  --partitions 3 --replication-factor 1

# Consume messages
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic meter-readings --from-beginning

# Check consumer groups
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --list
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs <service>

# Check disk space
df -h

# Check Docker daemon
docker info

# Remove and recreate
docker-compose rm -f <service>
docker-compose up -d <service>
```

### Port conflicts

```bash
# Find process using port
lsof -i :5432

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Volume issues

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect gridtokenx-postgres_data

# Remove volume (WARNING: deletes data)
docker volume rm gridtokenx-postgres_data
```

### Network issues

```bash
# List networks
docker network ls

# Inspect network
docker network inspect gridtokenx-network

# Reconnect container
docker network disconnect gridtokenx-network <container>
docker network connect gridtokenx-network <container>
```

### Performance issues

```bash
# Check container stats
docker stats

# Check container logs for errors
docker-compose logs --tail=1000 <service>

# Restart service
docker-compose restart <service>

# Increase resource limits in docker-compose.yml
```

## Production deployment

### Environment-specific overrides

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G
    environment:
      POSTGRES_PASSWORD: ${PROD_DB_PASSWORD}
  
  api-gateway:
    environment:
      ENVIRONMENT: production
      JWT_SECRET: ${PROD_JWT_SECRET}
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 2G
```

### Deploy with production config

```bash
docker-compose \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  --env-file .env.production \
  up -d
```

## Security considerations

### Secrets management

```yaml
# Use Docker secrets or environment files
services:
  api-gateway:
    environment:
      JWT_SECRET: ${JWT_SECRET}  # From .env file
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Network isolation

```yaml
# Create separate networks for different tiers
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
  database:
    driver: bridge

services:
  api-gateway:
    networks:
      - frontend
      - backend
  
  trading-service:
    networks:
      - backend
      - database
  
  postgres:
    networks:
      - database  # Only accessible from backend
```

## Related resources

- [Docker Services Workflow](../workflows/docker-services.md)
- [Database Migrations Workflow](../workflows/database-migrations.md)
- [Monitoring Workflow](../workflows/monitoring.md)
- [Debugging Workflow](../workflows/debugging.md)
