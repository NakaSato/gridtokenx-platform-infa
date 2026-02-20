# Contributing to GridTokenX

Welcome to the GridTokenX platform! This guide will help you set up your development environment and understand the architecture of the API Gateway.

## Getting Started

### Prerequisites

- **Rust**: Nightly toolchain (for edition 2024 features)
- **PNPM/Bun**: For frontend and scripts
- **Docker**: For running databases and services
- **Solana CLI**: For local blockchain development

### Local Environment Setup

1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd gridtokenx-platform-infa
   ```

2. **Initialize services**:
   ```bash
   make setup-env  # Create .env from template
   make build      # Build Docker images
   ```

3. **Start development environment**:
   ```bash
   ./scripts/start-dev.sh
   ```
   This script starts the Solana validator, funds tokens, and launches the API Gateway, Simulator, and UI.

## Architecture: API Gateway

The API Gateway is built with Axum and follows a modular design.

### Application State (`AppState`)
The `AppState` is a modular hybrid structure:
- **Modular Sub-states**: Categories like `CoreState`, `AuthState`, `TradingState` are wrapped in `Arc` for efficient sharing.
- **Granular Extraction**: Use Axum's `FromRef` to extract only the sub-state you need in your handlers.
- **Example**:
  ```rust
  pub async fn my_handler(
      State(core): State<Arc<CoreState>>,
      ...
  ) { ... }
  ```

### High-Performance I/O
- **Async Solana Client**: All blockchain interactions use the `nonblocking` RPC client. Avoid `spawn_blocking` for RPC calls.
- **Database Tuning**: The connection pool is tuned for high concurrency. Check `src/constants.rs` for settings.

## Development Workflow

### Coding Standards
- **Error Handling**: Use the central `ApiError` type and provide structured context using `.context()` or `.map_err()`.
- **Security**: Avoid `.unwrap()` in production code. Use `anyhow` or `thiserror` for error propagation.
- **Documentation**: Use module-level and function-level doc comments.

### Testing
- **Unit Tests**: `cargo test`
- **Integration Tests**: See `tests/integration/` for full-cycle tests.
- **Property Tests**: Located in `src/handlers/trading/orders/tests.rs` for logic verification.
- **Benchmarks**: Run with `cargo bench -p api-gateway`.

### Building with Docker
The API Gateway is built using a workspace-aware Docker structure. To rebuild:
```bash
docker-compose build apigateway
```
*Note: The build context is the project root to properly resolve workspace dependencies.*

## Questions?
Reach out to the Engineering Department or check the `docs/` folder for deeper architectural dives.
