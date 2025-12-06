#!/bin/bash

# Configuration
API_URL="http://localhost:8080"
EMAIL="testuser_$(date +%s)@example.com"
PASSWORD="StrongP@ssw0rd2025!"
METER_SERIAL="METER-$(date +%s)"

echo "Testing End-to-End Minting Flow"
echo "API URL: $API_URL"
echo "Email: $EMAIL"

# 1. Register User
echo "1. Registering User..."
USERNAME="user_$(date +%s)"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"$USERNAME\",
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"first_name\": \"Test\",
    \"last_name\": \"User\"
  }")
echo "Register Response: $REGISTER_RESPONSE"

# 1.5 Verify User in DB (Bypass email verification)
echo "1.5 Verifying User in DB..."
docker exec gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c "UPDATE users SET email_verified = true, role = 'prosumer' WHERE email = '$EMAIL';"


# 2. Login
echo "2. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"$USERNAME\",
    \"password\": \"$PASSWORD\"
  }")
echo "Login Response: $LOGIN_RESPONSE"
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token')
echo "Token: ${TOKEN:0:10}..."

if [ "$TOKEN" == "null" ]; then
  echo "Login failed!"
  exit 1
fi

# 3. Update Wallet Address (Required for minting)
# Generate unique wallet address
WALLET_ADDRESS=$(docker exec gridtokenx-trading node -e 'const { Keypair } = require("@solana/web3.js"); console.log(Keypair.generate().publicKey.toBase58())')

echo "3. Updating Wallet Address to $WALLET_ADDRESS..."
curl -s -X POST "$API_URL/api/user/wallet" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"wallet_address\": \"$WALLET_ADDRESS\"
  }"
echo ""

# 4. Register Meter
echo "4. Registering Meter..."
METER_RESPONSE=$(curl -s -X POST "$API_URL/api/user/meters" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"meter_serial\": \"$METER_SERIAL\",
    \"meter_type\": \"smart_meter\",
    \"installation_date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  }")
echo "Meter Response: $METER_RESPONSE"
METER_ID=$(echo $METER_RESPONSE | jq -r '.meter_id')
echo "Meter ID: $METER_ID"

if [ "$METER_ID" == "null" ]; then
  echo "Meter registration failed!"
  exit 1
fi

# 4.5 Verify Meter in DB (Bypass admin verification)
echo "4.5 Verifying Meter in DB..."
docker exec gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c "UPDATE meter_registry SET verification_status = 'verified' WHERE meter_serial = '$METER_SERIAL';"

# 5. Submit Reading
echo "5. Submitting Reading..."
READING_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
READING_RESPONSE=$(curl -s -X POST "$API_URL/api/meters/submit-reading" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"meter_id\": \"$METER_ID\",
    \"kwh_amount\": 10.5,
    \"reading_timestamp\": \"$READING_TIME\"
  }")
echo "Reading Response: $READING_RESPONSE"

# 6. Wait for Minting
echo "6. Waiting for Minting (polling every 5s)..."
for i in {1..12}; do
  STATS_RESPONSE=$(curl -s -X GET "$API_URL/api/meters/stats" \
    -H "Authorization: Bearer $TOKEN")
  
  MINTED_KWH=$(echo $STATS_RESPONSE | jq -r '.minted_kwh')
  UNMINTED_KWH=$(echo $STATS_RESPONSE | jq -r '.unminted_kwh')
  
  echo "Attempt $i: Minted: $MINTED_KWH, Unminted: $UNMINTED_KWH"
  
  if (( $(echo "$MINTED_KWH > 0" | bc -l) )); then
    echo "SUCCESS: Tokens minted!"
    echo "Final Stats: $STATS_RESPONSE"
    exit 0
  fi
  
  sleep 5
done

echo "TIMEOUT: Tokens not minted within 60 seconds."
exit 1
