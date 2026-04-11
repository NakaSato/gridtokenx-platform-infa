---
description: API development and testing guide
---

# API Development (Gateway)

The **API Services** (`gridtokenx-api`) acts as the central orchestration layer for the GridTokenX platform. It handles client requests via REST/WebSockets and communicates with domain-specific microservices via **ConnectRPC (gRPC over HTTP/2)**.

## Core Concepts
- **Pure Orchestrator**: The API layer contains NO blockchain code. It delegates identity to `iam-service` and matching/settlement to `trading-service`.
- **Background Workers**: Manages persistent tasks like `settlement_processor`, `event_processor` (Kafka), and `market_data_sync`.
- **ConnectRPC**: Uses modern gRPC clients with connection pooling.

## Quick Commands

// turbo

```bash
# Run API Services natively
cd gridtokenx-api && cargo run

# Run with auto-reload (requires cargo-watch)
cargo watch -x run

# Run integration tests
just test
```

## Project Structure

```
gridtokenx-api/src/
├── api/                # ConnectRPC / REST Handlers
│   ├── handlers/       # Endpoint logic
│   └── mod.rs
├── domain/             # High-level business logic
├── infra/              # External integrations
│   ├── iam/            # gRPC Client for IAM Service
│   ├── trading/        # gRPC Client for Trading Service
│   ├── kafka/          # Message consumers/producers
│   └── database/       # SQLx persistence
├── core/               # Configuration & Shared types
├── startup.rs          # Server initialization & Worker spawning
└── main.rs             # Application entry point
```

## Implementing Endpoints

### 1. gRPC Client Usage
Since the API is an orchestrator, most handlers call a downstream microservice:

```rust
// src/api/handlers/users.rs
pub async fn get_user_profile(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<UserResponse>, AppError> {
    // Call IAM Service via gRPC client
    let user = state.infra.iam_client.get_user(user_id).await
        .map_err(|e| AppError::Internal(e.to_string()))?;

    Ok(Json(user))
}
```

### 2. Background Workers
Workers are spawned in `startup.rs` to handle asynchronous events:

```rust
// Example: Event Processor (Kafka Consumer)
pub async fn start_event_processor(state: AppState) {
    let mut consumer = state.infra.kafka.create_consumer("trading-events");
    
    while let Some(event) = consumer.next().await {
        match event {
            TradeExecuted(t) => state.broadcast_trade(t).await,
            _ => continue,
        }
    }
}
```

## Authentication & Middleware
The API layer handles JWT validation and propagates the user context to downstream services:

```rust
// src/api/middleware/auth.rs
// Validates Bearer token and inserts Claims into request extensions
pub async fn auth_middleware(...) { ... }
```

## Development Workflow

1. **Schema Update**: If adding a new domain entity, update the `.proto` files in `gridtokenx-api/proto/`.
2. **Infra Update**: Implement the gRPC client method in `infra/` to communicate with the target microservice.
3. **API Logic**: Create the REST/ConnectRPC handler in `api/handlers/`.
4. **Registration**: Register the handler in `startup.rs`.

## Testing the API

### Unit & Integration Tests
```bash
# Run specific service tests
cargo test -p gridtokenx-api

# Run full integration suite (Docker required)
./scripts/run_integration_tests.sh
```

### Manual Testing with Curl
```bash
curl -X GET http://localhost:4000/api/v1/health
```

## Related Workflows
- [IAM Service](./iam-service-development.md) - For identity/wallet logic
- [Trading Service](./trading-service-development.md) - For order matching logic
- [Monitoring](./monitoring.md) - For tracing requests across services
.md) - Run API tests
- [Debugging](./debugging.md) - Debug API issues
- [Monitoring](./monitoring.md) - Monitor API metrics
