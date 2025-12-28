#!/bin/bash
# Setup Seller and Buyer Accounts & Meters

set -e

# API Configuration
API_URL="http://localhost:4000"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# User Data
# Format: "Username|Email|Password|Role|MeterSerial|MeterType"
USERS=(
    "seller|seller@example.com|Gr1dT0k3n\$eller!|prosumer|METER-SELLER-$(date +%s)|Solar"
    "buyer|buyer@example.com|Gr1dT0k3nBuy3r!|consumer|METER-BUYER-$(date +%s)|Grid"
)

echo -e "${YELLOW}Starting Seller/Buyer Setup...${NC}"

for user_info in "${USERS[@]}"; do
    IFS="|" read -r USERNAME EMAIL PASSWORD ROLE METER_SERIAL METER_TYPE <<< "$user_info"
    
    echo ""
    echo -e "${YELLOW}Processing $USERNAME ($ROLE)...${NC}"

    # 1. Register User (or Login if exists)
    echo "  > Registering/Checking user..."
    REGISTER_RES=$(curl -s -X POST "$API_URL/api/v1/users" \
      -H "Content-Type: application/json" \
      -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\", \"username\": \"$USERNAME\", \"first_name\": \"$USERNAME\", \"last_name\": \"Demo\"}")

    # Extract Token
    TOKEN=$(echo "$REGISTER_RES" | jq -r '.auth.access_token // empty')
    
    if [ -z "$TOKEN" ]; then
        # Try login if registration implied existence
        echo "    User might exist, trying login..."
        LOGIN_RES=$(curl -s -X POST "$API_URL/api/v1/auth/token" \
          -H "Content-Type: application/json" \
          -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")
        TOKEN=$(echo "$LOGIN_RES" | jq -r '.access_token // empty')
    fi

    if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
       echo -e "${RED}    ❌ Failed to get token for $USERNAME.${NC}"
       exit 1
    fi
    echo -e "${GREEN}    ✅ Token acquired.${NC}"
    
    # 2. Manual Verification & Role Update (Direct DB)
    echo "  > Verifying email and setting role in DB..."
    # Generate wallet address if needed (using solana-keygen or dummy for now safely, but here we let the backend handle it or force it via DB if logic requires)
    # The registration logic assigns a wallet only on verification usually? 
    # Let's check the code: `verify_email` handler assigns it.
    # To bypass email flow, we must assign a wallet manually in DB.
    
    # Generate wallet address if needed
    if [ ! -f "keypairs/${USERNAME}-wallet.json" ]; then
        solana-keygen new --no-passphrase --outfile "keypairs/${USERNAME}-wallet.json" --silent
    fi
    NEW_WALLET=$(solana-keygen pubkey "keypairs/${USERNAME}-wallet.json")
    
    # Execute SQL
    docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c \
      "UPDATE users SET \
         email_verified = true, \
         role = '$ROLE', \
         wallet_address = COALESCE(wallet_address, '$NEW_WALLET') \
       WHERE email = '$EMAIL';" > /dev/null
    
    echo -e "${GREEN}    ✅ User verified and role set to $ROLE.${NC}"

    # 3. Register Meter
    echo "  > Registering meter $METER_SERIAL..."
    # Generate a temporary kepair for the meter public key
    METER_PUBKEY=$(solana-keygen new --no-passphrase --no-outfile | grep 'pubkey:' | cut -d: -f2 | xargs)

    METER_RES=$(curl -s -X POST "$API_URL/api/v1/meters" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d "{\"serial_number\": \"$METER_SERIAL\", \"meter_type\": \"$METER_TYPE\", \"location\": \"Demo Location\", \"manufacturer\": \"GridTokenX\", \"installation_date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"meter_public_key\": \"$METER_PUBKEY\"}")
    METER_ID=$(echo "$METER_RES" | jq -r '.meter.id // empty')
    
    if [ -n "$METER_ID" ] && [ "$METER_ID" != "null" ]; then
        echo -e "${GREEN}    ✅ Meter Registered: $METER_ID${NC}"
        
        # Auto-verify meter for demo
        echo "  > Auto-verifying meter..."
        docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c \
            "UPDATE meter_registry SET verification_status = 'verified', verified_at = NOW() WHERE id = '$METER_ID';" > /dev/null
         echo -e "${GREEN}    ✅ Meter Verified.${NC}"

    else
        echo -e "${RED}    ❌ Failed to register meter: $(echo "$METER_RES" | jq -r '.message // .')${NC}"
        # Proceeding anyway as it might be already registered
    fi

done

echo ""
echo -e "${GREEN}Setup Complete!${NC}"
echo "Seller: seller (Prosumer) - $METER_SERIAL"
echo "Buyer: buyer (Consumer) - $METER_SERIAL"
