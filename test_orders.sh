#!/bin/bash
set -e

echo "--- Login Buyer ---"
BUYER_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"email": "buyer@test.com", "password": "password123"}' | jq -r '.token')
echo "Buyer Token: ${BUYER_TOKEN:0:10}..."

echo "--- Login Seller ---"
SELLER_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"email": "seller@test.com", "password": "password123"}' | jq -r '.token')
echo "Seller Token: ${SELLER_TOKEN:0:10}..."

echo "--- Create Sell Order ---"
curl -v -X POST http://127.0.0.1:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $SELLER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order_type": "Limit",
    "side": "Sell",
    "energy_amount": "1.0",
    "price_per_kwh": "6.0"
  }'

echo -e "\n--- Create Buy Order ---"
curl -v -X POST http://127.0.0.1:4000/api/v1/trading/orders \
  -H "Authorization: Bearer $BUYER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order_type": "Limit",
    "side": "Buy",
    "energy_amount": "1.0",
    "price_per_kwh": "6.0"
  }'
