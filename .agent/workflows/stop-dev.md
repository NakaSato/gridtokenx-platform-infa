---
description: Stop all development services for GridTokenX
---
# Stop Development

This workflow stops all running development services.

## Steps

1. **Stop Frontend**
Kill the npm dev server process.

2. **Stop API Gateway**
Kill the cargo run process.

3. **Stop Solana Validator**
```bash
pkill -f "solana-test-validator" || true
```

4. **Stop Docker Services** (optional)
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa && docker-compose down
```

## Notes
- Database data persists in Docker volumes
- Solana state is reset on next start with `--reset` flag
