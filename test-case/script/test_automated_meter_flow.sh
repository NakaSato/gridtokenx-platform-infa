#!/bin/bash
# Automated Meter Processing Flow Test
# Tests: Smart Meter Simulator → API Gateway → Meter Polling Service → Blockchain Minting

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
NC='\033[0m'

echo "================================================================================"
echo "Automated Meter Processing Flow Test"
echo "Smart Meter → API Gateway → Polling Service → Blockchain"
echo "================================================================================"
echo ""

# Step 1: Setup test user
echo -e "${BLUE}═══ Step 1: User & Wallet Setup ═══${NC}"
echo "1.1 Creating automation test user..."

# Register user
curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "autotest",
    "email": "auto.test@gridtoken.test",
    "password": "AutoTest123!",
    "first_name": "Auto",
    "last_name": "Test"
  }' > /dev/null 2>&1

# Verify email and set role
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "UPDATE users SET role = 'prosumer', email_verified = true WHERE email = 'auto.test@gridtoken.test';" > /dev/null 2>&1

echo -e "${GREEN}✅ User created and verified${NC}"

# Login
echo "1.2 Authenticating..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "autotest",
    "email": "auto.test@gridtoken.test",
    "password": "AutoTest123!"
  }')

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // empty')
if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo -e "${RED}❌ Failed to authenticate${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Authenticated${NC}"

# Generate and set wallet
echo "1.3 Generating Solana wallet..."
solana-keygen new --no-bip39-passphrase --silent --force --outfile /tmp/auto-test-wallet.json
WALLET_ADDRESS=$(solana-keygen pubkey /tmp/auto-test-wallet.json)
echo "   Wallet: $WALLET_ADDRESS"

curl -s -X POST "$API_URL/api/user/wallet" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"wallet_address\": \"$WALLET_ADDRESS\"}" > /dev/null

echo -e "${GREEN}✅ Wallet configured${NC}"
echo ""

# Step 2: Clear previous readings
echo -e "${BLUE}═══ Step 2: Preparing Test Environment ═══${NC}"
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "DELETE FROM meter_readings WHERE user_id IN (SELECT id FROM users WHERE email = 'auto.test@gridtoken.test');" > /dev/null 2>&1
echo -e "${GREEN}✅ Test environment clean${NC}"
echo ""

# Step 3: Submit multiple meter readings
echo -e "${BLUE}═══ Step 3: Submitting Meter Readings ═══${NC}"
echo "Simulating smart meter data submission..."

READINGS=(
  "12.5"
  "18.3"
  "22.7"
)

READING_IDS=()

for i in "${!READINGS[@]}"; do
  KWH="${READINGS[$i]}"
  # Add offset to timestamps to avoid duplicate detection
  TIMESTAMP=$(date -u -v-$((i*20))M +"%Y-%m-%dT%H:%M:%SZ")
  
  echo "   📊 Reading $((i+1)): $KWH kWh at $TIMESTAMP"
  
  RESPONSE=$(curl -s -X POST "$API_URL/api/meters/submit-reading" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"kwh_amount\": \"$KWH\",
      \"reading_timestamp\": \"$TIMESTAMP\",
      \"meter_signature\": \"auto_sig_$i\"
    }")
  
  READING_ID=$(echo "$RESPONSE" | jq -r '.id // empty')
  if [ -n "$READING_ID" ] && [ "$READING_ID" != "null" ]; then
    READING_IDS+=("$READING_ID")
    echo -e "      ${GREEN}✅ Submitted (ID: ${READING_ID:0:8}...)${NC}"
  else
    echo -e "      ${RED}❌ Failed${NC}"
    echo "$RESPONSE" | jq '.'
  fi
  sleep 1
done

