#!/bin/bash
API_URL="http://localhost:4000/api/v1"
TIMESTAMP=$(date +%s)
EMAIL="demo_user_${TIMESTAMP}@example.com"
USERNAME="DemoUser_${TIMESTAMP}"
PASSWORD="StrongP@ssw0rd_2025!"

echo "==========================================="
echo "DEMO: User & Meter Registration Flow via Curl"
echo "==========================================="

# 1. Register User
echo -e "\n1. Registering User ($USERNAME / $EMAIL)..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\", \"username\": \"$USERNAME\", \"first_name\": \"Demo\", \"last_name\": \"User\"}")

echo "$REGISTER_RESPONSE" | jq .

# Extract token from registration response first
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.auth.access_token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo -e "\n⚠️  No token in registration (maybe email verification required?). Trying explicit login..."
    
    # 2. Login (Fallback)
    echo -e "\n2. Logging In..."
    LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/token" \
      -H "Content-Type: application/json" \
      -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")
      
    echo "$LOGIN_RESPONSE" | jq .
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // empty')
else
    echo -e "\n✅ Token acquired from registration response."
fi


if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "❌ Failed to get access token."
  exit 1
fi
echo "🔑 Token: ${TOKEN:0:15}..."

# 3. Register Meter
METER_SERIAL="METER-$TIMESTAMP"
echo -e "\n3. Registering Meter ($METER_SERIAL)..."
METER_RESPONSE=$(curl -s -X POST "$API_URL/meters" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"serial_number\": \"$METER_SERIAL\", \"meter_type\": \"Solar\", \"location\": \"Demo Location\"}")

echo "$METER_RESPONSE" | jq .

# 4. Verify Meter Listing
echo -e "\n4. Verifying Meter Listing..."
LIST_RESPONSE=$(curl -s -X GET "$API_URL/users/me/meters" \
  -H "Authorization: Bearer $TOKEN")

echo "$LIST_RESPONSE" | jq .

echo -e "\n==========================================="
echo "🎉 Demo Complete"
