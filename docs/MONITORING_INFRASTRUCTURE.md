# Infrastructure Monitoring & Alerting Setup

This document describes the infrastructure monitoring and alerting stack for the GridTokenX platform.

## Overview

The monitoring stack uses the **Prometheus + Grafana + Alertmanager** ecosystem to collect, store, visualize, and alert on metrics from all platform services.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Exporters Layer                              │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────┤
│  PostgreSQL │    Redis    │    Kafka    │    Node     │ cAdvisor│
│  Exporter   │   Exporter  │   Exporter  │   Exporter  │         │
│   :9187     │    :9121    │    :9308    │    :9100    │  :8080  │
└──────┬──────┴──────┬──────┴──────┬──────┴──────┬──────┴────┬────┘
       │             │             │             │           │
       └─────────────┴─────────────┴─────────────┴───────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Prometheus    │
                    │     :9090       │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                              ▼
     ┌─────────────────┐          ┌─────────────────┐
     │     Grafana     │          │  Alertmanager   │
     │     :3001       │          │     :9093       │
     └─────────────────┘          └────────┬────────┘
                                           │
                                           ▼
                                   ┌─────────────────┐
                                   │    Mailpit      │
                                   │     :8025       │
                                   └─────────────────┘
```

## Services

### Exporters

| Service | Container Name | Port | Description |
|---------|---------------|------|-------------|
| **PostgreSQL Exporter** | `gridtokenx-postgres-exporter` | 9187 | Database metrics (connections, transactions, replication) |
| **Redis Exporter** | `gridtokenx-redis-exporter` | 9121 | Cache metrics (memory, hit rate, clients) |
| **Kafka Exporter** | `gridtokenx-kafka-exporter` | 9308 | Message queue metrics (lag, offsets, partitions) |
| **Node Exporter** | `gridtokenx-node-exporter` | 9100 | Host system metrics (CPU, memory, disk, network) |
| **cAdvisor** | `gridtokenx-cadvisor` | 8080 | Container metrics (CPU, memory, network per container) |

### Alerting Services

| Service | Container Name | Port | Description |
|---------|---------------|------|-------------|
| **Alertmanager** | `gridtokenx-alertmanager` | 9093 | Alert routing, deduplication, silencing, notification |

### Application Metrics

| Service | Endpoint | Port | Description |
|---------|----------|------|-------------|
| **API Gateway Node 1** | `/metrics` | 4001 | HTTP requests, latency, errors, blockchain ops |
| **API Gateway Node 2** | `/metrics` | 4002 | HTTP requests, latency, errors, blockchain ops |
| **Smart Meter Simulator** | `/metrics` | 8082 | Simulation metrics, data generation |

## Quick Start

> ⚠️ **Prerequisite**: OrbStack must be running. See [OrbStack Setup](./ORBSTACK_MIGRATION.md).

### Start Monitoring Stack

```bash
# Start all services including monitoring
docker compose up -d

