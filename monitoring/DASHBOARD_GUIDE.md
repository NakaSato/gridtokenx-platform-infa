# GridTokenX Platform - Complete Monitoring Dashboard Guide

## 📊 Overview

This document provides a comprehensive guide to all monitoring dashboards and alerting rules for the GridTokenX P2P Energy Trading Platform.

---

## 🎯 Dashboard Index

### Core Platform Dashboards

| Dashboard | File | Description | Refresh |
|-----------|------|-------------|---------|
| **Platform Overview** | `platform-overview.json` | Main health dashboard - service health, requests, latency, errors | 30s |
| **API Performance** | `api-performance.json` | API Gateway metrics - latency, throughput, endpoint analysis | 15s |
| **Trading Operations** | `trading-operations.json` | Trading engine - orders, matching, settlement, market activity | 10s |
| **Blockchain Monitor** | `blockchain-monitor.json` | Solana interactions - transactions, program calls, RPC | 30s |
| **Infrastructure** | `infrastructure.json` | DB, cache, queue, containers - PostgreSQL, Redis, Kafka | 30s |

### Service-Specific Dashboards

| Dashboard | File | Description | Refresh |
|-----------|------|-------------|---------|
| **IAM Service Monitor** | `iam-service-monitor.json` | Auth, sessions, JWT, user management, security events | 30s |
| **Smart Meter & IoT** | `smartmeter-iot-monitor.json` | Meter readings, IoT devices, oracle bridge, data ingestion | 30s |
| **Energy Token & REC** | `energy-token-rec-monitor.json` | Token minting, transfers, REC lifecycle, certification | 30s |
| **Governance & Voting** | `governance-voting-monitor.json` | DAO proposals, voting, execution, participation | 30s |
| **VPP Monitor** | `vpp-monitor.json` | Virtual Power Plant - assets, dispatch, grid services, SOC | 30s |
| **Settlement Health** | `settlement-health.json` | On-chain settlement - batching, fees, Solana latency | 10s |

### Analytics & Security Dashboards

| Dashboard | File | Description | Refresh |
|-----------|------|-------------|---------|
| **User Analytics** | `user-analytics-activity.json` | User behavior, engagement, retention, cohorts | 1m |
| **Security & Audit** | `security-audit-monitor.json` | Threat detection, audit logs, compliance, incidents | 1m |

---

## 📁 Dashboard Locations

All dashboards are located in:
```
docker/signoz/dashboards/
├── platform-overview.json
├── api-performance.json
├── trading-operations.json
├── blockchain-monitor.json
├── infrastructure.json
├── iam-service-monitor.json
├── smartmeter-iot-monitor.json
├── energy-token-rec-monitor.json
├── governance-voting-monitor.json
├── vpp-monitor.json
├── settlement-health.json
├── user-analytics-activity.json
└── security-audit-monitor.json
```

---

## 🚨 Alerting Rules

### Location
```
monitoring/gridtokenx-alerts.yml
```

### Alert Categories

| Category | Alerts | Severity Levels |
|----------|--------|-----------------|
| **API Gateway** | 5 | Critical, Warning |
| **IAM Service** | 4 | Critical, Warning |
| **Trading Service** | 5 | Critical, Warning |
| **Oracle Bridge** | 6 | Critical, Warning |
| **Blockchain** | 5 | Critical, Warning |
| **Energy Token** | 3 | Critical, Warning |
| **VPP** | 4 | Critical, Warning |
| **Governance** | 3 | Critical, Warning, Info |
| **Infrastructure** | 8 | Critical, Warning |
| **Security** | 5 | Critical, Warning |
| **System Resources** | 4 | Critical, Warning |

**Total: 52 alerting rules**

### Alert Severity Definitions

| Severity | Response Time | Description |
|----------|---------------|-------------|
| **Critical** | Immediate | Service is down or severely degraded. Requires immediate action. |
| **Warning** | < 1 hour | Service is experiencing issues. Investigation needed. |
| **Info** | < 24 hours | Informational alerts for tracking trends. |

---

## 🔧 Setup Instructions

### Step 1: Import Dashboards to SigNoz

1. **Start the platform:**
   ```bash
   ./scripts/app.sh start
   ```

2. **Access SigNoz UI:**
   - URL: http://localhost:3030
   - Wait for health check: `curl http://localhost:3030/api/v1/health`

3. **Import each dashboard:**
   - Navigate to **Dashboards** → **Create Dashboard** → **Import Dashboard**
   - Upload each JSON file from `docker/signoz/dashboards/`
   - Select your data source (SigNoz/ClickHouse)
   - Click **Import**

4. **Verify dashboards:**
   - All dashboards should show data within 5-10 minutes
   - Check that variables (dropdowns) are populated

### Step 2: Configure Alerting Rules

