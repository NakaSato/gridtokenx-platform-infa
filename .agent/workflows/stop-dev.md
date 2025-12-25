---
description: Stop all development services for GridTokenX
---
# Stop Development

This workflow stops all running development services.

## Quick Command

// turbo
```bash
./scripts/stop-dev.sh
```

To stop everything including Docker services:
```bash
./scripts/stop-dev.sh --all
```

## Manual Steps

1. **Stop API Gateway**
```bash
pkill -f "api-gateway" 2>/dev/null || true
```

2. **Stop Solana Validator**
```bash
pkill -f "solana-test-validator" 2>/dev/null || true
```

3. **Stop Docker Services** (optional)
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa && docker-compose down
```

## Notes
- Database data persists in Docker volumes
- Solana state is reset on next start with `--reset` flag
- The stop script leaves Docker services running by default for faster restarts
