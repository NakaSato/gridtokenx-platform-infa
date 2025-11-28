# Solana Test Validator Docker Setup

This directory contains a Docker setup for running a Solana test validator for local development and testing.

## ⚠️ Apple Silicon (M1/M2/M3) Users

**The Solana validator does NOT work in Docker on Apple Silicon Macs** due to AVX CPU instruction requirements that aren't available in x86 emulation.

### Recommended: Run Natively on macOS

```bash
# 1. Install Solana CLI
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"

# 2. Add to PATH (add to ~/.zshrc for persistence)
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# 3. Run the test validator
solana-test-validator --reset
```

The validator will be available at:
- **RPC**: http://localhost:8899
- **WebSocket**: ws://localhost:8900

## x86/AMD64 Linux Users

For native x86/AMD64 Linux machines, you can use Docker:

### Quick Start

```bash
# Start the validator (use profile since it's optional)
docker-compose --profile solana up -d solana-test-validator

# View logs
docker-compose logs -f solana-test-validator
```

### Stop the Validator

```bash
docker-compose down solana-test-validator
```

### Reset Ledger (Clean Start)

```bash
# Stop and remove volumes
docker-compose down -v

# Start fresh
docker-compose --profile solana up -d solana-test-validator
```

## Features

- **Isolated test environment**: Run a local Solana validator without affecting your system
- **Persistent ledger**: Ledger data is stored in a Docker volume
- **Health checks**: Automatic health monitoring
- **Network integration**: Connects to the GridTokenX network

## Exposed Ports

| Port | Description |
|------|-------------|
| 8899 | JSON RPC endpoint |
| 8900 | WebSocket endpoint |
| 9900 | Faucet endpoint (for airdropping SOL) |

## Usage Examples

### Connect from Host Machine

```bash
# Set cluster to local
solana config set --url http://localhost:8899

# Check cluster info
solana cluster-version

# Airdrop SOL
solana airdrop 10
```

### Connect from Another Container

Use the service name as hostname:

```bash
solana config set --url http://solana-test-validator:8899
```

### JavaScript/TypeScript

```typescript
import { Connection } from '@solana/web3.js';

const connection = new Connection('http://localhost:8899', 'confirmed');
const version = await connection.getVersion();
console.log('Solana version:', version);
```

### Rust

```rust
use solana_client::rpc_client::RpcClient;

let rpc_url = "http://localhost:8899".to_string\(\)\;
let client = RpcClient::new(rpc_url);
let version = client.get_version().unwrap();
println!("Solana version: {:?}", version);
```

## Troubleshooting

### "missing AVX support" Error

This error occurs when running on ARM64 or in virtualized environments without AVX support. Run the validator natively instead of in Docker.

### Validator Won't Start

1. Check logs: `docker-compose logs solana-test-validator`
2. Ensure ports 8899, 8900, 9900 are not in use
3. Try resetting the ledger: `docker-compose down -v && docker-compose up -d`

### Out of Memory

Increase Docker memory allocation in Docker Desktop settings (recommended: 4GB+)

## References

- [Solana Test Validator Documentation](https://docs.solana.com/developing/test-validator)
- [Agave Docker Images](https://github.com/anza-xyz/agave/tree/master/docker-solana)
- [Solana CLI Reference](https://docs.solana.com/cli)
- [Anza Solana Install](https://www.anchor-lang.com/docs/installation)
