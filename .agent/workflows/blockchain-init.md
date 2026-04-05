---
description: Initialize Solana blockchain and deploy Anchor programs
---

# Blockchain Initialization

Initialize the local Solana validator and deploy Anchor smart contracts.

## Prerequisites
- Docker running (PostgreSQL, Redis)
- Solana CLI installed
- Anchor CLI installed
- Rust toolchain

## Quick Command

// turbo

```bash
./scripts/app.sh init
```

## Manual Steps

### 1. Start Solana Validator

```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa
solana-test-validator --reset --ledger ./test-ledger
```

Wait for validator to be ready:
```bash
solana cluster-version --url http://localhost:8899
```

### 2. Build Anchor Programs

```bash
cd gridtokenx-anchor
anchor build
```

### 3. Deploy Programs

Programs are deployed with fixed keypairs for consistent Program IDs:

```bash
cd gridtokenx-anchor

# Registry Program
solana program deploy \
  --program-id target/deploy/registry-keypair.json \
  target/deploy/registry.so \
  --url http://localhost:8899

# Energy Token Program
solana program deploy \
  --program-id target/deploy/energy_token-keypair.json \
  target/deploy/energy_token.so \
  --url http://localhost:8899

# Trading Program
solana program deploy \
  --program-id target/deploy/trading-keypair.json \
  target/deploy/trading.so \
  --url http://localhost:8899

# Oracle Program
solana program deploy \
  --program-id target/deploy/oracle-keypair.json \
  target/deploy/oracle.so \
  --url http://localhost:8899

# Governance Program
solana program deploy \
  --program-id target/deploy/governance-keypair.json \
  target/deploy/governance.so \
  --url http://localhost:8899
```

### 4. Bootstrap On-Chain Accounts

```bash
cd gridtokenx-anchor
export ANCHOR_PROVIDER_URL=http://localhost:8899
export ANCHOR_WALLET=target/deploy/registry-keypair.json

npx ts-node scripts/bootstrap.ts
```

### 5. Extract and Propagate PDAs

```bash
# Extract PDA addresses
npx ts-node scripts/get_pdas.ts

# This updates .env files with:
# - ENERGY_TOKEN_MINT
# - CURRENCY_TOKEN_MINT
# - REGISTRY_PDA
# - TRADING_MARKET_PDA
```

## Program IDs (Fixed)

| Program | Program ID |
|---------|------------|
| Registry | `FmvDiFUWsqo7z7XnVniKbZDcz32U5HSDVwPug89c` |
| Energy Token | `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` |
| Trading | `69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na` |
| Oracle | `JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop` |
| Governance | `DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4` |

## Verify Deployment

```bash
# Check program deployment
solana program show <PROGRAM_ID> --url http://localhost:8899

# Check account data
anchor account <PDA_ADDRESS> --url http://localhost:8899
```

## Troubleshooting

### Validator Won't Start
```bash
# Clean ledger and restart
rm -rf test-ledger
solana-test-validator --reset
```

### Deployment Fails
```bash
# Ensure validator is running
solana cluster-version --url http://localhost:8899

# Check SOL balance for fees
solana balance --url http://localhost:8899
```

### Programs Not Found
```bash
# Rebuild programs
cd gridtokenx-anchor
anchor clean
anchor build
```

## Related Workflows

- [Start Development](./start-dev.md) - Start validator and services
- [Testing](./testing.md) - Run Anchor tests
- [Admin Registration](./admin-register.md) - Register admin user
