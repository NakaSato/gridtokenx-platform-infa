#!/bin/bash
set -e

API_URL="http://localhost:4000"
SIM_URL="http://localhost:8005"
USERNAME="seller"
PASSWORD="Gr1dT0k3n\$eller!"
METER_TYPE="Solar_Prosumer"

echo "Logging in as $USERNAME..."
LOGIN_RES=$(curl -s -X POST "$API_URL/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")

TOKEN=$(echo "$LOGIN_RES" | jq -r '.access_token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "❌ Failed to login."
    echo "$LOGIN_RES"
    exit 1
fi
echo "✅ Logged in."

# Retrieve User Wallet Address from DB for consistency
WALLET_ADDRESS=$(docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -t -c "SELECT wallet_address FROM users WHERE username = '$USERNAME';" | xargs)
echo "✅ Wallet Address: $WALLET_ADDRESS"

echo "Requesting New Meter from Simulator..."
# We do NOT provide meter_id, letting Simulator generate it.
SIM_RES=$(curl -s -X POST "$SIM_URL/api/meters/add" \
  -H "Content-Type: application/json" \
  -d "{
    \"meter_type\": \"$METER_TYPE\",
    \"location\": \"Auto-Simulator-Location\",
    \"solar_capacity\": 5.0,
    \"battery_capacity\": 10.0,
    \"trading_preference\": \"Aggressive\",
    \"wallet_address\": \"$WALLET_ADDRESS\"
  }")

SIM_SUCCESS=$(echo "$SIM_RES" | jq -r '.success // false')

if [ "$SIM_SUCCESS" != "true" ]; then
    echo "❌ Failed to add meter to Simulator."
    echo "$SIM_RES"
    exit 1
fi

METER_ID=$(echo "$SIM_RES" | jq -r '.meter.meter_id')
METER_PUBKEY=$(echo "$SIM_RES" | jq -r '.meter.meter_public_key')

echo "✅ Simulator Created Meter: $METER_ID"
echo "   Public Key: $METER_PUBKEY"

echo "Registering Meter on Platform..."
METER_RES=$(curl -s -X POST "$API_URL/api/v1/meters" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"serial_number\": \"$METER_ID\", \"meter_type\": \"$METER_TYPE\", \"location\": \"Auto-Simulator-Location\", \"manufacturer\": \"GridTokenX\", \"installation_date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"meter_public_key\": \"$METER_PUBKEY\"}")

PLATFORM_ID=$(echo "$METER_RES" | jq -r '.meter.id // empty')

if [ -z "$PLATFORM_ID" ] || [ "$PLATFORM_ID" == "null" ]; then
    echo "❌ Failed to register meter on Platform."
    echo "$METER_RES"
    # IMPORTANT: Since sim added it but platform failed, we might want to cleanup sim? 
    # For now, just exit.
    exit 1
fi
echo "✅ Meter Registered on Platform: $PLATFORM_ID"

echo "Auto-verifying meter in DB..."
docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c \
    "UPDATE meter_registry SET verification_status = 'verified', verified_at = NOW() WHERE id = '$PLATFORM_ID';" > /dev/null
echo "✅ Meter Verified in DB."

echo "Success! Meter $METER_ID is fully integrated."
