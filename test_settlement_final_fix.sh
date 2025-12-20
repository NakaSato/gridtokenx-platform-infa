#!/bin/bash
set -e

# Register Buyer 10/Seller 10
echo "--- Registering Users ---"
curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "buyer10", "email": "buyer10@test.com", "password": "password123", "first_name": "B", "last_name": "10"}'

curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "seller10", "email": "seller10@test.com", "password": "password123", "first_name": "S", "last_name": "10"}'

echo "Waiting 15s for Funding..."
sleep 15

# Login to get Tokens (Using correct /token endpoint)
echo "--- Logging In ---"
B_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username": "buyer10", "password": "password123"}' | jq -r '.access_token')

S_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username": "seller10", "password": "password123"}' | jq -r '.access_token')

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

echo "Orders Submitted. Monitoring for Settlement..."
