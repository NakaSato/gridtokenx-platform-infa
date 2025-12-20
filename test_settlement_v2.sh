#!/bin/bash
set -e

# 1. Register Buyer 2
echo "--- Register Buyer 2 ---"
curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "buyer2", 
    "email": "buyer2@test.com", 
    "password": "password123", 
    "first_name": "Buyer", 
    "last_name": "Two"
  }'

# 2. Register Seller 2
echo -e "\n--- Register Seller 2 ---"
curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "seller2", 
    "email": "seller2@test.com", 
    "password": "password123", 
    "first_name": "Seller", 
    "last_name": "Two"
  }'

# 3. Login Buyer 2
echo -e "\n--- Login Buyer 2 ---"
BUYER_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username": "buyer2", "password": "password123"}' | jq -r '.token')
echo "Buyer Token: ${BUYER_TOKEN:0:10}..."

# 4. Login Seller 2
echo "--- Login Seller 2 ---"
SELLER_TOKEN=$(curl -s -X POST http://127.0.0.1:4000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username": "seller2", "password": "password123"}' | jq -r '.token')
echo "Seller Token: ${SELLER_TOKEN:0:10}..."

# 5. Create Sell Order
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

# 6. Create Buy Order
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
