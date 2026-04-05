---
description: Debug and troubleshoot GridTokenX services
---

# Debugging & Troubleshooting

Debug and troubleshoot issues across GridTokenX services.

## Quick Diagnostics

// turbo

```bash
# Check system status
./scripts/app.sh status

# Run system doctor
./scripts/app.sh doctor

# View all logs
docker-compose logs -f
```

## Service Health Checks

### API Gateway

```bash
# Health endpoint
curl http://localhost:4000/health

# Check API version
curl http://localhost:4000/api/v1/version

# Test database connection
curl http://localhost:4000/api/v1/admin/health/db
```

### Blockchain

```bash
# Solana RPC health
curl http://localhost:8899/health

# Get cluster version
solana cluster-version --url http://localhost:8899

# Get balance
solana balance --url http://localhost:8899
```

### Database

```bash
# PostgreSQL health
docker exec gridtokenx-postgres pg_isready -U gridtokenx_user

# Redis health
docker exec gridtokenx-redis redis-cli ping

# InfluxDB health
curl http://localhost:8086/health
```

## Log Analysis

### View Service Logs

```bash
# API Gateway
docker logs -f gridtokenx-api-gateway

# All Rust services
docker logs -f gridtokenx-iam-service
docker logs -f gridtokenx-trading-service

# Smart Meter Simulator
docker logs -f gridtokenx-smartmeter-simulator

# Solana Validator
tail -f scripts/logs/validator.log
```

### Filter Logs by Level

```bash
# Error logs only
docker logs gridtokenx-api-gateway 2>&1 | grep ERROR

# Warning logs
docker logs gridtokenx-api-gateway 2>&1 | grep WARN
```

### Real-time Log Streaming

```bash
# All services
docker-compose logs -f

# Specific services
docker-compose logs -f api-gateway postgres redis
```

## Common Issues

### 1. Database Connection Errors

**Symptoms**: API returns 500, connection timeout

**Diagnosis**:
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Test connection
docker exec gridtokenx-postgres \
  psql -U gridtokenx_user -d gridtokenx -c "SELECT 1"

# Check connection pool
docker logs gridtokenx-api-gateway | grep pool
```

**Fix**:
```bash
# Restart PostgreSQL
docker-compose restart postgres

# Check DATABASE_URL
echo $DATABASE_URL

# Verify migrations
cd gridtokenx-api
sqlx migrate info
```

### 2. Redis Connection Errors

**Symptoms**: Cache misses, session errors

**Diagnosis**:
```bash
# Check Redis is running
docker exec gridtokenx-redis redis-cli ping

# Check memory usage
docker exec gridtokenx-redis redis-cli INFO memory
```

**Fix**:
```bash
# Restart Redis
docker-compose restart redis

# Clear cache
docker exec gridtokenx-redis redis-cli FLUSHALL
```

### 3. Solana Validator Issues

**Symptoms**: Transaction failures, RPC timeout

**Diagnosis**:
```bash
# Check validator is running
ps aux | grep solana-test-validator

# Check RPC endpoint
curl http://localhost:8899/health

# Check logs
tail -f scripts/logs/validator.log
```

**Fix**:
```bash
# Restart validator
pkill -f solana-test-validator
solana-test-validator --reset --ledger ./test-ledger

# Fund wallets
solana airdrop 100 <WALLET_ADDRESS> --url http://localhost:8899
```

### 4. Kafka Message Backlog

**Symptoms**: Delayed processing, high latency

**Diagnosis**:
```bash
# Check consumer lag
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe --group gridtokenx-apigateway

# Check topic stats
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-run-class.sh \
  kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic meter-readings
```

**Fix**:
```bash
# Restart consumer
docker-compose restart api-gateway

# Increase consumers
# Edit docker-compose.yml to add more consumer instances
```

### 5. High Memory Usage

**Symptoms**: Slow responses, OOM errors

**Diagnosis**:
```bash
# Check container memory
docker stats

# Check Rust service memory
ps aux | grep api-gateway
```

**Fix**:
```bash
# Restart service
docker-compose restart api-gateway

# Increase memory limits in docker-compose.yml
# Or reduce connection pool sizes
```

### 6. Port Conflicts

**Symptoms**: Service won't start, address already in use

**Diagnosis**:
```bash
# Find process using port
lsof -i :4000
lsof -i :5432
lsof -i :8899
```

**Fix**:
```bash
# Kill conflicting process
kill -9 <PID>

# Or change port in docker-compose.yml
```

## Debugging Tools

### Rust Service Debugging

```bash
# Enable debug logging
export RUST_LOG=debug
docker-compose restart api-gateway

# Run with backtrace
export RUST_BACKTRACE=1
cargo run --bin api-gateway
```

### Database Query Debugging

```bash
# Enable query logging
docker exec gridtokenx-postgres psql \
  -U gridtokenx_user -d gridtokenx \
  -c "SET log_min_duration_statement = 0"

# View slow queries
docker logs gridtokenx-postgres | grep duration
```

### Blockchain Debugging

```bash
# Enable Anchor debug logging
export ANCHOR_DEBUG=1
anchor test

# Check program logs
solana logs --url http://localhost:8899
```

### Network Debugging

```bash
# Check network connectivity
docker network inspect gridtokenx-network

# Test inter-container communication
docker exec gridtokenx-api-gateway \
  curl -v http://postgres:5432

# Check DNS resolution
docker exec gridtokenx-api-gateway \
  getent hosts postgres
```

## Performance Profiling

### CPU Profiling

```bash
# Install cargo-flamegraph
cargo install flamegraph

# Run with profiling
cd gridtokenx-api
flamegraph --bin api-gateway
```

### Memory Profiling

```bash
# Install cargo-heaptrack
cargo install heaptrack

# Run with profiling
heaptrack cargo run --bin api-gateway
```

### Database Query Analysis

```bash
# Enable pg_stat_statements
docker exec gridtokenx-postgres psql \
  -U gridtokenx_user -d gridtokenx \
  -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10"
```

## Remote Debugging

### Attach Debugger to Running Service

```bash
# Find process ID
ps aux | grep api-gateway

# Attach GDB
gdb -p <PID>
```

### Docker Exec for Debugging

```bash
# Enter running container
docker exec -it gridtokenx-api-gateway bash

# Run commands inside container
docker exec -it gridtokenx-api-gateway \
  curl -v http://localhost:4001/health
```

## Related Workflows

- [Testing](./testing.md) - Run tests to verify fixes
- [Docker Services](./docker-services.md) - Manage containers
- [Start Development](./start-dev.md) - Restart services
