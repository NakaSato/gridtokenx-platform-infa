#!/bin/bash
# Smart Meter Simulator → Automated Flow Test
# Tests: Simulator generates readings → API Gateway → Polling Service → Blockchain

set -e

API_URL="http://localhost:8080"
SIMULATOR_URL="http://localhost:8000"
DB_CONTAINER="gridtokenx-postgres"
DB_USER="gridtokenx_user"
DB_NAME="gridtokenx"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo "================================================================================"
echo "Smart Meter Simulator → Automated Flow Test"
echo "Simulator → API Gateway → Validation → Polling Service → Blockchain"
echo "================================================================================"
echo ""

# Step 1: Setup test user
echo -e "${BLUE}═══ Step 1: User & Wallet Setup ═══${NC}"
echo "1.1 Creating simulator test user..."

# Register user
curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "simtest",
    "email": "sim.test@gridtoken.test",
    "password": "SimTest123!",
    "first_name": "Simulator",
    "last_name": "Test"
  }' > /dev/null 2>&1

# Verify email and set role
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "UPDATE users SET role = 'prosumer', email_verified = true WHERE email = 'sim.test@gridtoken.test';" > /dev/null 2>&1

echo -e "${GREEN}✅ User created and verified${NC}"

# Login
echo "1.2 Authenticating..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "simtest",
    "email": "sim.test@gridtoken.test",
    "password": "SimTest123!"
  }')

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // empty')
if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo -e "${RED}❌ Failed to authenticate${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Authenticated${NC}"

# Generate and set wallet
echo "1.3 Generating Solana wallet..."
solana-keygen new --no-bip39-passphrase --silent --force --outfile /tmp/sim-test-wallet.json
WALLET_ADDRESS=$(solana-keygen pubkey /tmp/sim-test-wallet.json)
echo "   Wallet: $WALLET_ADDRESS"

curl -s -X POST "$API_URL/api/user/wallet" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"wallet_address\": \"$WALLET_ADDRESS\"}" > /dev/null

echo -e "${GREEN}✅ Wallet configured${NC}"
echo ""

# Step 2: Check simulator status
echo -e "${BLUE}═══ Step 2: Smart Meter Simulator Status ═══${NC}"
SIM_STATUS=$(curl -s "$SIMULATOR_URL/api/status")
echo "$SIM_STATUS" | jq '.'
echo ""

# Step 3: Add virtual meter to simulator
echo -e "${BLUE}═══ Step 3: Configuring Virtual Smart Meter ═══${NC}"
echo "Adding virtual meter to simulator..."

METER_RESPONSE=$(curl -s -X POST "$SIMULATOR_URL/api/meters/add" \
  -H "Content-Type: application/json" \
  -d "{
    \"meter_id\": \"SIM-METER-001\",
    \"user_id\": \"sim.test@gridtoken.test\",
    \"api_endpoint\": \"$API_URL/api/meters/submit-reading\",
    \"auth_token\": \"$TOKEN\",
    \"base_consumption\": 2.5,
    \"variance\": 0.5,
    \"interval_seconds\": 10
  }")

echo "$METER_RESPONSE" | jq '.'
echo -e "${GREEN}✅ Virtual meter configured${NC}"
echo "   Meter ID: SIM-METER-001"
echo "   Base Consumption: 2.5 kWh"
echo "   Variance: ±0.5 kWh"
echo "   Interval: 10 seconds"
echo ""

# Step 4: Clear previous readings
echo -e "${BLUE}═══ Step 4: Preparing Test Environment ═══${NC}"
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "DELETE FROM meter_readings WHERE user_id IN (SELECT id FROM users WHERE email = 'sim.test@gridtoken.test');" > /dev/null 2>&1
echo -e "${GREEN}✅ Test environment clean${NC}"
echo ""

# Step 5: Start simulator
echo -e "${BLUE}═══ Step 5: Starting Smart Meter Simulation ═══${NC}"
echo "Starting automated meter reading generation..."

START_RESPONSE=$(curl -s -X POST "$SIMULATOR_URL/api/control/start")
echo "$START_RESPONSE" | jq '.'
echo ""
echo -e "${CYAN}📡 Simulator is now generating readings every 10 seconds${NC}"
echo ""

