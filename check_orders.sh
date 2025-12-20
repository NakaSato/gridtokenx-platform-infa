#!/bin/bash
set -e

# Register Buyer 4
BUYER_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "buyer4", 
    "email": "buyer4@test.com", 
    "password": "password123", 
    "first_name": "Buyer", 
    "last_name": "Four"
  }' | jq -r '.auth.access_token')

echo "Buyer Token: ${BUYER_TOKEN:0:10}..."

# Create Order
echo "--- Create Buy Order ---"
curl -s -X POST http://127.0.0.1:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $BUYER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order_type": "Limit",
    "side": "Buy",
    "energy_amount": "1.0",
    "price_per_kwh": "6.0"
  }' | jq .

# Fetch Orders
echo -e "\n--- Fetching Orders ---"
curl -s -X GET http://127.0.0.1:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $BUYER_TOKEN" | jq .