1. **Copy alert rules to Prometheus:**
   ```bash
   cp monitoring/gridtokenx-alerts.yml /path/to/prometheus/rules/
   ```

2. **Update prometheus.yml:**
   ```yaml
   rule_files:
     - "rules/gridtokenx-alerts.yml"
   
   alerting:
     alertmanagers:
       - static_configs:
           - targets:
             - alertmanager:9093
   ```

3. **Reload Prometheus:**
   ```bash
   curl -X POST http://localhost:9090/-/reload
   ```

4. **Verify rules are loaded:**
   ```bash
   curl http://localhost:9090/api/v1/rules | grep gridtokenx
   ```

### Step 3: Configure Alertmanager (Optional)

Create `docker/alertmanager/alertmanager.yml`:

```yaml
global:
  smtp_smarthost: 'mailpit:1025'
  smtp_from: 'alertmanager@gridtokenx.com'

route:
  group_by: ['alertname', 'severity', 'team']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default-receiver'
  
  routes:
    - match:
        severity: critical
      receiver: 'critical-team'
      continue: true
    - match:
        team: security
      receiver: 'security-team'

receivers:
  - name: 'default-receiver'
    email:
      to: 'platform-team@gridtokenx.com'
  - name: 'critical-team'
    email:
      to: 'oncall@gridtokenx.com'
    pagerduty:
      service_key: '<pagerduty-key>'
  - name: 'security-team'
    email:
      to: 'security@gridtokenx.com'
```

---

## 📊 Dashboard Details

### 1. Platform Overview (`platform-overview.json`)

**Purpose:** High-level health check of all GridTokenX services

**Key Panels:**
- Service Health Overview (error count in 5m)
- Total Requests (5m)
- Global Avg Latency (ms)
- Error Rate (%)
- Request Rate by Service
- Latency Percentiles (P50, P95, P99)
- Error Rate by Service
- Slowest Endpoints (Top 10)
- Trading Activity
- Blockchain Operations
- Service Dependency Map
- Recent Errors

**Variables:**
- `service`: Filter by service name
- `time_range`: 15m, 30m, 1h, 2h, 6h, 12h, 24h

---

### 2. API Performance (`api-performance.json`)

**Purpose:** Deep dive into API Gateway performance

**Key Panels:**
- API Requests Per Second
- Latency Heatmap
- Endpoint Latency Comparison
- Endpoint Error Rates
- HTTP Status Code Distribution
- HTTP Method Distribution
- Latency Percentiles Trend
- Slowest Traces
- User Activity (Top 10)
- Latency Distribution by Quartile

**Variables:**
- `endpoint`: Filter by API endpoint
- `http_method`: GET, POST, PUT, PATCH, DELETE

---

### 3. Trading Operations (`trading-operations.json`)

**Purpose:** Monitor trading engine performance and market activity

**Key Panels:**
- Trading KPIs (Total Orders, Matched, Settlements, Avg Match Time)
- Order Flow Timeline
- Order Book Activity (Bid/Ask)
- Trading Latency Breakdown
- Market Pairs Activity
- Order Status Distribution
- Trading Errors
- Settlement Success Rate
- Active DCA Orders
- Matching Engine Throughput
- Order Lifecycle Traces

**Variables:**
- `market_pair`: Filter by trading pair
- `order_side`: buy, sell

---

### 4. Blockchain Monitor (`blockchain-monitor.json`)

**Purpose:** Track Solana blockchain interactions

**Key Panels:**
- Blockchain KPIs (Transactions, Success Rate, Confirmation Time, Priority Fees)
- Transaction Volume
- Program Calls by Program
- Transaction Success vs Failure
- Blockchain Latency Percentiles
- Smart Program Interactions
- Token Operations
- Recent Blockchain Errors
- RPC Endpoint Performance
- NFT/REC Operations

**Variables:**
- `program_id`: Filter by program ID
- `rpc_method`: Filter by RPC method

---

### 5. Infrastructure (`infrastructure.json`)

**Purpose:** Monitor infrastructure components (DB, cache, queue, containers)

**Key Panels:**
- Infrastructure Health (PostgreSQL, Redis, Kafka, InfluxDB)
- PostgreSQL Connections
- PostgreSQL Query Performance
- PostgreSQL Table Statistics
- Redis Memory Usage
- Redis Operations
- Redis Keyspace
- Kafka Consumer Lag
- Kafka Message Rate
- Kafka Topics
- Container CPU Usage
- Container Memory Usage
- Container Network I/O
- System Resources Summary

**Variables:**
- `container`: Filter by container name
- `topic`: Filter by Kafka topic

---

### 6. IAM Service Monitor (`iam-service-monitor.json`)

**Purpose:** Identity & Access Management service metrics

