# OpenTelemetry Integration Guide

This guide explains how to use OpenTelemetry tracing in GridTokenX services for distributed tracing with SigNoz.

## Overview

GridTokenX uses OpenTelemetry to instrument all Rust services with distributed tracing. Traces are exported to SigNoz via the OTLP (OpenTelemetry Protocol) gRPC endpoint.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  gridtokenx-api │     │  iam-service    │     │ trading-service │
│  (Axum + OTel)  │     │  (gRPC + OTel)  │     │  (OTel)         │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    SigNoz (OTLP)        │
                    │  http://localhost:4317  │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   SigNoz UI             │
                    │  http://localhost:3030  │
                    └─────────────────────────┘
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OTEL_ENABLED` | `true` | Enable/disable OpenTelemetry |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4317` | SigNoz OTLP gRPC endpoint |
| `OTEL_SERVICE_NAME` | `gridtokenx-api` | Service name in traces |
| `OTEL_RESOURCE_ATTRIBUTES` | - | Additional attributes (key=value,key2=value2) |
| `OTEL_TRACES_SAMPLER` | `always_on` | Sampler: `always_on`, `always_off`, `traceidratio` |
| `OTEL_TRACES_SAMPLER_ARG` | `1.0` | Sampler argument (e.g., 0.1 for 10% sampling) |

### Example Configuration

```bash
# Development (sample all traces)
OTEL_ENABLED=true
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_SERVICE_NAME=gridtokenx-api
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=development,service.team=platform
OTEL_TRACES_SAMPLER=always_on

# Production (sample 10% of traces)
OTEL_ENABLED=true
OTEL_EXPORTER_OTLP_ENDPOINT=https://signoz.company.com:4317
OTEL_SERVICE_NAME=gridtokenx-api
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production,service.team=platform
OTEL_TRACES_SAMPLER=traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1
```

## Usage

### Automatic HTTP Tracing

All incoming HTTP requests are automatically traced with:
- HTTP method and route
- Status code
- Request duration
- Client IP and user agent
- Error information (for 5xx responses)

No code changes needed - the `otel_tracing_middleware` handles this.

### Manual Instrumentation

#### Creating Spans

```rust
use tracing::{info_span, instrument};

// Using macro for function instrumentation
#[instrument(name = "user.login", skip(password))]
async fn login(username: &str, password: &str) -> Result<User> {
    // Function body
}

// Using span macro
async fn process_order(order_id: &str) -> Result<()> {
    let _span = info_span!("order.process", order_id).entered();
    // Processing logic
}
```

#### Adding Events to Spans

```rust
use opentelemetry::trace::{Span, TraceContextExt};
use opentelemetry::{global, Context, KeyValue};

fn process_payment(amount: f64) -> Result<()> {
    let tracer = global::tracer("gridtokenx-api");
    let mut span = tracer.span("payment.process");

    span.add_event("payment.started".to_string(), vec![
        KeyValue::new("payment.amount", amount),
        KeyValue::new("payment.currency", "THB"),
    ]);

    // Processing...

    span.add_event("payment.completed".to_string(), vec![
        KeyValue::new("payment.status", "success"),
    ]);

    Ok(())
}
```

#### Recording Errors

```rust
use anyhow::Result;
use tracing::{error, Span};

async fn fetch_blockchain_data() -> Result<Data> {
    match do_fetch().await {
        Ok(data) => Ok(data),
        Err(e) => {
            // Record error in current span
            Span::current().record("error", &e.to_string());
            error!("Failed to fetch blockchain data: {}", e);
            Err(e)
        }
    }
}
```

### Custom Span Attributes

```rust
use tracing::info_span;

// Database operations
let span = info_span!(
    "db.query",
    db.system = "postgresql",
    db.operation = "SELECT",
    db.sql.table = "users"
);

// Blockchain operations
let span = info_span!(
    "blockchain.transaction",
    blockchain.system = "solana",
    blockchain.program = "trading",
    blockchain.method = "create_order"
);

// External API calls
let span = info_span!(
    "http.client",
    http.method = "POST",
    http.url = "https://api.pyth.network",
    span.kind = "client"
);
```

## Helper Macros

GridTokenX provides helper macros for common operations:

