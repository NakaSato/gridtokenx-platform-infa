# 🛰 API Services Architecture

**Service Name**: `gridtokenx-api`  
**Port**: `4000` (HTTP) / `4001` (Metrics)  
**Version**: 2.2  
**Status**: ✅ Production Ready / Lead Orchestrator

---

## 1. Overview

The **API Services** (Gateway Orchestrator) is the high-performance central nervous system of the GridTokenX Platform. Built with **Axum (Rust)**, it coordinates complex workflows between specialized microservices, manages real-time event broadcasting to frontends, and executes critical background persistence tasks.

---

## 2. Core Responsibilities

1.  **Request Orchestration**: Aggregates data from `iam-service`, `trading-service`, and `oracle-bridge` via ConnectRPC.
2.  **Auth Propagation**: Verifies JWTs from Kong and injects user context (Claims) into downstream gRPC metadata.
3.  **Real-Time Engine**: Bridges Kafka/RabbitMQ events into Redis Pub/Sub for sub-millisecond WebSocket fan-out.
4.  **High-Throughput Persistence**: Executes the `Persistence Worker` pool to batch-insert telemetry into PostgreSQL and InfluxDB.
5.  **Event Convergence**: Syncs on-chain Solana events (from Geyser/RPC) to the off-chain Postgres database for consistent indexing.

---

## 3. Technical Stack

-   **Framework**: Axum (Rust)
-   **Communication**: **ConnectRPC (gRPC over HTTP/2)** with persistent connection pooling.
-   **Caching**: Redis 7 (Pub/Sub & Session Cache).
-   **Messaging**: Kafka (Event Sink) & RabbitMQ (Task Ingestion).
-   **Observability**: OpenTelemetry (OTEL), Prometheus, and Loki.

---

## 4. Orchestration & Connection Pooling

The API Service uses a **Connection Pool** model to maintain high-throughput communication with downstream microservices.

```rust
// Default Orchestration Config
GrpcClientConfig {
    iam_grpc_url: "http://iam-service:50052",
    trading_grpc_url: "http://trading-service:50053",
    oracle_grpc_url: "http://oracle-bridge:50051",
    pool_size: 8,           // 8 persistent HTTP/2 connections
    timeout_ms: 5000,       // 5s fail-fast timeout
}
```

---

## 5. Background Workers

The `gridtokenx-api` spawns several specialized workers upon startup:

| Worker | Role | Strategy |
| :--- | :--- | :--- |
| **Persistence Worker** | Telementry Ingestion | Consumes Kafka/Redis; performs batch SQL/Influx inserts. |
| **Event Consumer** | Audit Logging | Listens to `market.events` and records immutable trade logs. |
| **Settlement Watcher** | Finality Tracking | Monitors Solana slots until 32 confirmations are reached. |
| **Billing Engine** | Aggregation | Periodic task to trigger 15-min window calculations if delayed. |

---

## 6. Directory Structure

```text
gridtokenx-api/src/
├── main.rs              # App Entry & Worker Spawning
├── core/                # Configuration, Telemetry, and Orchestration logic
├── api/                 # HTTP Routes & Handlers (Axum)
├── infra/               # gRPC Clients (ConnectRPC implementation)
├── domain/              # Shared types & Business logic
└── worker/              # Background Task implementations
```

---

## 7. Performance Benchmarks

-   **Orchestration Overhead**: < 5ms (gRPC pooling optimization).
-   **Telemetry Persistence**: 20k+ records/sec (Multi-threaded Batching).
-   **Real-time Latency**: ~3ms (Kafka → Redis → WebSocket).

---

## Related Documentation
-   [Platform Design](../../PLATFORM_DESIGN.md)
-   [System Architecture](../specs/system-architecture.md)
-   [Trading Service Architecture](./TRADING_SERVICE_ARCHITECTURE.md)