**Key Panels:**
- IAM Service KPIs (Auth Requests, Success Rate, Active Sessions, Avg Auth Latency)
- Authentication Flow (Success vs Failure)
- Authentication Methods Distribution
- Failed Authentication by Reason
- JWT Operations
- User Registration Trend
- User Management Operations
- API Key Authentication
- Session Lifecycle
- IAM Latency Percentiles
- IAM Service Errors
- Permission & Authorization Checks
- Top Users by Authentication

**Variables:**
- `auth_method`: Filter by authentication method
- `auth_result`: success, failure

---

### 7. Smart Meter & IoT Monitor (`smartmeter-iot-monitor.json`)

**Purpose:** Smart meter and IoT device monitoring

**Key Panels:**
- IoT & Smart Meter KPIs (Readings, Active Meters, Oracle Submissions)
- Meter Readings Volume
- Energy Production vs Consumption
- Oracle Bridge Pipeline
- Meter Connectivity Status
- Top Energy Producers
- Top Energy Consumers
- Attestation Success Rate
- IoT Gateway Throughput
- Meter Reading Latency
- Smart Meter Simulator Activity
- Oracle Blockchain Settlement
- IoT Errors
- Meter Types Distribution
- Data Quality Metrics

**Variables:**
- `meter_id`: Filter by meter ID
- `meter_type`: production, consumption, bidirectional
- `service`: oracle-bridge, smartmeter-simulator

---

### 8. Energy Token & REC Monitor (`energy-token-rec-monitor.json`)

**Purpose:** Energy token and Renewable Energy Certificate tracking

**Key Panels:**
- Energy Token KPIs (Token Ops, Minted, Burned, Active Holders)
- Token Operations Timeline
- REC Lifecycle
- Token Minting by Energy Source
- Token Transfer Volume
- REC Status Distribution
- Top Token Holders
- REC Generation by Region
- Tokenization Success Rate
- Energy Token Supply
- REC Retirement Tracking
- Token Latency Percentiles
- SPL Token Program Calls
- REC Verification Pipeline
- Token & REC Errors
- Green Energy Certification Stats

**Variables:**
- `energy_source`: solar, wind, hydro, geothermal, biomass
- `token_operation`: mint, burn, transfer, approve, revoke
- `rec_status`: Filter by REC status

---

### 9. Governance & Voting Monitor (`governance-voting-monitor.json`)

**Purpose:** DAO governance and voting activity

**Key Panels:**
- Governance KPIs (Active Proposals, Votes Cast, Participation Rate, Executed)
- Proposal Lifecycle
- Voting Activity (For/Against/Abstain)
- Proposal Status Distribution
- Vote Distribution
- Proposal Types
- Active Proposals Detail
- Voting Power Distribution
- Proposal Execution Timeline
- Governance Participation Rate
- Proposal Success Rate
- Avg Voting Duration
- Governance Latency
- Recent Proposals
- Governance Errors

**Variables:**
- `proposal_status`: active, pending, passed, rejected, executed, expired
- `vote_choice`: for, against, abstain
- `proposal_type`: Filter by proposal type

---

### 10. VPP Monitor (`vpp-monitor.json`)

**Purpose:** Virtual Power Plant operations and performance tracking.

**Key Panels:**
- **Aggregate Cluster SOC**: Real-time gauge of average state of charge.
- **Aggregation Events**: Total meter readings recently processed.
- **Cluster SOC Over Time**: Historical trends of battery health per cluster.
- **Aggregation Success Rate**: Health of the telemetry ingestion pipeline.
- **Aggregation Latency (P99)**: Performance profiling of VPP aggregation cycles.

**Variables:**
- `cluster`: Filter by VPP Cluster ID.

---

### 11. Settlement Health (`settlement-health.json`)

**Purpose:** Intensive monitoring of on-chain settlement performance.

**Key Panels:**
- **Settlement Success Rate**: Core KPI for the trading-to-blockchain pipeline.
- **Avg Batch Size**: Measures the effectiveness of match bundling.
- **Settlement Latency vs Batch Size**: Correlation between batch density and confirmation time.
- **Batch Size Distribution**: Histogram of transaction bundling over time.
- **Confirmation Latency P99**: Solana network performance for GridTokenX transactions.

---

### 12. User Analytics & Activity (`user-analytics-activity.json`)

**Purpose:** User behavior analytics and engagement tracking

**Key Panels:**
- User Analytics KPIs (Total Users, Active Users, New Users, Session Duration)
- User Activity Timeline
- User Actions Distribution
- User Retention Cohort
- User Geographic Distribution
- User Type Distribution
- Top Active Users
- User Onboarding Funnel
- User Session Metrics
- User Trading Behavior
- User Engagement Score Distribution
- User Device Types
- User Churn Indicators
- User Lifetime Value Segments
- User Feature Adoption

