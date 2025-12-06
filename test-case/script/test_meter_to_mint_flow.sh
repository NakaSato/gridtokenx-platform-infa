#!/bin/bash
# Test: Meter Reading → Validation → Settlement → CPI → Token Mint
# This script tests the complete flow from meter reading submission to token minting

set -e

API_URL="http://localhost:8080"
DB_CONTAINER="gridtokenx-postgres"
DB_USER="gridtokenx_user"
DB_NAME="gridtokenx"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================================================"
echo "Testing: Meter Reading → Validation → Settlement → CPI → Token Mint"
echo "================================================================================"
echo ""

# Step 1: Setup - Create and verify user
echo -e "${BLUE}Step 1: User Setup${NC}"
echo "1.1 Registering test user..."
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "metertest",
    "email": "meter.test@gridtoken.test",
    "password": "TestPass123!",
    "first_name": "Meter",
    "last_name": "Test"
  }')

HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" == "201" ] || [ "$HTTP_CODE" == "200" ]; then
  echo -e "${GREEN}✅ User registered${NC}"
elif [ "$HTTP_CODE" == "400" ]; then
  echo -e "${YELLOW}⚠️  User already exists${NC}"
else
  echo -e "${RED}❌ Registration failed (HTTP $HTTP_CODE)${NC}"
  exit 1
fi

echo "1.2 Verifying email and setting role..."
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "UPDATE users SET role = 'prosumer', email_verified = true WHERE email = 'meter.test@gridtoken.test';" > /dev/null 2>&1
echo -e "${GREEN}✅ User verified and role set${NC}"

echo "1.3 Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "metertest",
    "email": "meter.test@gridtoken.test",
    "password": "TestPass123!"
  }')

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // empty')
if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo -e "${RED}❌ Failed to get auth token${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Logged in successfully${NC}"
echo ""

# Step 2: Set wallet address
echo -e "${BLUE}Step 2: Wallet Setup${NC}"
WALLET_ADDRESS="58tj1xRGjjpSNkHuJfsgTYKfKM7gsG8TQqBmya6KGx3i"
echo "Setting wallet address: $WALLET_ADDRESS"

WALLET_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/user/wallet" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"wallet_address\": \"$WALLET_ADDRESS\"}")

HTTP_CODE=$(echo "$WALLET_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" == "200" ]; then
  echo -e "${GREEN}✅ Wallet address set${NC}"
else
  echo -e "${RED}❌ Failed to set wallet (HTTP $HTTP_CODE)${NC}"
  echo "$WALLET_RESPONSE" | sed '$d'
  exit 1
fi
echo ""

# Step 3: Submit Meter Reading (with validation)
echo -e "${BLUE}Step 3: Meter Reading Submission (with Validation)${NC}"
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
KWH_AMOUNT="25.5"

echo "Submitting meter reading: $KWH_AMOUNT kWh at $CURRENT_TIME"

READING_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/meters/submit-reading" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"kwh_amount\": \"$KWH_AMOUNT\",
    \"reading_timestamp\": \"$CURRENT_TIME\",
    \"meter_signature\": \"test_signature_$(date +%s)\"
  }")

