# GridTokenX Platform

A blockchain-powered P2P energy trading platform built on Solana with Anchor smart contracts.

## 🏗️ Architecture

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Trading UI     │────▶│   API Gateway    │────▶│  Solana Chain    │
│   (Next.js)      │     │   (Rust/Axum)    │     │  (Anchor)        │
└──────────────────┘     └──────────────────┘     └──────────────────┘
         │                       │                        │
         │                       ▼                        │
         │               ┌──────────────┐                 │
         │               │  PostgreSQL  │                 │
         │               │  + Redis     │                 │
         │               └──────────────┘                 │
         │                       │                        │
         ▼                       ▼                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Smart Meter Simulator                          │
└──────────────────────────────────────────────────────────────────┘
```

## 📦 Components

| Component | Directory | Port |
|-----------|-----------|------|
| API Gateway | `gridtokenx-apigateway/` | 4000 |
| Trading UI | `gridtokenx-trading/` | 3000 |
| Admin Portal | `gridtokenx-admin/` | 3001 |
| Anchor Programs | `gridtokenx-anchor/` | - |
| Meter Simulator | `gridtokenx-smartmeter-simulator/` | 8080 |

## 🚀 Quick Start

```bash
# Start development environment
./scripts/start-dev.sh

# Stop all services
./scripts/stop-dev.sh
```

## 🧪 Testing

### Anchor Tests
```bash
cd gridtokenx-anchor
anchor test --skip-build
```

### API Gateway Tests
```bash
cd gridtokenx-apigateway
cargo test --lib -- --test-threads=1
```

## ⚙️ Configuration

Key environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection | - |
| `REDIS_URL` | Redis connection | - |
| `SOLANA_RPC_URL` | Solana RPC endpoint | `http://localhost:8899` |
| `TOKENIZATION_USE_ONCHAIN_BALANCE` | Use on-chain balance for escrow | `false` |

## 📊 Test Results

- **Anchor Programs**: 18/18 (100%)
- **API Gateway**: 117/117 (100%)

## 📝 License

Proprietary - GridTokenX
