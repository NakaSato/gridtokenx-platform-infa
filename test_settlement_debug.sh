#!/bin/bash
set -e

# Register Buyer 5/Seller 5
B_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "buyer5", "email": "buyer5@test.com", "password": "password123", "first_name": "B", "last_name": "5"}' | jq -r '.auth.access_token')

S_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "seller5", "email": "seller5@test.com", "password": "password123", "first_name": "S", "last_name": "5"}' | jq -r '.auth.access_token')

# Create Sell
curl -s -o /dev/null -X POST http://127.0.0.1:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $S_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order_type": "Limit", "side": "Sell", "energy_amount": "1.0", "price_per_kwh": "6.0"}'

# Create Buy
curl -s -o /dev/null -X POST http://127.0.0.1:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $B_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order_type": "Limit", "side": "Buy", "energy_amount": "1.0", "price_per_kwh": "6.0"}'

echo "Orders Created"
