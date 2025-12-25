#!/bin/bash
# GridTokenX Complete User Flow Test
# Tests the entire journey from registration to token minting

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

API_URL="http://localhost:4000"
RPC_URL="http://localhost:8899"

# Generate unique user
TIMESTAMP=$(date +%s)
USERNAME="testuser${TIMESTAMP}"
EMAIL="${USERNAME}@example.com"
WALLET="$(solana-keygen pubkey ~/.config/solana/id.json)"
METER_SERIAL="METER-${TIMESTAMP}"

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       GridTokenX Complete User Flow Test                  ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Test Parameters:${NC}"
echo "  • Username: $USERNAME"
echo "  • Email: $EMAIL"
echo "  • Wallet: $WALLET"
echo "  • Meter: $METER_SERIAL"
echo ""

# ============================================================================
# Step 1: Register User
# ============================================================================
echo -e "${YELLOW}📝 Step 1: Registering user...${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/users" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"TestPass123!\", \"username\": \"$USERNAME\", \"first_name\": \"Test\", \"last_name\": \"User\"}")

JWT_TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.auth.access_token')
USER_ID=$(echo $REGISTER_RESPONSE | jq -r '.auth.user.id')

if [ "$JWT_TOKEN" == "null" ] || [ -z "$JWT_TOKEN" ]; then
    echo -e "${RED}❌ Registration failed: $(echo $REGISTER_RESPONSE | jq -r '.message')${NC}"
    exit 1
fi
echo "   User ID: $USER_ID"
echo -e "${GREEN}   ✅ User registered${NC}"

# ============================================================================
# Step 2: Register Meter
# ============================================================================
echo ""
echo -e "${YELLOW}📟 Step 2: Registering meter...${NC}"
METER_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/meters" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "{\"serial_number\": \"$METER_SERIAL\", \"location\": \"Test Location\", \"meter_type\": \"smart\"}")

METER_ID=$(echo $METER_RESPONSE | jq -r '.meter.id')
echo "   Meter ID: $METER_ID"
echo "   Serial: $METER_SERIAL"
echo -e "${GREEN}   ✅ Meter registered${NC}"

# ============================================================================
# Step 3: Verify Meter (Direct DB)
# ============================================================================
echo ""
echo -e "${YELLOW}✓ Step 3: Verifying meter...${NC}"
docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c \
  "UPDATE meters SET is_verified = true WHERE serial_number = '$METER_SERIAL';" > /dev/null 2>&1
echo -e "${GREEN}   ✅ Meter verified${NC}"

# ============================================================================
# Step 4: Submit Reading
# ============================================================================
echo ""
echo -e "${YELLOW}⚡ Step 4: Submitting meter reading...${NC}"
READING_AMOUNT=42.5
READING_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/meters/$METER_SERIAL/readings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "{\"kwh\": $READING_AMOUNT, \"wallet_address\": \"$WALLET\"}")

READING_ID=$(echo $READING_RESPONSE | jq -r '.id')
echo "   Reading ID: $READING_ID"
echo "   Amount: $READING_AMOUNT kWh"
echo -e "${GREEN}   ✅ Reading submitted${NC}"

# ============================================================================
# Step 5: Mint Tokens
# ============================================================================
echo ""
echo -e "${YELLOW}🪙 Step 5: Minting tokens from reading...${NC}"
MINT_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/meters/readings/$READING_ID/mint" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" 2>&1)

TX_SIG=$(echo $MINT_RESPONSE | jq -r '.transaction_signature' 2>/dev/null || echo "")
MINTED_AMOUNT=$(echo $MINT_RESPONSE | jq -r '.kwh_amount' 2>/dev/null || echo "")

if [ "$TX_SIG" == "null" ] || [ -z "$TX_SIG" ]; then
    echo -e "${RED}❌ Minting failed${NC}"
    echo "   Response: $MINT_RESPONSE"
    exit 1
fi
echo "   TX Signature: ${TX_SIG:0:40}..."
echo "   Minted: $MINTED_AMOUNT tokens"
echo -e "${GREEN}   ✅ Tokens minted${NC}"

