#!/bin/bash
# Verify Landed Cost Matching Engine

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

API_URL="http://127.0.0.1:4000"
TS=$(date +%s)

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    GridTokenX Landed Cost Verification                   ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

# Helper to create user, update role, and login
setup_user() {
    local role=$1
    local username="u_${role}_${TS}"
    local email="${username}@example.com"
    
    # 1. Register
    REG_RESP=$(curl -s -X POST "$API_URL/api/v1/users" \
      -H "Content-Type: application/json" \
      -d "{\"email\": \"$email\", \"password\": \"TestPass123!\", \"username\": \"$username\", \"first_name\": \"Test\", \"last_name\": \"$role\"}")
    
    # 2. Update role in DB
    docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c "UPDATE users SET role = 'admin' WHERE email = '$email';" > /dev/null
    
    # 3. Login
    LOGIN_RESP=$(curl -s -X POST "$API_URL/api/v1/auth/token" \
      -H "Content-Type: application/json" \
      -d "{\"email\": \"$email\", \"password\": \"TestPass123!\"}")
    
    TOKEN=$(echo $LOGIN_RESP | jq -r '.access_token')
    USER_ID=$(echo $LOGIN_RESP | jq -r '.user.id' || echo "null")
    
    if [ "$TOKEN" == "null" ]; then
        TOKEN=$(echo $REG_RESP | jq -r '.auth.access_token')
        USER_ID=$(echo $REG_RESP | jq -r '.auth.user.id')
    fi

    echo "$TOKEN:$USER_ID"
}

register_meter() {
    local token=$1
    local serial=$2
    local zone=$3
    
    RESP=$(curl -s -X POST "$API_URL/api/v1/meters" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $token" \
      -d "{\"serial_number\": \"$serial\", \"location\": \"Zone $zone\", \"meter_type\": \"residential\"}")
    
    M_ID=$(echo $RESP | jq -r '.meter.id')
    
    docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c "UPDATE meters SET is_verified = true, zone_id = $zone WHERE id = '$M_ID';" > /dev/null
    docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c "UPDATE meter_registry SET zone_id = $zone WHERE id = '$M_ID';" > /dev/null
    
    echo $M_ID
}

echo -e "${YELLOW}Setting up users...${NC}"
S_L_DATA=$(setup_user "SL")
S_L_TOKEN=$(echo $S_L_DATA | cut -d':' -f1)
S_L_ID=$(echo $S_L_DATA | cut -d':' -f2)
echo "Seller Local: $S_L_ID"

S_R_DATA=$(setup_user "SR")
S_R_TOKEN=$(echo $S_R_DATA | cut -d':' -f1)
S_R_ID=$(echo $S_R_DATA | cut -d':' -f2)
echo "Seller Remote: $S_R_ID"

B_DATA=$(setup_user "B")
B_TOKEN=$(echo $B_DATA | cut -d':' -f1)
B_ID=$(echo $B_DATA | cut -d':' -f2)
echo "Buyer: $B_ID"

echo -e "${YELLOW}Configuring zones and balances...${NC}"
docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c "UPDATE users SET balance = 1000 WHERE id = '$B_ID';" > /dev/null

M_SL=$(register_meter "$S_L_TOKEN" "MS-L-$TS" 1)
M_SR=$(register_meter "$S_R_TOKEN" "MS-R-$TS" 2)
M_B=$(register_meter "$B_TOKEN" "MB-1-$TS" 1)

echo -e "${YELLOW}Creating orders...${NC}"
# Seller Local: 10 kWh @ 5.0 in Zone 1 (Landed 5.35)
curl -s -X POST "$API_URL/api/v1/trading/orders" -H "Content-Type: application/json" -H "Authorization: Bearer $S_L_TOKEN" \
  -d "{\"side\": \"sell\", \"order_type\": \"limit\", \"energy_amount\": \"10\", \"price_per_kwh\": \"5.0\", \"meter_id\": \"$M_SL\", \"zone_id\": 1}" > /dev/null

# Seller Remote: 10 kWh @ 3.0 in Zone 2 (Landed 5.8)
curl -s -X POST "$API_URL/api/v1/trading/orders" -H "Content-Type: application/json" -H "Authorization: Bearer $S_R_TOKEN" \
  -d "{\"side\": \"sell\", \"order_type\": \"limit\", \"energy_amount\": \"10\", \"price_per_kwh\": \"3.0\", \"meter_id\": \"$M_SR\", \"zone_id\": 2}" > /dev/null

# Buyer: 10 kWh @ 6.0 in Zone 1
curl -s -X POST "$API_URL/api/v1/trading/orders" -H "Content-Type: application/json" -H "Authorization: Bearer $B_TOKEN" \
  -d "{\"side\": \"buy\", \"order_type\": \"limit\", \"energy_amount\": \"10\", \"price_per_kwh\": \"6.0\", \"zone_id\": 1}" > /dev/null

echo -e "${YELLOW}Triggering Matching Engine...${NC}"
# Wait a bit for background matching or trigger manually
sleep 2
curl -s -X POST "$API_URL/api/v1/trading/admin/match-orders" -H "Authorization: Bearer $B_TOKEN" -H "Content-Type: application/json" > /dev/null

echo -e "${YELLOW}Verifying results...${NC}"
sleep 2
TRADES=$(curl -s -X GET "$API_URL/api/v1/trading/trades" -H "Authorization: Bearer $B_TOKEN")
MATCHED=$(echo $TRADES | jq -r '.[0].seller_id')

if [ "$MATCHED" == "$S_L_ID" ]; then
    echo -e "${GREEN}✅ SUCCESS: Buyer matched with Local Seller (lower landed cost).${NC}"
elif [ "$MATCHED" == "$S_R_ID" ]; then
    echo -e "${RED}❌ FAILURE: Buyer matched with Remote Seller (lower base price but higher landed cost).${NC}"
else
    echo -e "${RED}❌ FAILURE: No trades matched.${NC}"
    echo "Response: $TRADES"
fi
