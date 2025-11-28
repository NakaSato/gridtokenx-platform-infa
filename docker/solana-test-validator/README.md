# Solana Test Validator Docker Setup

This directory contains a Docker setup for running a Solana test validator for local development and testing.

## Features

- **Isolated test environment**: Run a local Solana validator without affecting your system
- **Persistent ledger**: Ledger data is stored in a Docker volume
- **Configurable version**: Easily change Solana version via build args
- **Health checks**: Automatic health monitoring
- **Network integration**: Connects to the GridTokenX network

## Quick Start

### Build and Run

```bash
# Build the image
docker-compose build

# Start the validator
docker-compose up -d

# View logs
docker-compose logs -f
```

### Stop the Validator

```bash
docker-compose down
```

### Reset Ledger (Clean Start)

```bash
# Stop and remove volumes
docker-compose down -v

# Start fresh
docker-compose up -d
```

## Configuration

### Change Solana Version

Edit the `SOLANA_VERSION` build arg in `docker-compose.yml`:

```yaml
build:
  args:
    SOLANA_VERSION: "1.18.22"  # Change to desired version
```

### Custom Validator Options

Modify the `CMD` in the Dockerfile to add custom flags:

```dockerfile
CMD ["solana-test-validator", \
     "--ledger", "/solana/ledger", \
     "--rpc-port", "8899", \
     "--reset", \              # Add --reset to start fresh each time
     "--limit-ledger-size", "50000000"]  # Limit ledger size
```

## Exposed Ports

- **8899**: JSON RPC endpoint
- **8900**: WebSocket endpoint
- **9900**: Faucet endpoint (for airdropping SOL)

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

let rpc_url = "http://localhost:8899".to_string();
let client = RpcClient::new(rpc_url);
let version = client.get_version().unwrap();
println!("Solana version: {:?}", version);
```

## Health Check

The validator includes a health check that runs every 30 seconds:

```bash
# Check health status
docker inspect solana-test-validator | grep -A 10 Health
```

## Troubleshooting

### Validator Won't Start

1. Check logs: `docker-compose logs`
2. Ensure ports 8899, 8900, 9900 are not in use
3. Try resetting the ledger: `docker-compose down -v && docker-compose up -d`

### Out of Memory

Increase Docker memory allocation in Docker Desktop settings (recommended: 4GB+)

### Ledger Size Growing Too Large

Add `--limit-ledger-size` flag to the validator command in the Dockerfile

## Integration with GridTokenX

This validator is designed to work with the GridTokenX platform. Ensure the `gridtokenx-network` Docker network exists:

```bash
docker network create gridtokenx-network
```

## References

- [Solana Test Validator Documentation](https://docs.solana.com/developing/test-validator)
- [Agave Docker Images](https://github.com/anza-xyz/agave/tree/master/docker-solana)
- [Solana CLI Reference](https://docs.solana.com/cli)