**Variables:**
- `user_type`: prosumer, consumer, investor, aggregator
- `user_region`: Filter by geographic region
- `device_type`: Filter by device type

---

### 12. Security & Audit Monitor (`security-audit-monitor.json`)

**Purpose:** Security operations center dashboard

**Key Panels:**
- Security KPIs (Auth Failures, Blocked IPs, Suspicious Activities, Audit Events)
- Authentication Failures Timeline
- Failed Auth by Source IP
- Rate Limiting Events
- Security Incidents by Type
- Audit Log Events
- Suspicious Activity Heatmap
- Wallet Security Events
- Privilege Escalation Attempts
- Data Access Violations
- API Abuse Detection
- Encryption Key Operations
- Compliance Events
- Platform Security Score Trend
- Threat Intelligence Indicators
- Security Alerts by Severity
- Incident Response Metrics

**Variables:**
- `incident_type`: brute_force, sql_injection, xss, csrf, ddos, fraud, unauthorized_access
- `alert_severity`: critical, high, medium, low, info
- `compliance_type`: Filter by compliance type

---

## 🔍 Query Reference

### Common SigNoz Query Patterns

#### Request Rate
```sql
SELECT toStartOfInterval(ts, INTERVAL 1 MINUTE) AS interval, 
       sum(count) as requests 
FROM signoz_calls_total 
WHERE service_name = 'gridtokenx-api' 
GROUP BY interval 
ORDER BY interval ASC
```

#### Latency Percentiles
```sql
SELECT quantile(0.50)(durationNano) / 1000000 as p50,
       quantile(0.95)(durationNano) / 1000000 as p95,
       quantile(0.99)(durationNano) / 1000000 as p99
FROM signoz_spans
WHERE service_name = 'gridtokenx-api'
```

#### Error Rate
```sql
SELECT (sum(count) FILTER (WHERE status_code = 'ERROR') * 100.0 / sum(count)) as error_rate
FROM signoz_calls_total
WHERE service_name = 'gridtokenx-api'
```

#### Custom Attribute Filtering
```sql
SELECT count()
FROM signoz_spans
WHERE attribute_user_id != ''
  AND attribute_order_side = 'buy'
  AND name LIKE '%order%'
```

---

## 🛠️ Troubleshooting

### Dashboards Not Showing Data

1. **Check SigNoz health:**
   ```bash
   curl http://localhost:3030/api/v1/health
   ```

2. **Verify OTEL collector is running:**
   ```bash
   docker ps | grep otel
   ```

3. **Check service instrumentation:**
   ```bash
   docker logs gridtokenx-api | grep OTEL
   ```

4. **Wait for data ingestion:**
   - First data appears within 2-5 minutes
   - Full dashboards populate in 10-15 minutes

### Alerts Not Firing

1. **Verify rules are loaded:**
   ```bash
   curl http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[].name'
   ```

2. **Check Alertmanager:**
   ```bash
   curl http://localhost:9093/api/v1/status
   ```

3. **Test alert expression:**
   ```bash
   curl "http://localhost:9090/api/v1/query?query=up"
   ```

### High Cardinality Issues

If dashboards become slow:
- Reduce time range
- Limit `DISTINCT` queries
- Add filters for specific services/attributes
- Use `LIMIT` clauses

---

## 📈 Best Practices

### Dashboard Usage

1. **Start with Platform Overview** for quick health check
2. **Drill down** to service-specific dashboards for issues
3. **Use variables** to filter by time range, service, or attributes
4. **Set appropriate refresh intervals** (10s-1m for ops, 5m+ for analytics)

### Alert Configuration

1. **Tune thresholds** based on your traffic patterns
2. **Start with warning-only** for new alerts
3. **Group related alerts** to reduce noise
4. **Set up escalation policies** for critical alerts
5. **Review and update** alerts quarterly

### Attribute Instrumentation

For best monitoring coverage, ensure services emit these standard attributes:

```rust
// Standard span attributes
span.set_attribute("user_id", user_id);
span.set_attribute("session_id", session_id);
span.set_attribute("order_id", order_id);
span.set_attribute("transaction_id", tx_id);
span.set_attribute("http.method", method);
span.set_attribute("http.status_code", status);
span.set_attribute("db.system", "postgresql");
span.set_attribute("rpc.system", "solana");
```

---

## 🔗 Related Documentation

- [SigNoz Documentation](https://signoz.io/docs/)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/)
- [GridTokenX Architecture](../../QWEN.md)
- [Monitoring Setup Guide](./setup_guide.md)

---

## 📞 Support

For monitoring-related issues:
- **Platform Team**: platform-team@gridtokenx.com
- **Security Team**: security@gridtokenx.com
- **On-Call**: oncall@gridtokenx.com (Critical only)

---

*Last Updated: April 2026*
*Version: 1.0.0*