# Start only monitoring services
docker compose up -d prometheus grafana alertmanager postgres-exporter redis-exporter kafka-exporter node-exporter cadvisor
```

### Access Dashboards

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3001 | admin / admin |
| **Prometheus** | http://localhost:9090 | - |
| **Alertmanager** | http://localhost:9093 | - |
| **cAdvisor UI** | http://localhost:8080 | - |

## Metrics Collected

### Host Metrics (Node Exporter)
- CPU usage per core
- Memory usage and availability
- Disk usage and I/O
- Network traffic
- System load
- Uptime

### Container Metrics (cAdvisor)
- CPU usage per container
- Memory usage per container
- Network I/O per container
- Container restarts
- Filesystem usage

### Database Metrics (PostgreSQL Exporter)
- Transactions per second (commit/rollback)
- Active connections by state
- Query duration (pg_stat_statements)
- Lock waits
- Replication lag
- Table sizes and row counts
- Cache hit ratio

### Cache Metrics (Redis Exporter)
- Memory usage
- Connected clients
- Cache hit/miss ratio
- Operations per second
- Keyspace statistics
- Slow queries
- Network I/O

### Message Queue Metrics (Kafka Exporter)
- Topic partition offsets
- Consumer group lag
- Broker availability
- Under-replicated partitions
- Request rates

## Alerting

### Alert Rules

Alerts are organized into the following categories:

#### Infrastructure Alerts (`infrastructure`)
| Alert Name | Severity | Condition | Description |
|------------|----------|-----------|-------------|
| `HighCPUUsage` | Warning | CPU > 80% for 5m | Host CPU usage is high |
| `CriticalCPUUsage` | Critical | CPU > 95% for 2m | Host CPU usage is critical |
| `HighMemoryUsage` | Warning | Memory > 80% for 5m | Host memory usage is high |
| `CriticalMemoryUsage` | Critical | Memory > 95% for 2m | Host memory usage is critical |
| `HighDiskUsage` | Warning | Disk > 80% | Host disk usage is high |
| `CriticalDiskUsage` | Critical | Disk > 90% | Host disk usage is critical |
| `NodeDown` | Critical | Node exporter down for 1m | Node exporter is unreachable |

#### Container Alerts (`containers`)
| Alert Name | Severity | Condition | Description |
|------------|----------|-----------|-------------|
| `ContainerHighCPU` | Warning | CPU > 80% for 5m | Container CPU usage is high |
| `ContainerHighMemory` | Warning | Memory > 80% for 5m | Container memory usage is high |
| `ContainerRestarted` | Warning | >2 restarts in 5m | Container has restarted frequently |

#### PostgreSQL Alerts (`postgresql`)
| Alert Name | Severity | Condition | Description |
|------------|----------|-----------|-------------|
| `PostgreSQLDown` | Critical | Exporter down for 1m | PostgreSQL is unreachable |
| `PostgreSQLHighConnections` | Warning | >150 active connections | Too many active connections |
| `PostgreSQLReplicationLag` | Warning | Lag > 30s for 5m | Replication lag detected |
| `PostgreSQLCriticalReplicationLag` | Critical | Lag > 120s for 2m | Critical replication lag |
| `PostgreSQLHighTransactionRate` | Warning | >1000 tx/sec | High transaction rate |
| `PostgreSQLLockWaits` | Warning | >10 exclusive lock waits | Lock contention detected |

#### Redis Alerts (`redis`)
| Alert Name | Severity | Condition | Description |
|------------|----------|-----------|-------------|
| `RedisDown` | Critical | Exporter down for 1m | Redis is unreachable |
| `RedisHighMemory` | Warning | Memory > 80% for 5m | Redis memory usage is high |
| `RedisCriticalMemory` | Critical | Memory > 95% for 2m | Redis memory is critical |
| `RedisLowCacheHitRate` | Warning | Hit rate < 80% for 10m | Cache efficiency is low |
| `RedisTooManyConnections` | Warning | >1000 clients for 5m | Too many connected clients |
| `RedisEvictedKeys` | Warning | >100 evictions/sec | Memory pressure causing evictions |

#### Kafka Alerts (`kafka`)
| Alert Name | Severity | Condition | Description |
|------------|----------|-----------|-------------|
| `KafkaDown` | Critical | Exporter down for 1m | Kafka is unreachable |
| `KafkaConsumerLag` | Warning | Lag > 10,000 for 5m | Consumer lag detected |
| `KafkaCriticalConsumerLag` | Critical | Lag > 50,000 for 2m | Critical consumer lag |
| `KafkaUnderReplicatedPartitions` | Warning | Any under-replicated partitions | Data replication issue |
| `KafkaBrokerOffline` | Critical | No brokers available | Kafka broker is offline |

#### Application Alerts (`application`)
| Alert Name | Severity | Condition | Description |
|------------|----------|-----------|-------------|
| `APIGatewayDown` | Critical | Gateway down for 1m | API Gateway is unreachable |
| `HighErrorRate` | Warning | Error rate > 5% for 5m | High HTTP error rate |
| `CriticalErrorRate` | Critical | Error rate > 10% for 2m | Critical HTTP error rate |
| `HighLatency` | Warning | P99 latency > 1s for 5m | High request latency |
| `SmartMeterSimulatorDown` | Warning | Simulator down for 5m | Smart Meter Simulator is down |

### Notification Routing

Alerts are routed based on severity and service:

```
┌─────────────────────────────────────────────────────────────┐
│                      Alertmanager                            │
├─────────────────────────────────────────────────────────────┤
│  Routing Tree:                                              │
│                                                             │
│  default-receiver (alerts@gridtokenx.local)                │
│  ├── critical-receiver (oncall@gridtokenx.local)           │
│  │   └── severity = critical                               │
│  ├── warning-receiver (dev-team@gridtokenx.local)          │
│  │   └── severity = warning                                │
│  ├── database-receiver (dba-team@gridtokenx.local)         │
│  │   └── service = database                                │
│  └── infrastructure-receiver (infra-team@gridtokenx.local) │
│      └── service = infrastructure                          │
└─────────────────────────────────────────────────────────────┘
```

### Notification Timing

| Severity | Group Wait | Group Interval | Repeat Interval |
|----------|------------|----------------|-----------------|
| **Critical** | 10s | 1h | 1h |
| **Warning** | 1m | 2h | 2h |
| **Database** | 30s | 5m | 2h |
| **Infrastructure** | 30s | 5m | 2h |

### Inhibition Rules

- Critical alerts suppress warning alerts for the same alertname
- ServiceDown alerts suppress other alerts from that service

## Prometheus Configuration

Configuration file: `gridtokenx-api/docker/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