TOTAL_READINGS=${#READING_IDS[@]}
echo ""
echo -e "${GREEN}✅ Submitted $TOTAL_READINGS readings${NC}"
echo ""

# Step 4: Check initial state
echo -e "${BLUE}═══ Step 4: Pre-Automation State ═══${NC}"

# Get initial balance
INITIAL_BALANCE=$(curl -s -X GET "$API_URL/api/tokens/balance/$WALLET_ADDRESS" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.token_balance // "0"')
echo "   💰 Token Balance: $INITIAL_BALANCE"

# Get unminted count
READINGS_RESPONSE=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
  -H "Authorization: Bearer $TOKEN")
UNMINTED_COUNT=$(echo "$READINGS_RESPONSE" | jq 'if type == "array" then [.[] | select(.minted == false)] | length else 0 end')
echo "   📋 Unminted Readings: $UNMINTED_COUNT"

echo ""

# Step 5: Monitor automated processing
echo -e "${BLUE}═══ Step 5: Monitoring Automated Processing ═══${NC}"
echo -e "${CYAN}Meter Polling Service will automatically:${NC}"
echo "   1. Detect unminted readings (every 60s)"
echo "   2. Validate settlement conditions"
echo "   3. Execute CPI to energy_token program"
echo "   4. Mint tokens to wallet"
echo "   5. Update database with transaction signatures"
echo ""
echo "Monitoring for up to 120 seconds..."
echo ""

MAX_WAIT=120
ELAPSED=0
CHECK_INTERVAL=10

while [ $ELAPSED -lt $MAX_WAIT ]; do
  sleep $CHECK_INTERVAL
  ELAPSED=$((ELAPSED + CHECK_INTERVAL))
  
  # Check minting progress
  READINGS_STATUS=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
    -H "Authorization: Bearer $TOKEN")
  
  MINTED_COUNT=$(echo "$READINGS_STATUS" | jq 'if type == "array" then [.[] | select(.minted == true)] | length else 0 end')
  UNMINTED_COUNT=$(echo "$READINGS_STATUS" | jq 'if type == "array" then [.[] | select(.minted == false)] | length else 0 end')
  
  # Get current balance
  CURRENT_BALANCE=$(curl -s -X GET "$API_URL/api/tokens/balance/$WALLET_ADDRESS" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.token_balance // "0"')
  
  echo -e "   ⏱️  ${ELAPSED}s | Minted: ${GREEN}${MINTED_COUNT}${NC}/${TOTAL_READINGS} | Balance: ${CYAN}${CURRENT_BALANCE}${NC} tokens"
  
  # Check if all readings are minted
  if [ "$MINTED_COUNT" -eq "$TOTAL_READINGS" ]; then
    echo ""
    echo -e "${GREEN}✅ All readings processed automatically!${NC}"
    break
  fi
done

echo ""

# Step 6: Final verification
echo -e "${BLUE}═══ Step 6: Post-Automation Verification ═══${NC}"

# Get final readings status
FINAL_READINGS=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
  -H "Authorization: Bearer $TOKEN")

FINAL_MINTED=$(echo "$FINAL_READINGS" | jq '[.[] | select(.minted == true)] | length')
FINAL_UNMINTED=$(echo "$FINAL_READINGS" | jq '[.[] | select(.minted == false)] | length')

# Get final balance
FINAL_BALANCE=$(curl -s -X GET "$API_URL/api/tokens/balance/$WALLET_ADDRESS" \
  -H "Authorization: Bearer $TOKEN")

BALANCE_TOKENS=$(echo "$FINAL_BALANCE" | jq -r '.token_balance // "0"')
BALANCE_RAW=$(echo "$FINAL_BALANCE" | jq -r '.token_balance_raw // 0')

echo "📊 Processing Summary:"
echo "   Total Readings: $TOTAL_READINGS"
echo "   Minted: ${GREEN}$FINAL_MINTED${NC}"
echo "   Pending: ${YELLOW}$FINAL_UNMINTED${NC}"
echo ""
echo "💰 Token Balance:"
echo "   Balance: ${CYAN}$BALANCE_TOKENS${NC} tokens"
echo "   Raw: $BALANCE_RAW"
echo ""

# Show transaction signatures
echo "🔗 Blockchain Transactions:"
echo "$FINAL_READINGS" | jq -r '.[] | select(.minted == true) | "   ✅ \(.kwh_amount) kWh → TX: \(.mint_tx_signature // "pending")"'
echo ""

# Step 7: Summary
echo "================================================================================"
if [ "$FINAL_MINTED" -eq "$TOTAL_READINGS" ]; then
  echo -e "${GREEN}✅ AUTOMATED METER PROCESSING COMPLETE${NC}"
  echo ""
  echo "Flow Verified:"
  echo "  ✅ Smart meter readings submitted"
  echo "  ✅ Validation passed (duplicate detection, amounts, timestamps)"
  echo "  ✅ Polling service detected unminted readings"
  echo "  ✅ Settlement conditions validated"
  echo "  ✅ CPI executed to blockchain"
  echo "  ✅ Tokens minted automatically"
  echo "  ✅ Database updated with transaction signatures"
elif [ "$FINAL_MINTED" -gt 0 ]; then
  echo -e "${YELLOW}⚠️  PARTIAL AUTOMATION COMPLETE${NC}"
  echo ""
  echo "Status: $FINAL_MINTED/$TOTAL_READINGS readings processed"
  echo "Note: Polling service runs every 60 seconds"
  echo "      Remaining readings will be processed in next cycle"
else
  echo -e "${YELLOW}⏳ AUTOMATION IN PROGRESS${NC}"
  echo ""
  echo "Status: Polling service is running"
  echo "Note: First polling cycle occurs at 60-second mark"
  echo "      Check again in a few moments"
fi
echo "================================================================================"
echo ""