```rust
use api_gateway::{db_span, http_client_span, blockchain_span};

// Database span
let _span = db_span!("SELECT", "users");

// HTTP client span
let _span = http_client_span!("POST", "https://api.example.com");

// Blockchain span
let _span = blockchain_span!("create_order", "trading_program");
```

## Best Practices

### 1. Span Naming

Use lowercase, dot-separated names that describe the operation:
- ✅ `user.login`, `order.create`, `db.query.users`
- ❌ `Login`, `CreateOrder`, `SELECT * FROM users`

### 2. Sensitive Data

**NEVER** include sensitive data in spans:
- ❌ Passwords, API keys, tokens
- ❌ Full credit card numbers
- ❌ Personal identification numbers

**DO** include:
- ✅ Resource IDs (user_id, order_id)
- ✅ Operation types
- ✅ Status codes and error messages (without sensitive context)

### 3. Span Duration

Keep spans short-lived:
- ✅ Individual operations (DB queries, API calls)
- ❌ Long-running background processes (use separate spans for each step)

### 4. Error Handling

Always record errors in spans:
```rust
#[instrument(err)]
async fn process_data() -> Result<()> {
    // If this returns Err, it's automatically recorded
}
```

### 5. Sampling

In production, use sampling to reduce overhead:
```bash
# Sample 10% of traces
OTEL_TRACES_SAMPLER=traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1

# Sample all error traces (custom logic needed)
# See: https://opentelemetry.io/docs/specs/otel/trace/sdk/#sampler
```

## Testing

### Verify Traces are Being Sent

1. Start SigNoz: `just signoz-up`
2. Start the API: `cargo run`
3. Make a few requests: `curl http://localhost:4000/health`
4. Check SigNoz UI: http://localhost:3030
5. Look for traces from `gridtokenx-api`

### Local Testing with Console Exporter

For development, you can use the console exporter to see traces in logs:

```rust
// In utils/telemetry.rs, change the exporter:
let exporter = opentelemetry_otlp::new_exporter()
    .tonic()
    .with_endpoint(&config.otlp_endpoint);

// To console exporter for debugging:
use opentelemetry_stdout as stdout;
let exporter = stdout::SpanExporter::default();
```

## Troubleshooting

### No Traces Appearing in SigNoz

1. **Check SigNoz is running**: `docker-compose ps signoz`
2. **Verify endpoint**: Ensure `OTEL_EXPORTER_OTLP_ENDPOINT` is correct
3. **Check network**: SigNoz must be reachable from the service
4. **Inspect logs**: Look for OpenTelemetry errors in application logs
5. **Verify OTLP port**: Port 4317 should be exposed

### High Overhead

If tracing causes performance issues:

1. **Reduce sampling rate**: Set `OTEL_TRACES_SAMPLER_ARG=0.01` for 1%
2. **Disable in dev**: Set `OTEL_ENABLED=false`
3. **Check span count**: Too many spans per request can cause overhead
4. **Batch configuration**: Adjust batch settings in `TelemetryConfig`

### Missing Context Propagation

For traces to connect across services:

1. **Propagate headers**: Ensure trace context headers are passed
2. **Use same sampler**: Consistent sampling across services
3. **Check service names**: Each service should have unique `OTEL_SERVICE_NAME`

## Migration Guide

### Adding Tracing to Existing Code

1. **Add dependencies** to `Cargo.toml`:
```toml
[dependencies]
opentelemetry = { workspace = true }
opentelemetry-otlp = { workspace = true }
opentelemetry_sdk = { workspace = true }
tracing-opentelemetry = { workspace = true }
```

2. **Initialize telemetry** in `main.rs`:
```rust
use crate::utils::telemetry;

#[tokio::main]
async fn main() -> Result<()> {
    let config = Config::from_env()?;
    let _tracer = telemetry::init_telemetry_default(&config);
    
    // Rest of initialization
}
```

3. **Add `#[instrument]`** to key functions:
```rust
use tracing::instrument;

#[instrument(name = "business.operation", skip(sensitive_data))]
async fn process_business_logic() -> Result<()> {
    // Implementation
}
```

## Resources

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [OpenTelemetry Rust API](https://docs.rs/opentelemetry/)
- [SigNoz Documentation](https://signoz.io/docs/)
- [tracing Crate Documentation](https://docs.rs/tracing/)
- [tracing-opentelemetry](https://docs.rs/tracing-opentelemetry/)
