---
description: Environment setup and configuration guide
---

# Environment Setup

Set up and configure the GridTokenX development environment.

## Prerequisites

### Required Software

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 24+ | Containerization |
| Rust | 1.75+ | Backend services |
| Node.js/Bun | Latest | Frontend |
| Solana CLI | 1.17+ | Blockchain |
| Anchor | 0.30+ | Smart contracts |
| Python | 3.11+ | Simulator |
| Just | Latest | Task runner |

### Installation Commands

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Solana CLI
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"

# Install Anchor CLI
cargo install --git https://github.com/coral-xyz/anchor avm --force --locked
avm install latest

# Install Bun (Node.js alternative)
curl -fsSL https://bun.sh/install | bash

# Install Just
cargo install just

# Install Python UV (for simulator)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Initial Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd gridtokenx-platform-infa
git submodule update --init --recursive
```

### 2. Copy Environment Files

```bash
# Root environment
cp .env.example .env

# Service-specific environments
cp gridtokenx-api/.env.example gridtokenx-api/.env
cp gridtokenx-trading/.env.example gridtokenx-trading/.env
cp gridtokenx-portal/.env.example gridtokenx-portal/.env
```

### 3. Configure Environment Variables

Edit `.env` with your settings:

```bash
# Database credentials
POSTGRES_DB=gridtokenx
POSTGRES_USER=gridtokenx_user
POSTGRES_PASSWORD=<secure-password>

# JWT Secret (use strong random string)
JWT_SECRET=<generate-secure-random-string>

# Encryption Secret
ENCRYPTION_SECRET=<secure-32-char-minimum>

# Solana Configuration
SOLANA_CLUSTER=localnet
SOLANA_RPC_URL=http://localhost:8899
SOLANA_WS_URL=ws://localhost:8900
```

### 4. Generate Secure Secrets

```bash
# Generate JWT secret
openssl rand -base64 32

# Generate encryption key
openssl rand -base64 32

# Generate API key secret
openssl rand -hex 32
```

## Directory Structure

```
gridtokenx-platform-infa/
├── gridtokenx-api/              # API Gateway (Rust)
├── gridtokenx-iam-service/      # Identity Service (Rust)
├── gridtokenx-trading-service/  # Trading Engine (Rust)
├── gridtokenx-oracle-bridge/    # Oracle Gateway (Rust)
├── gridtokenx-anchor/           # Smart Contracts (Anchor)
├── gridtokenx-trading/          # Trading UI (Next.js)
├── gridtokenx-portal/           # Admin Portal (Next.js)
├── gridtokenx-explorer/         # Blockchain Explorer (Next.js)
├── gridtokenx-smartmeter-simulator/  # Meter Simulator (Python)
├── gridtokenx-smartmeter-simulator/ui  # Simulator UI (React)
├── scripts/                     # Management scripts
├── docker/                      # Docker configurations
└── .env                         # Environment variables
```

## Wallet Setup

### Generate Dev Wallet

```bash
# Generate new keypair
solana-keygen new -o dev-wallet.json --no-passphrase

# View public key
solana-keygen pubkey dev-wallet.json

# Fund with test SOL (localnet)
solana airdrop 100 $(solana-keygen pubkey dev-wallet.json) \
  --url http://localhost:8899
```

### Configure Wallet Path

In `.env`:
```bash
AUTHORITY_WALLET_PATH=/path/to/gridtokenx-platform-infa/dev-wallet.json
```

## Database Setup

### Initialize PostgreSQL

```bash
# Start PostgreSQL container
docker-compose up -d postgres

# Wait for ready
docker exec gridtokenx-postgres \
  pg_isready -U gridtokenx_user -d gridtokenx

# Create database and run migrations
cd gridtokenx-api
sqlx database create
sqlx migrate run
```

### Verify Database

```bash
docker exec -it gridtokenx-postgres psql \
  -U gridtokenx_user -d gridtokenx \
  -c "\dt"
```

## Blockchain Setup

### Initialize Solana Validator

```bash
# Start validator
solana-test-validator --reset --ledger ./test-ledger

# In new terminal, deploy programs
cd gridtokenx-anchor
anchor build
anchor deploy
```

### Bootstrap Smart Contracts

```bash
cd gridtokenx-anchor
export ANCHOR_PROVIDER_URL=http://localhost:8899
export ANCHOR_WALLET=target/deploy/registry-keypair.json

npx ts-node scripts/bootstrap.ts
npx ts-node scripts/get_pdas.ts
```

## Verification

### Check All Services

```bash
./scripts/app.sh status
```

### Test Endpoints

```bash
# API Gateway
curl http://localhost:4000/health

# Solana RPC
curl http://localhost:8899/health

# Trading UI
curl http://localhost:3000

# Smart Meter API
curl http://localhost:8082/health
```

## IDE Configuration

### VS Code Extensions

Recommended extensions:
- Rust Analyzer
- Prisma
- Next.js
- Python
- Docker
- Solana

### Rust Analyzer Setup

Create `.vscode/settings.json`:
```json
{
  "rust-analyzer.cargo.features": "all",
  "rust-analyzer.checkOnSave.command": "clippy"
}
```

## Troubleshooting

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Rust Version Mismatch

```bash
# Update Rust
rustup update

# Check version
rustc --version
```

### Solana Version Issues

```bash
# Update Solana
solana-install update

# Check version
solana --version
```

### Port Already in Use

```bash
# Find and kill process
lsof -ti:4000 | xargs kill -9
lsof -ti:5432 | xargs kill -9
```

### Database Migration Errors

```bash
# Check migration status
cd gridtokenx-api
sqlx migrate info

# Reset and reapply
sqlx migrate revert
sqlx migrate run
```

## Related Workflows

- [Start Development](./start-dev.md) - Start the platform
- [Docker Services](./docker-services.md) - Manage containers
- [Blockchain Init](./blockchain-init.md) - Setup blockchain