# Load alerting rules
rule_files:
  - '/etc/prometheus/rules/*.yml'

scrape_configs:
  # Application services (host.docker.internal)
  - job_name: 'apigateway-node1'
  - job_name: 'apigateway-node2'
  - job_name: 'smartmeter'
  
  # Infrastructure exporters (Docker network)
  - job_name: 'postgres'
  - job_name: 'redis'
  - job_name: 'kafka'
  - job_name: 'node'
  - job_name: 'cadvisor'
  
  # Self-monitoring
  - job_name: 'prometheus'
  - job_name: 'alertmanager'
```

## Grafana Dashboards

### Infrastructure Overview
**UID:** `infrastructure-overview`

A comprehensive dashboard showing:
- Host resource utilization (CPU, Memory, Disk)
- Active container count
- PostgreSQL transactions, connections, replication lag
- Redis memory, clients, cache hit rate
- Kafka topic offsets, consumer lag
- Container CPU and memory usage

### API Gateway Overview
**UID:** `apigateway`

Application-level metrics for the API gateway services.

### Redis Monitoring
**UID:** `redis-dashboard`

Detailed Redis performance metrics.

## Key Metrics Queries

### Host CPU Usage
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Memory Usage Percentage
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

### PostgreSQL Transactions per Second
```promql
sum(rate(pg_stat_database_xact_commit[5m])) + sum(rate(pg_stat_database_xact_rollback[5m]))
```

### Redis Cache Hit Rate
```promql
(redis_keyspace_hits_total / (redis_keyspace_hits_total + redis_keyspace_misses_total)) * 100
```

### Kafka Consumer Lag
```promql
sum(kafka_consumergroup_lag) by (consumergroup, topic)
```

### Container Memory Usage
```promql
container_memory_usage_bytes{container_label_org_label_schema_group!="", container_memory_usage_bytes != 0}
```

## Troubleshooting

### Exporters Not Scraping

1. Check exporter health:
```bash
curl http://localhost:9187/metrics  # PostgreSQL
curl http://localhost:9121/metrics  # Redis
curl http://localhost:9308/metrics  # Kafka
curl http://localhost:9100/metrics  # Node
curl http://localhost:8080/metrics  # cAdvisor
```

2. Check container logs:
```bash
docker-compose logs postgres-exporter
docker-compose logs redis-exporter
docker-compose logs kafka-exporter
```

### Prometheus Targets Down

1. Open Prometheus UI: http://localhost:9090/targets
2. Check which targets are down
3. Verify network connectivity between containers

### Alertmanager Not Sending Notifications

1. Check Alertmanager UI: http://localhost:9093
2. Verify mailpit is running: http://localhost:8025
3. Check Alertmanager logs: `docker-compose logs alertmanager`
4. Verify email configuration in `alertmanager.yml`

### Grafana Dashboards Not Loading

1. Verify Prometheus datasource is configured
2. Check Grafana logs: `docker-compose logs grafana`
3. Re-provision dashboards: restart Grafana container

### Testing Alerts

To test alerting, you can manually trigger an alert:

```bash
# Simulate high CPU (run inside a container)
yes > /dev/null &

