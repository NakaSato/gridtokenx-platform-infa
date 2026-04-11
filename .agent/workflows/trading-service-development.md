---
description: Trading engine and matching service development guide
---

# Trading Service Development

The **Trading Service** (`gridtokenx-trading-service`) is the high-performance matching engine of the platform. It handles order book management, trade matching (CDA/Batch), and on-chain settlement.

## Core Responsibilities
- **Matching Engine**: In-memory order book transition and trade execution.
- **CDA (Continuous Double Auction)**: Immediate matching for high-liquidity markets.
- **Batch Clearing**: Periodic window matching (e.g., 15-min) for gas efficiency.
- **Settlement**: Recording trades in the Solana **Trading Program** and executing SPL token transfers.
- **Market Data**: Providing L2/L3 order book depth and ticker statistics.

## Quick Commands

// turbo

```bash
# Run Trading Service natively
cd gridtokenx-trading-service && cargo run

# Run matching tests
cargo test -p gridtokenx-trading-service
```

## Project Structure

```
gridtokenx-trading-service/src/
├── api/                # gRPC (ConnectRPC) Handlers
├── domain/             # Core matching logic
│   ├── engine/        # Order book implementation
│   ├── matching/      # CDA & Batch Algorithms
│   └── settlement/    # On-chain clearing logic
├── infra/              # External drivers
│   ├── solana/         # Trading program client
│   ├── redis/          # Persistence & Pub/Sub
│   └── database/       # Trade history (PostgreSQL)
├── core/               # Matching config & Market types
├── metrics/            # Throughput & Latency monitoring
└── startup.rs          # Engine initialization
```

## Matching Modes

### 1. Continuous Double Auction (CDA)
Orders are matched immediately upon arrival based on price-time priority. Best for liquid markets.

### 2. Batch Auction
Orders are collected in a window (e.g., 15 minutes) and matched at a single clearing index. This optimizes on-chain gas costs and is ideal for P2P energy trading.

## On-Chain Settlement
Executed trades must be finalized on the Solana blockchain. The service handles:
- **Escrow**: Locking tokens during order placement.
- **Transfer**: Moving tokens from seller to buyer accounts.
- **Revenue Split**: Automatic fee distribution (50% staking, 30% treasury, 20% burn).

## Event Streaming
Matching results are published to:
- **Redis Pub/Sub**: Real-time websocket updates (via API services).
- **Kafka**: Audit trail and historical trade recording.

## Configuration
- `TRADING_PROGRAM_ID`: Anchor Program ID for trading logic.
- `BATCH_WINDOW_SECONDS`: Duration for batch auction windows.
- `FEE_COLLECTOR_WALLET`: Destination for platform fees.

## Related Workflows
- [API Development](./api-development.md) - Connectivity to the matching engine.
- [Oracle Bridge](./oracle-bridge-development.md) - Understanding how energy production triggers trades.
- [Anchor Development](./anchor-development.md) - Developing the Trading smart contract.