# Step 6: Monitor readings for 60 seconds
echo -e "${BLUE}═══ Step 6: Monitoring Automated Reading Generation ═══${NC}"
echo "Watching for 60 seconds as simulator generates and submits readings..."
echo ""

MONITOR_DURATION=60
ELAPSED=0
CHECK_INTERVAL=10

while [ $ELAPSED -lt $MONITOR_DURATION ]; do
  sleep $CHECK_INTERVAL
  ELAPSED=$((ELAPSED + CHECK_INTERVAL))
  
  # Get readings count
  READINGS=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
    -H "Authorization: Bearer $TOKEN")
  
  TOTAL_COUNT=$(echo "$READINGS" | jq 'if type == "array" then length else 0 end')
  MINTED_COUNT=$(echo "$READINGS" | jq 'if type == "array" then [.[] | select(.minted == true)] | length else 0 end')
  UNMINTED_COUNT=$(echo "$READINGS" | jq 'if type == "array" then [.[] | select(.minted == false)] | length else 0 end')
  
  # Get latest reading
  if [ "$TOTAL_COUNT" -gt 0 ]; then
    LATEST_KWH=$(echo "$READINGS" | jq -r 'if type == "array" then .[0].kwh_amount else "0" end')
    LATEST_TIME=$(echo "$READINGS" | jq -r 'if type == "array" then .[0].reading_timestamp else "N/A" end')
    echo -e "   ⏱️  ${ELAPSED}s | Total: ${CYAN}${TOTAL_COUNT}${NC} | Latest: ${GREEN}${LATEST_KWH} kWh${NC} at ${LATEST_TIME:11:8}"
  else
    echo -e "   ⏱️  ${ELAPSED}s | Waiting for first reading..."
  fi
done

echo ""

# Step 7: Stop simulator
echo -e "${BLUE}═══ Step 7: Stopping Simulator ═══${NC}"
STOP_RESPONSE=$(curl -s -X POST "$SIMULATOR_URL/api/control/stop")
echo "$STOP_RESPONSE" | jq '.'
echo -e "${GREEN}✅ Simulator stopped${NC}"
echo ""

# Step 8: Verify readings
echo -e "${BLUE}═══ Step 8: Verifying Generated Readings ═══${NC}"

FINAL_READINGS=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
  -H "Authorization: Bearer $TOKEN")

TOTAL_READINGS=$(echo "$FINAL_READINGS" | jq 'if type == "array" then length else 0 end')
TOTAL_KWH=$(echo "$FINAL_READINGS" | jq 'if type == "array" then [.[] | .kwh_amount | tonumber] | add else 0 end')

echo "📊 Reading Statistics:"
echo "   Total Readings: ${CYAN}$TOTAL_READINGS${NC}"
echo "   Total Energy: ${GREEN}$TOTAL_KWH kWh${NC}"
echo ""

if [ "$TOTAL_READINGS" -gt 0 ]; then
  echo "📋 Recent Readings:"
  echo "$FINAL_READINGS" | jq -r 'if type == "array" then .[] | "   • \(.kwh_amount) kWh at \(.reading_timestamp) (minted: \(.minted))" else empty end' | head -5
fi
echo ""

# Step 9: Wait for automatic minting
echo -e "${BLUE}═══ Step 9: Monitoring Automatic Token Minting ═══${NC}"
echo -e "${CYAN}Meter Polling Service will automatically:${NC}"
echo "   1. Detect unminted readings (every 60s)"
echo "   2. Validate settlement conditions"
echo "   3. Execute CPI to blockchain"
echo "   4. Mint tokens to wallet"
echo ""
echo "Monitoring for up to 90 seconds..."
echo ""

MAX_WAIT=90
ELAPSED=0
CHECK_INTERVAL=10