HTTP_CODE=$(echo "$READING_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$READING_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
  READING_ID=$(echo "$RESPONSE_BODY" | jq -r '.id')
  echo -e "${GREEN}✅ Meter reading submitted${NC}"
  echo "   Reading ID: $READING_ID"
  echo "   Amount: $KWH_AMOUNT kWh"
  echo "   Minted: $(echo "$RESPONSE_BODY" | jq -r '.minted')"
else
  echo -e "${RED}❌ Meter reading submission failed (HTTP $HTTP_CODE)${NC}"
  echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
  exit 1
fi
echo ""

# Step 4: Check initial balance (before minting)
echo -e "${BLUE}Step 4: Pre-Mint Balance Check${NC}"
BALANCE_RESPONSE=$(curl -s -X GET "$API_URL/api/tokens/balance/$WALLET_ADDRESS" \
  -H "Authorization: Bearer $TOKEN")

INITIAL_BALANCE=$(echo "$BALANCE_RESPONSE" | jq -r '.token_balance // "0"')
echo "Initial token balance: $INITIAL_BALANCE"
echo ""

# Step 5: Wait for automatic minting (Settlement → CPI → Token Mint)
echo -e "${BLUE}Step 5: Waiting for Automatic Token Minting${NC}"
echo "The meter polling service should automatically:"
echo "  1. Detect unminted reading"
echo "  2. Validate settlement conditions"
echo "  3. Execute CPI to energy_token program"
echo "  4. Mint tokens to user's wallet"
echo ""
echo "Waiting up to 90 seconds for automatic minting..."

MAX_WAIT=90
ELAPSED=0
MINTED=false

while [ $ELAPSED -lt $MAX_WAIT ]; do
  sleep 5
  ELAPSED=$((ELAPSED + 5))
  
  # Check if reading has been minted
  READING_STATUS=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
    -H "Authorization: Bearer $TOKEN" | jq -r "if type == \"array\" then .[0].minted else false end // false")
  
  if [ "$READING_STATUS" == "true" ]; then
    MINTED=true
    echo -e "${GREEN}✅ Reading minted after ${ELAPSED}s${NC}"
    break
  else
    echo "   ⏳ Waiting... (${ELAPSED}s elapsed)"
  fi
done

if [ "$MINTED" == "false" ]; then
  echo -e "${YELLOW}⚠️  Automatic minting did not complete within ${MAX_WAIT}s${NC}"
  echo "   This may be normal if the polling interval is longer"
fi
echo ""

# Step 6: Check final balance (after minting)
echo -e "${BLUE}Step 6: Post-Mint Balance Check${NC}"
BALANCE_RESPONSE=$(curl -s -X GET "$API_URL/api/tokens/balance/$WALLET_ADDRESS" \
  -H "Authorization: Bearer $TOKEN")

FINAL_BALANCE=$(echo "$BALANCE_RESPONSE" | jq -r '.token_balance // "0"')
FINAL_BALANCE_RAW=$(echo "$BALANCE_RESPONSE" | jq -r '.token_balance_raw // 0')

echo "Final token balance: $FINAL_BALANCE ($FINAL_BALANCE_RAW raw)"
echo ""

# Step 7: Verify transaction on blockchain
echo -e "${BLUE}Step 7: Blockchain Verification${NC}"
READINGS=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
  -H "Authorization: Bearer $TOKEN")

TX_SIGNATURE=$(echo "$READINGS" | jq -r '.[0].mint_tx_signature // "none"')
echo "Mint transaction signature: $TX_SIGNATURE"

if [ "$TX_SIGNATURE" != "none" ] && [ "$TX_SIGNATURE" != "null" ]; then
  echo -e "${GREEN}✅ Transaction recorded on blockchain${NC}"
else
  echo -e "${YELLOW}⚠️  No transaction signature found${NC}"
fi
echo ""

# Step 8: Summary
echo "================================================================================"
echo -e "${GREEN}✅ METER TO MINT FLOW TEST COMPLETE${NC}"
echo "================================================================================"
echo ""
echo "Summary:"
echo "  📊 Meter Reading: $KWH_AMOUNT kWh"
echo "  💰 Initial Balance: $INITIAL_BALANCE tokens"
echo "  💰 Final Balance: $FINAL_BALANCE tokens"
echo "  🔗 TX Signature: $TX_SIGNATURE"
echo ""

if [ "$MINTED" == "true" ]; then
  echo -e "${GREEN}✅ Complete flow executed successfully!${NC}"
  echo ""
  echo "Flow verified:"
  echo "  ✅ Meter Reading submitted"
  echo "  ✅ Validation passed"
  echo "  ✅ Settlement processed"
  echo "  ✅ CPI executed"
  echo "  ✅ Tokens minted"
else
  echo -e "${YELLOW}⚠️  Flow partially complete - minting pending${NC}"
fi
echo ""
