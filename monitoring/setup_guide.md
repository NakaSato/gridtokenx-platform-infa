# Oracle Bridge Monitoring & Alerting Setup Guide

This guide explains how to integrate the newly created monitoring assets into your GridTokenX environment.

## 📁 Repository Locations
- **Alerting Rules**: `monitoring/prometheus_rules.yml`
- **Grafana Dashboard**: `monitoring/oracle_bridge_dashboard.json`

---

## 🚀 Step 1: Prometheus Alerting Integration

To enable real-time alerting for the Oracle Bridge, add the rules to your Prometheus configuration.

1. Copy `monitoring/prometheus_rules.yml` to your Prometheus config directory (e.g., `/etc/prometheus/rules/`).
2. Update your `prometheus.yml` to include the rule file:
   ```yaml
   rule_files:
     - "rules/prometheus_rules.yml"
   ```
3. Reload Prometheus: `curl -X POST http://localhost:9090/-/reload`

### Critical Thresholds Rationale
| Alert Name | Threshold | Rationale |
| :--- | :--- | :--- |
| `OracleRelayQueueSaturation` | > 800 | The relay buffer has a hard limit of 1024. Reaching 800 indicates we are at 80% capacity and at risk of dropping IoT readings. |
| `OracleHighSubmissionLatency` | p95 > 30s | Solana settlement usually takes < 10s. 30s indicates significant network congestion or RPC failure. |
| `OracleSubmissionFailureSpike` | > 5% | Indicates a persistent issue with the authority wallet or smart contract permissions. |

---

## 📊 Step 2: Grafana Dashboard Import

Visualize the relay pipeline health with the provided dashboard.

1. Open your Grafana instance.
2. Navigate to **Dashboards** > **New** > **Import**.
3. Upload the `monitoring/oracle_bridge_dashboard.json` file.
4. Select your Prometheus data source and click **Import**.

### Dashboard Panels
- **Ingestion Rate**: Tracks real-time throughput from IoT devices.
- **Queue Depth**: Uses color coding (Green < 700, Yellow 700-900, Red > 900) to show buffer health.
- **P99/P95 Latency**: Monitors tail latency for blockchain settlements.
- **Outcome Trends**: Compares successful vs. failed submissions over time.

---

## 🛠️ Verification
After deployment, you can verify the metrics flow by visiting the platform's metrics endpoint:
`GET /metrics` (search for `oracle_relay_`)