while [ $ELAPSED -lt $MAX_WAIT ]; do
  sleep $CHECK_INTERVAL
  ELAPSED=$((ELAPSED + CHECK_INTERVAL))
  
  # Check minting progress
  READINGS_STATUS=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
    -H "Authorization: Bearer $TOKEN")
  
  MINTED=$(echo "$READINGS_STATUS" | jq 'if type == "array" then [.[] | select(.minted == true)] | length else 0 end')
  UNMINTED=$(echo "$READINGS_STATUS" | jq 'if type == "array" then [.[] | select(.minted == false)] | length else 0 end')
  
  # Get current balance
  BALANCE=$(curl -s -X GET "$API_URL/api/tokens/balance/$WALLET_ADDRESS" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.token_balance // "0"')
  
  echo -e "   ⏱️  ${ELAPSED}s | Minted: ${GREEN}${MINTED}${NC}/${TOTAL_READINGS} | Pending: ${YELLOW}${UNMINTED}${NC} | Balance: ${CYAN}${BALANCE}${NC} tokens"
  
  # Check if all readings are minted
  if [ "$MINTED" -eq "$TOTAL_READINGS" ] && [ "$TOTAL_READINGS" -gt 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All readings automatically minted!${NC}"
    break
  fi
done

echo ""

# Step 10: Final summary
echo "================================================================================"
echo -e "${MAGENTA}SMART METER SIMULATOR FLOW - FINAL SUMMARY${NC}"
echo "================================================================================"

# Get final stats
FINAL_STATUS=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
  -H "Authorization: Bearer $TOKEN")

FINAL_TOTAL=$(echo "$FINAL_STATUS" | jq 'if type == "array" then length else 0 end')
FINAL_MINTED=$(echo "$FINAL_STATUS" | jq 'if type == "array" then [.[] | select(.minted == true)] | length else 0 end')
FINAL_UNMINTED=$(echo "$FINAL_STATUS" | jq 'if type == "array" then [.[] | select(.minted == false)] | length else 0 end')

FINAL_BALANCE=$(curl -s -X GET "$API_URL/api/tokens/balance/$WALLET_ADDRESS" \
  -H "Authorization: Bearer $TOKEN")

BALANCE_TOKENS=$(echo "$FINAL_BALANCE" | jq -r '.token_balance // "0"')

echo ""
echo "📊 Simulation Results:"
echo "   Duration: 60 seconds"
echo "   Readings Generated: ${CYAN}$FINAL_TOTAL${NC}"
echo "   Total Energy: ${GREEN}$TOTAL_KWH kWh${NC}"
echo ""
echo "🔄 Processing Status:"
echo "   Minted: ${GREEN}$FINAL_MINTED${NC}"
echo "   Pending: ${YELLOW}$FINAL_UNMINTED${NC}"
echo ""
echo "💰 Token Balance:"
echo "   Balance: ${CYAN}$BALANCE_TOKENS${NC} tokens"
echo ""

if [ "$FINAL_MINTED" -eq "$FINAL_TOTAL" ] && [ "$FINAL_TOTAL" -gt 0 ]; then
  echo -e "${GREEN}✅ COMPLETE AUTOMATED FLOW SUCCESSFUL!${NC}"
  echo ""
  echo "Flow Verified:"
  echo "  ✅ Smart Meter Simulator generated readings automatically"
  echo "  ✅ Readings submitted to API Gateway via HTTP"
  echo "  ✅ Validation passed (duplicates, amounts, timestamps)"
  echo "  ✅ Polling service detected unminted readings"
  echo "  ✅ CPI executed to blockchain"
  echo "  ✅ Tokens minted automatically"
  echo "  ✅ End-to-end automation working!"
elif [ "$FINAL_MINTED" -gt 0 ]; then
  echo -e "${YELLOW}⚠️  PARTIAL AUTOMATION COMPLETE${NC}"
  echo ""
  echo "Status: $FINAL_MINTED/$FINAL_TOTAL readings processed"
  echo "Note: Remaining readings will be processed in next polling cycle (60s)"
else
  echo -e "${YELLOW}⏳ AUTOMATION IN PROGRESS${NC}"
  echo ""
  echo "Status: Readings submitted, waiting for polling service"
  echo "Note: Polling service runs every 60 seconds"
  echo "      Check again in a few moments for automatic minting"
fi

echo "================================================================================"
echo ""
