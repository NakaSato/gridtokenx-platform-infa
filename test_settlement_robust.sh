#!/bin/bash
set -e

# Register Buyer 9/Seller 9
echo "--- Registering Users ---"
B_RESP=$(curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "buyer9", "email": "buyer9@test.com", "password": "password123", "first_name": "B", "last_name": "9"}')
B_TOKEN=$(echo $B_RESP | jq -r '.auth.access_token')
B_WALLET=$(echo $B_RESP | jq -r '.user.wallet_address')

S_RESP=$(curl -s -X POST http://127.0.0.1:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "seller9", "email": "seller9@test.com", "password": "password123", "first_name": "S", "last_name": "9"}')
S_TOKEN=$(echo $S_RESP | jq -r '.auth.access_token')
S_WALLET=$(echo $S_RESP | jq -r '.user.wallet_address')

echo "Buyer Wallet: $B_WALLET"
echo "Seller Wallet: $S_WALLET"

# Wait for Funding
echo "--- Waiting for Funding ---"
for i in {1..30}; do
  BAL=$(solana balance $B_WALLET --url http://127.0.0.1:8899 | awk '{print $1}')
  echo "Buyer Balance: $BAL SOL"
  if [[ "$BAL" != "0" && "$BAL" != "0.000000000" && "$BAL" != "" ]]; then
    echo "Funding Confirmed!"
    break
  fi
  sleep 2
done

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
