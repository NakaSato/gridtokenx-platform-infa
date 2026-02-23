#!/bin/bash
set -e

echo "Registering Buyer..."
BUYER_RES=$(curl -s -X POST http://localhost:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"buyer2","email":"buyer2@test.com","password":"Test!123","first_name":"Jane","last_name":"Buyer"}')

BUYER_TOKEN=$(curl -s -X POST http://localhost:4000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"buyer2","password":"Test!123"}' | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))")

echo "Buyer Token length: ${#BUYER_TOKEN}"

# Generate wallet
echo "Generating Wallet for Buyer..."
curl -s -X POST http://localhost:4000/api/v1/users/wallet/generate \
  -H "Authorization: Bearer $BUYER_TOKEN" \
  -H "Content-Type: application/json"

echo -e "\nRegistering Meter for Buyer..."
curl -s -X POST http://localhost:4000/api/v1/meters \
  -H "Authorization: Bearer $BUYER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"serial_number":"METER-BUYER2","meter_type":"Consumer_Only","location":"Test Building 2","latitude":13.7,"longitude":100.5,"zone_id":1}'

echo -e "\n\nRegistering Seller..."
SELLER_RES=$(curl -s -X POST http://localhost:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"seller1","email":"seller1@test.com","password":"Test!123","first_name":"John","last_name":"Seller"}')

SELLER_TOKEN=$(curl -s -X POST http://localhost:4000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"seller1","password":"Test!123"}' | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))")

echo "Seller Token length: ${#SELLER_TOKEN}"

echo "Generating Wallet for Seller..."
curl -s -X POST http://localhost:4000/api/v1/users/wallet/generate \
  -H "Authorization: Bearer $SELLER_TOKEN" \
  -H "Content-Type: application/json"

echo -e "\nRegistering Meter for Seller..."
curl -s -X POST http://localhost:4000/api/v1/meters \
  -H "Authorization: Bearer $SELLER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"serial_number":"METER-SELLER1","meter_type":"Solar_Prosumer","location":"Solar Farm 1","latitude":13.8,"longitude":100.6,"zone_id":1}'

