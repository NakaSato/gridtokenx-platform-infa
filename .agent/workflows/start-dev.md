---
description: Start all development services for GridTokenX
---
# Start Development

This workflow starts all required services for local development.

## Prerequisites
- Docker running (for PostgreSQL/Redis)
- Solana CLI installed
- Node.js and Cargo installed

## Steps

// turbo-all

1. **Start Database Services** (if not running)
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa && docker-compose up -d postgres redis
```

2. **Start Solana Validator**
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa && solana-test-validator --reset &
```

3. **Wait for Validator**
Wait 5 seconds for the validator to start.

4. **Airdrop SOL to Dev Wallet**
```bash
solana airdrop 100 AmeT4PvH96gx8AiuLkpjsX9ExA21oH2HtthgbvzDgnD3 --url localhost
```

5. **Deploy Anchor Programs**
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-anchor && anchor deploy
```

6. **Bootstrap Programs**
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-anchor && anchor run bootstrap
```

7. **Start API Gateway**
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-apigateway && cargo run --bin api-gateway &
```

8. **Start Frontend**
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-trading && npm run dev &
```

## Verification
- Frontend: http://localhost:3000
- API Gateway: http://localhost:4000/health
- Solana: http://localhost:8899
