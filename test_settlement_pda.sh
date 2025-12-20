#!/bin/bash
set -e

# Register Buyer 8/Seller 8
echo "--- Registering Users (Funding Triggered) ---"
B_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "buyer8", "email": "buyer8@test.com", "password": "password123", "first_name": "B", "last_name": "7"}' | jq -r '.auth.access_token')

S_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "seller8", "email": "seller8@test.com", "password": "password123", "first_name": "S", "last_name": "7"}' | jq -r '.auth.access_token')

echo "Tokens Obtained. Sleeping 10s for Airdrop..."
sleep 10

# Create Sell Order
echo "--- Creating Sell Order ---"
curl -s -X POST http://127.0.0.1:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $S_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order_type": "Limit", "side": "Sell", "energy_amount": "1.0", "price_per_kwh": "6.0"}' | jq .

# Create Buy Order
echo "--- Creating Buy Order ---"
curl -s -X POST http://127.0.0.1:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $B_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order_type": "Limit", "side": "Buy", "energy_amount": "1.0", "price_per_kwh": "6.0"}' | jq .

echo "Orders Submitted. Waiting for Matching & Settlement..."
