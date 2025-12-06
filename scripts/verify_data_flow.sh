#!/bin/bash

# ============================================================================
# GridTokenX Data Flow Verification (Simulator -> Gateway -> Solana)
# ============================================================================

set -e

# Configuration
API_URL="${API_URL:-http://localhost:8080}"
SIMULATOR_URL="${SIMULATOR_URL:-http://localhost:8000}"
DB_CONTAINER="${DB_CONTAINER:-gridtokenx-postgres}"
DB_USER="${DB_USER:-gridtokenx_user}"
DB_NAME="${DB_NAME:-gridtokenx}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test Variables
TIMESTAMP=$(date +%s)
USER_EMAIL="flowtest_${TIMESTAMP}@example.com"
USERNAME="flowUser_${TIMESTAMP}"
PASSWORD="StrongPass${TIMESTAMP}!"
METER_ID=""
USER_ID=""
TOKEN=""
WALLET_ADDRESS=""

print_step() {
    echo -e "\n${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

get_json_field() {
    echo "$1" | jq -r ".$2 // empty" 2>/dev/null || echo ""
}

db_exec() {
    docker exec ${DB_CONTAINER} psql -U ${DB_USER} -d ${DB_NAME} -c "$1" > /dev/null 2>&1
}

db_query() {
    docker exec ${DB_CONTAINER} psql -U ${DB_USER} -d ${DB_NAME} -t -c "$1" 2>/dev/null | tr -d ' \n'
}

# ============================================================================
# 1. Setup & Registration
# ============================================================================

print_step "1. Creating User & Meter..."

# Register User
RES=$(curl -s -X POST "${API_URL}/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"${USER_EMAIL}\",
        \"username\": \"${USERNAME}\",
        \"password\": \"${PASSWORD}\",
        \"first_name\": \"Flow\",
        \"last_name\": \"Tester\"
    }")

# Force Verify Email
db_exec "UPDATE users SET email_verified = true, email_verified_at = NOW() WHERE email = '${USER_EMAIL}';"

# Login to create wallet
LOGIN_RES=$(curl -s -X POST "${API_URL}/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\"}")

TOKEN=$(get_json_field "$LOGIN_RES" "access_token")
USER_ID=$(db_query "SELECT id FROM users WHERE email='${USER_EMAIL}';")
WALLET_ADDRESS=$(db_query "SELECT wallet_address FROM users WHERE id='${USER_ID}';")

if [ -z "$TOKEN" ]; then
    print_error "Login failed"
    echo "Response: $LOGIN_RES"
    exit 1
fi
print_success "User logged in & Wallet created: $WALLET_ADDRESS"

# Create Meter in Simulator
METER_RES=$(curl -s -X POST "${SIMULATOR_URL}/api/meters/add" \
    -H "Content-Type: application/json" \
    -d "{
        \"meter_type\": \"Solar_Prosumer\",
        \"location\": \"Flow Test\",
        \"solar_capacity\": 20.0,
        \"wallet_address\": \"${WALLET_ADDRESS}\"
    }")

METER_ID=$(get_json_field "$METER_RES" "meter.meter_id")
METER_PUBKEY=$(get_json_field "$METER_RES" "meter.meter_public_key")

if [ -z "$METER_ID" ]; then
    print_error "Failed to create meter in simulator"
    echo "Response: $METER_RES"
    exit 1
fi
print_success "Meter created in Simulator: $METER_ID (Key: ${METER_PUBKEY:0:10}...)"

# Link Meter to User
LINK_RES=$(curl -s -X POST "${API_URL}/api/user/meters" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
        \"meter_serial\": \"${METER_ID}\",
        \"meter_type\": \"Solar_Prosumer\",
        \"meter_public_key\": \"${METER_PUBKEY}\"
    }")

# Verify in DB (Admin override)
db_exec "UPDATE meter_registry SET verification_status = 'verified', verified_at = NOW() WHERE meter_serial = '${METER_ID}';"
print_success "Meter linked & verified in Gateway"

# ============================================================================
# 2. Start Simulation & Wait for Data
# ============================================================================

print_step "2. Starting Simulation & Waiting for Data..."

# Ensure simulator is running
curl -s -X POST "${SIMULATOR_URL}/api/control/start" > /dev/null

echo "Waiting 30 seconds for simulator to generate and send readings..."
# Simulator runs tick every ~5s real time (configured in engine.py: self.real_time_interval)
for i in {1..6}; do
    echo -n "."
    sleep 5
done
echo ""

# ============================================================================
# 3. Verify Data Flow
# ============================================================================

print_step "3. Verifying Data Flow..."

# Check Gateway DB for readings
READING_COUNT=$(db_query "SELECT COUNT(*) FROM meter_readings WHERE meter_id = (SELECT id FROM meter_registry WHERE meter_serial = '${METER_ID}');")
MINTED_COUNT=$(db_query "SELECT COUNT(*) FROM meter_readings WHERE meter_id = (SELECT id FROM meter_registry WHERE meter_serial = '${METER_ID}') AND minted = true;")

echo "Readings received: $READING_COUNT"
echo "Minted readings: $MINTED_COUNT"

if [ "$READING_COUNT" -gt 0 ]; then
    print_success "Data Flow Simulator -> Gateway: SUCCESS"
else
    print_error "No readings found in Gateway DB"
    exit 1
fi

if [ "$MINTED_COUNT" -gt 0 ]; then
    print_success "Data Flow Gateway -> Solana: SUCCESS (Minted Tokens)"
else
    print_error "No readings were minted! Check logs for blockchain errors."
    exit 1
fi

echo -e "\n${GREEN}deprecated: VERIFICATION SUCCESSFUL${NC}"
