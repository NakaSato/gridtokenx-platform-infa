---
description: Monitor GridTokenX services and metrics
---

# Monitoring & Observability

Monitor GridTokenX services using Prometheus, Grafana, and built-in metrics.

## Quick Access

// turbo

```bash
# Start monitoring stack
docker-compose up -d prometheus grafana promtail

# Access dashboards
# Grafana: http://localhost:3001 (admin/admin)
# Prometheus: http://localhost:9090
```

## Monitoring Stack

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| Prometheus | 9090 | http://localhost:9090 | Metrics collection |
| Grafana | 3001 | http://localhost:3001 | Visualization |
| Mailpit | 8025 | http://localhost:8025 | Email monitoring |

## Prometheus Metrics

### Accessing Prometheus

Open http://localhost:9090

### Available Metrics

```promql
# API Gateway requests
http_requests_total{service="api-gateway"}

# Request latency
http_request_duration_seconds{service="api-gateway"}

# Database connections
db_pool_connections{service="api-gateway"}

# Redis operations
redis_operations_total{service="api-gateway"}

# Trading orders
trading_orders_total{status="pending"}
trading_orders_total{status="matched"}

# Smart meter readings
meter_readings_total{type="consumption"}
meter_readings_total{type="generation"}

# Blockchain transactions
solana_transactions_total{status="success"}
```

### Custom Queries

```promql
# Request rate per second
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Database pool utilization
db_pool_active / db_pool_max

# Trading volume
sum(trading_orders_total{status="matched"})
```

## Grafana Dashboards

### Accessing Grafana

Open http://localhost:3001
- Username: `admin`
- Password: `admin`

### Built-in Dashboards

| Dashboard | Description |
|-----------|-------------|
| API Gateway | Request metrics, latency, errors |
| Trading | Order flow, matching, settlement |
| Smart Meters | Energy readings, tokenization |
| Blockchain | Transaction stats, program calls |
| Database | Connection pool, query performance |
| System | CPU, memory, disk, network |

### Creating Custom Dashboards

1. Open Grafana (http://localhost:3001)
2. Click "Create" → "Dashboard"
3. Add panels with Prometheus queries
4. Save dashboard

### Example Panel Queries

**Request Rate**:
```promql
sum(rate(http_requests_total[1m]))
```

**Error Rate**:
```promql
sum(rate(http_requests_total{status=~"5.."}[1m]))
```

**Active Users**:
```promql
count(active_sessions)
```

## Application Logs

### Structured Logging

GridTokenX uses JSON structured logging:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "service": "api-gateway",
  "message": "Request processed",
  "method": "POST",
  "path": "/api/v1/orders",
  "status": 200,
  "duration_ms": 45
}
```

### Log Levels

| Level | Description |
|-------|-------------|
| ERROR | Critical errors requiring attention |
| WARN | Potential issues, degraded functionality |
| INFO | Normal operations, key events |
| DEBUG | Detailed debugging information |
| TRACE | Very detailed trace information |

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api-gateway

# Filter by level
docker logs gridtokenx-api-gateway 2>&1 | grep '"level":"ERROR"'

# Last N lines
docker-compose logs --tail=100 api-gateway
```

### Log Aggregation

Configure log shipping to external systems:

```yaml
# docker-compose.yml
services:
  api-gateway:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## Health Checks

### Service Health Endpoints

```bash
# API Gateway
curl http://localhost:4000/health

# Trading Service
curl http://localhost:8092/health

# IAM Service
curl http://localhost:8080/health

# Smart Meter API
curl http://localhost:8082/health
```

### Health Check Response

```json
{
  "status": "healthy",
  "checks": {
    "database": "healthy",
    "redis": "healthy",
    "blockchain": "healthy",
    "kafka": "healthy"
  },
  "uptime_seconds": 86400
}
```

### Docker Health Checks

```bash
# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# Specific health check
docker inspect --format='{{.State.Health.Status}}' gridtokenx-postgres
```

## Alerting

### Prometheus Alert Rules

Create `prometheus/alerts.yml`:

```yaml
groups:
  - name: gridtokenx
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 5m
        annotations:
          summary: High error rate detected

      - alert: DatabaseDown
        expr: db_pool_available == 0
        for: 1m
        annotations:
          summary: Database connection pool exhausted

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        annotations:
          summary: P95 latency above 1 second
```

### Grafana Alerts

1. Open panel in Grafana
2. Click "Alert" tab
3. Create alert rule
4. Configure notification channel

## Performance Metrics

### Key Metrics to Monitor

| Metric | Threshold | Alert Level |
|--------|-----------|-------------|
| Error Rate | > 1% | Critical |
| P95 Latency | > 500ms | Warning |
| P99 Latency | > 1s | Critical |
| DB Pool Usage | > 80% | Warning |
| Memory Usage | > 85% | Warning |
| Disk Usage | > 90% | Critical |
| Trading Order Lag | > 5s | Warning |

### Trading-Specific Metrics

```promql
# Order matching latency
trading_order_match_duration_seconds

# Settlement success rate
settlement_transactions_total{status="success"} / settlement_transactions_total

# Price feed freshness
time() - oracle_price_update_timestamp
```

## Distributed Tracing

### Trace Context

GridTokenX propagates trace context via headers:

```
X-Trace-ID: <unique-trace-id>
X-Span-ID: <span-id>
```

### Viewing Traces

```bash
# Enable trace logging
export RUST_LOG=trace

# View trace in logs
docker logs api-gateway | grep "trace_id"
```

## Related Workflows

- [Debugging](./debugging.md) - Troubleshoot issues
- [Docker Services](./docker-services.md) - Manage containers
- [Start Development](./start-dev.md) - Start monitoring stack
