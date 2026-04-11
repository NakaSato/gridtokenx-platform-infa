---
description: Oracle Bridge and IoT data ingestion development guide
---

# Oracle Bridge Development

The **Oracle Bridge** (`gridtokenx-oracle-bridge`) is the cryptographic trust layer between physical energy infrastructure and the Exchange Platform. It validates telemetry and aggregates data for blockchain settlement.

## Core Responsibilities
- **Telemetry Ingestion**: Receiving signed measurements from Edge Gateways via HTTP/gRPC.
- **Signature Verification**: Validating Ed25519 signatures from devices to ensure data integrity.
- **Range Validation**: Checking physics-of-sense (Voltage, Current, Frequency) and kWh bounds.
- **Data Aggregation**: Grouping 1-second/1-minute readings into 15-minute **Settlement Windows**.
- **Message Publishing**: Streaming validated data to Kafka for the API and Trading services.

## Quick Commands

// turbo

```bash
# Run Oracle Bridge natively
cd gridtokenx-oracle-bridge && cargo run

# Test ingestion
./scripts/stress_test_20k.sh --limit 100
```

## Project Structure

```
gridtokenx-oracle-bridge/src/
├── ingester/           # Zone-based telemetry ingestion logic
├── aggregator/         # 15-min settlement window logic
├── domain/             # Validation & Cryptography
│   ├── signature.rs    # Ed25519 verification
│   └── physics.rs      # Range validation
├── infra/              # External drivers
│   ├── kafka/          # Topic producers (meter.readings)
│   └── database/       # Meter registry & Public keys
├── grpc/               # ConnectRPC server for admin/querying
└── startup.rs          # Worker orchestration
```

## Data Lifecycle

### 1. Ingestion
The bridge receives small batches of telemetry from an Edge Gateway. Each request must include an `X-Edge-Signature` header.

### 2. Validation
- **Cryptographic**: Verified against the meter's stored public key in the IAM registry.
- **Physical**: Checks if readings align with transformer zone limits.

### 3. Aggregation
Readings are stored in RAM-optimized buffers (usually Redis or specialized in-memory maps) to calculate the net energy in 15-minute windows.

### 4. Publishing
Once validated, readings are pushed to the `meter.readings.validated` Kafka topic. The API service consumes this to update user dashboards.

## Key Metrics
The Oracle Bridge is I/O intensive. Key metrics include:
- `telemetry_ingestion_rps`: Requests per second.
- `signature_verification_latency_ms`: Time taken for Ed25519 checks.
- `aggregation_window_drift_sec`: Latency between device time and window finalization.

## Related Workflows
- [Trading Service](./trading-service-development.md) - How validated data triggers settlements.
- [Project Overview](./project-overview.md) - Understanding the Infrastructure vs Exchange platforms.
- [Monitoring](./monitoring.md) - Tracking high-throughput telemetry pipelines.
