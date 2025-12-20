---
description: Test API endpoints with curl commands
---
# Test API Endpoints

Quick tests for GridTokenX API endpoints.

## Prerequisites
- API Gateway running on localhost:4000

## Health Check
```bash
curl -s http://localhost:4000/health | jq
```

## Authentication

### Register User
```bash
curl -s -X POST http://localhost:4000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","username":"testuser"}' | jq
```

### Login
```bash
curl -s -X POST http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"testbuyer","password":"Test123!"}' | jq
```

## Trading (requires auth token)

### Get Order Book
```bash
curl -s http://localhost:4000/api/v1/trading/orderbook \
  -H "Authorization: Bearer $TOKEN" | jq
```

### Create Order
```bash
curl -s -X POST http://localhost:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"side":"Buy","amount":"50","price_per_kwh":"5.00"}' | jq
```

### Get My Orders
```bash
curl -s http://localhost:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $TOKEN" | jq
```

## Dev Faucet

### Airdrop SOL + Mint Tokens
```bash
curl -s -X POST http://localhost:4000/api/v1/dev/faucet \
  -H "Content-Type: application/json" \
  -d '{"wallet_address":"YOUR_WALLET","amount_sol":10,"mint_tokens_kwh":1000}' | jq
```

## Swagger Docs
Open in browser: http://localhost:4000/api/docs