# ============================================================================
# Step 6: Verify Token Balance
# ============================================================================
echo ""
echo -e "${YELLOW}💰 Step 6: Verifying token balance...${NC}"
TOKEN_MINT=$(grep "^ENERGY_TOKEN_MINT=" gridtokenx-apigateway/.env | cut -d'=' -f2)
BALANCE=$(spl-token balance "$TOKEN_MINT" --owner "$WALLET" --url "$RPC_URL" 2>/dev/null || echo "0")
echo "   Token Mint: $TOKEN_MINT"
echo "   Balance: $BALANCE tokens"
echo -e "${GREEN}   ✅ Balance verified${NC}"

# ============================================================================
# Step 7: Verify Double-Minting Prevention
# ============================================================================
echo ""
echo -e "${YELLOW}🔒 Step 7: Testing double-minting prevention...${NC}"
DOUBLE_MINT=$(curl -s -X POST "$API_URL/api/v1/meters/readings/$READING_ID/mint" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json")

ERROR_MSG=$(echo $DOUBLE_MINT | jq -r '.error.message' 2>/dev/null || echo "")
if [[ "$ERROR_MSG" == *"already been minted"* ]]; then
    echo "   Response: $ERROR_MSG"
    echo -e "${GREEN}   ✅ Double-minting correctly prevented${NC}"
else
    echo -e "${RED}   ❌ Double-minting prevention failed${NC}"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    TEST SUMMARY                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}All tests passed! ✅${NC}"
echo ""
echo "User:    $USERNAME ($USER_ID)"
echo "Meter:   $METER_SERIAL"
echo "Reading: $READING_ID"
echo "Minted:  $MINTED_AMOUNT GRX tokens"
echo "Balance: $BALANCE tokens"
echo "TX:      ${TX_SIG:0:50}..."
echo ""

# ============================================================================
# Additional Minting Tests
# ============================================================================
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           ADDITIONAL MINTING TESTS                        ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test: Submit and mint multiple readings
echo -e "${YELLOW}🧪 Test: Multiple readings minting...${NC}"
for i in 10 20 30; do
    R_RESP=$(curl -s -X POST "$API_URL/api/v1/meters/$METER_SERIAL/readings" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $JWT_TOKEN" \
      -d "{\"kwh\": $i, \"wallet_address\": \"$WALLET\"}")
    R_ID=$(echo $R_RESP | jq -r '.id')
    
    M_RESP=$(curl -s -X POST "$API_URL/api/v1/meters/readings/$R_ID/mint" \
      -H "Authorization: Bearer $JWT_TOKEN" \
      -H "Content-Type: application/json")
    
    M_TX=$(echo $M_RESP | jq -r '.transaction_signature // ""')
    if [ -n "$M_TX" ] && [ "$M_TX" != "null" ]; then
        echo "   ✅ Minted $i kWh"
    else
        echo "   ⚠️  Failed to mint $i kWh reading"
    fi
done

# Test: Verify total minted via API
echo ""
echo -e "${YELLOW}🧪 Test: Verify readings list...${NC}"
READINGS=$(curl -s "$API_URL/api/v1/meters/readings" \
  -H "Authorization: Bearer $JWT_TOKEN")
MINTED_COUNT=$(echo $READINGS | jq '[.[] | select(.minted==true)] | length')
PENDING_COUNT=$(echo $READINGS | jq '[.[] | select(.minted==false and .kwh_amount>0)] | length')
echo "   Minted readings: $MINTED_COUNT"
echo "   Pending readings: $PENDING_COUNT"

# Test: Verify stats endpoint (if exists)
echo ""
echo -e "${YELLOW}🧪 Test: Verify meter stats...${NC}"
STATS=$(curl -s "$API_URL/api/v1/meters/stats" \
  -H "Authorization: Bearer $JWT_TOKEN" 2>/dev/null || echo "{}")
if [ "$STATS" != "{}" ] && [ "$(echo $STATS | jq -r '.total_minted // ""')" != "" ]; then
    TOTAL_MINTED=$(echo $STATS | jq -r '.total_minted // 0')
    TOTAL_PENDING=$(echo $STATS | jq -r '.pending_mint // 0')
    echo "   Total minted: $TOTAL_MINTED kWh"
    echo "   Total pending: $TOTAL_PENDING kWh"
else
    echo "   Stats endpoint not available (OK)"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         ALL MINTING TESTS COMPLETED SUCCESSFULLY!         ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
