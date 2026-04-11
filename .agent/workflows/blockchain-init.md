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

### 2. Deploy Anchor Programs
Use the Anchor CLI from the `gridtokenx-anchor` directory. 

| Program | Program ID (from Anchor.toml) |
|---------|------------|
| **Registry** | `FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c` |
| **Energy Token** | `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` |
| **Trading** | `69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na` |
| **Oracle** | `JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop` |
| **Governance** | `DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4` |

```bash
cd gridtokenx-anchor
anchor deploy
```

### 3. Account Bootstrapping
After deployment, several on-chain "PDA" (Program Derived Address) accounts must be initialized (e.g., Energy Mint, Global Config).

```bash
cd gridtokenx-anchor
# Initialize registry and global settings
npx tsx scripts/init-registry.ts
# Initialize energy tokens and pools
npx ts-node scripts/mint-tokens.ts
```

## Propagation
Once initialized, the generated PDA addresses and Mint IDs must be updated in the platform's `.env` files.
- `REGISTRY_PDA`
- `ENERGY_TOKEN_MINT`
- `TRADING_CONFIG_PDA`

These are typically extracted by `app.sh init` automatically.

## Troubleshooting

- **Deployment Failed (Balance)**: Your deployer wallet needs local SOL. Run `solana airdrop 5`.
- **Program ID Mismatch**: Ensure `Anchor.toml` and the code in `programs/*/src/lib.rs` use the same ID string.
- **Validator Stalled**: Run `pkill -f solana-test-validator` and delete `test-ledger/`.

## Related Workflows
- [Anchor Development](./anchor-development.md) - Modifying smart contracts.
- [Trading Service](./trading-service-development.md) - Using the deployed contracts for settlement.
- [Start Development](./start-dev.md) - Regular development cycle.