# Or use Prometheus UI to test alert rules
# Go to http://localhost:9090/rules and check alert states
```

## Security Notes

⚠️ **Development Environment Only**: This configuration is for development/testing. For production:

1. Enable authentication on Grafana and Alertmanager
2. Use HTTPS/TLS for all endpoints
3. Restrict network access to exporters
4. Use secrets management for credentials
5. Enable Prometheus authentication
6. Configure proper RBAC in Grafana
7. Use secure email/SMTP configuration
8. Implement webhook authentication for external notifications

## File Structure

```
gridtokenx-api/docker/
├── prometheus/
│   ├── prometheus.yml          # Prometheus configuration
│   └── rules/
│       └── alerts.yml          # Alerting rules
├── alertmanager/
│   ├── alertmanager.yml        # Alertmanager configuration
│   └── templates/
│       └── default.tmpl        # Notification templates
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── datasource.yml  # Datasource configuration
        ├── dashboards/
        │   ├── dashboard.yml   # Dashboard provisioning
        │   ├── infrastructure.json
        │   ├── apigateway.json
        │   └── redis-dashboard.json
        └── alerting/
            └── alerts.yml      # Alert contact points & policies
```

## Next Steps

1. **Customize Notifications**: Update email addresses in `alertmanager.yml` for your team
2. **Add Webhooks**: Configure Slack, Teams, or PagerDuty webhooks for critical alerts
3. **Create Runbooks**: Add runbook URLs to alert annotations for incident response
4. **Define SLI/SLO**: Implement service level indicators and objectives
5. **Business Alerts**: Create alerts for business-level metrics (trading volume, user activity)

---

## Dashboard Improvements Changelog

### Platform Overview Dashboard
- ✅ Added proper Grafana annotations support
- ✅ Enhanced stat panels with better thresholds and color coding
- ✅ Added success rate monitoring (2xx + 3xx responses)
- ✅ Improved error rate tracking with proper 5xx detection
- ✅ Added HTTP status code distribution visualization
- ✅ Enhanced trading activity section with real metrics:
  - Orders created/matched rates
  - Blockchain operations tracking
  - Active DCA orders count
- ✅ Added blockchain performance section:
  - Average transaction time
  - Blockchain success rate
  - Transaction retry monitoring
  - Priority fee tracking
- ✅ Added authentication & security section:
  - Auth success rate
  - Auth failure monitoring
  - WebSocket connection tracking
  - Cache hit rate
- ✅ Updated to latest Grafana schema (v39)

### API Performance Dashboard
- ✅ Added comprehensive latency analysis (P50/P95/P99)
- ✅ Implemented endpoint and method filtering via template variables
- ✅ Added HTTP status code distribution (stacked area chart)
- ✅ Added active requests (in-flight) monitoring
- ✅ Added request rate by path (Top 10 endpoints)
- ✅ Implemented latency heatmap for distribution analysis
- ✅ Added latency by endpoint (P95) timeline
- ✅ Added top 15 slowest endpoints (bar chart with thresholds)
- ✅ Added top 15 most error-prone endpoints
- ✅ Added database & cache performance section

### Trading Operations Dashboard
- ✅ Added order flow rate (created/matched/settled)
- ✅ Added DCA order tracking
- ✅ Improved settlement latency tracking
- ✅ Added blockchain transaction correlation

### Infrastructure Dashboard
- ✅ Enhanced PostgreSQL metrics (connections, cache hit, transactions)
- ✅ Enhanced Redis metrics (memory, operations, hit rate)
- ✅ Enhanced Kafka metrics (messages, topics, consumer lag)
- ✅ Added container resource utilization

### Blockchain Monitor Dashboard
- ✅ Added transaction success rate tracking
- ✅ Added average confirmation time monitoring
- ✅ Added priority fee tracking
- ✅ Added program call volume metrics
