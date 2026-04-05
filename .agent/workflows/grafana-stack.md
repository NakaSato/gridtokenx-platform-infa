---
description: How to use and manage the Grafana Observability Stack (LGT)
---

# Grafana Observability Stack (LGT)

This workflow describes how to manage the Prometheus, Loki, and Tempo stack used for observability in GridTokenX.

## 1. Starting the Stack

The monitoring stack is managed via Docker Compose.

```bash
docker-compose up -d prometheus grafana loki tempo otel-collector
```

## 2. Accessing UIs

| Service | URL | Credentials |
| :--- | :--- | :--- |
| **Grafana** | [http://localhost:3001](http://localhost:3001) | `admin` / `admin` |
| **Prometheus** | [http://localhost:9090](http://localhost:9090) | None |
| **Loki** | [http://localhost:3100/ready](http://localhost:3100/ready) | None (Health Check) |
| **Tempo** | [http://localhost:3200/ready](http://localhost:3200/ready) | None (Health Check) |

## 3. Viewing Telemetry in Grafana

1.  Open **Grafana** ([http://localhost:3001](http://localhost:3001)).
2.  Go to **Explore** in the left sidebar.
3.  Select the datasource from the dropdown:
    *   **Prometheus**: For metrics (CPU, memory, custom app metrics).
    *   **Loki**: For application and container logs.
    *   **Tempo**: For distributed trace search and visualization.

## 4. Verification

To verify that telemetry is being ingested:

- **Metrics**: Search for `up` or `process_cpu_seconds_total` in Prometheus/Grafana.
- **Logs**: In Loki, search with label `{job="otel-collector"}` or `{container_name="gridtokenx-api-gateway"}`.
- **Traces**: In Tempo, use the "TraceQL" or "Search" tab to find spans from `gridtokenx-api-gateway`, `iam-service`, etc.

## 5. Troubleshooting

- **Check OTEL Collector Logs**:
    ```bash
    docker logs -f gridtokenx-otel-collector
    ```
- **Check Exporter Health**: Verify that the endpoints labeled in `otel-collector-config.yaml` are reachable from within the Docker network.
- **Reset Data**: To clear all telemetry data and start fresh:
    ```bash
    docker-compose down -v prometheus_data loki_data tempo_data grafana_data
    ```
