#!/bin/bash

# GridTokenX Admin User Registration Script
# Usage: ./register_admin.sh [email] [username] [password] [first_name] [last_name]
# Or: ./register_admin.sh (uses defaults)

set -e

# Configuration
API_URL="${API_URL:-http://localhost:4000}"
TIMESTAMP=$(date +%s)

# Default values
EMAIL="${1:-admin_${TIMESTAMP}@example.com}"
USERNAME="${2:-admin_${TIMESTAMP}}"
PASSWORD="${3:-P@ssw0rd123!}"
FIRST_NAME="${4:-Admin}"
LAST_NAME="${5:-User}"

echo "=========================================="
echo "GridTokenX Admin User Registration"
echo "=========================================="
echo "API URL: $API_URL"
echo "Email: $EMAIL"
echo "Username: $USERNAME"
echo "First Name: $FIRST_NAME"
echo "Last Name: $LAST_NAME"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

log_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed. Install with: brew install jq (macOS) or apt-get install jq (Linux)"
fi

# Step 1: Register User
log_info "Step 1: Registering user..."

REGISTER_RESP=$(curl -s -X POST "$API_URL/api/v1/users" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMAIL\",
        \"password\": \"$PASSWORD\",
        \"username\": \"$USERNAME\",
        \"first_name\": \"$FIRST_NAME\",
        \"last_name\": \"$LAST_NAME\"
    }") || log_error "Failed to connect to API at $API_URL"

# Check for errors
ERROR_MSG=$(echo "$REGISTER_RESP" | jq -r '.message // empty')
if [[ "$ERROR_MSG" == *"failed"* ]] || [[ "$ERROR_MSG" == *"error"* ]] || [[ "$ERROR_MSG" == *"already exists"* ]]; then
    log_error "Registration failed: $ERROR_MSG"
fi

# Extract access token
ACCESS_TOKEN=$(echo "$REGISTER_RESP" | jq -r '.auth.access_token // .data.auth.access_token // empty')
if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    log_error "Failed to get access token. Response: $REGISTER_RESP"
fi

log_success "User registered successfully"
log_info "Access Token: ${ACCESS_TOKEN:0:30}..."

# Step 2: Verify Email using test mode pattern (verify_<username>)
log_info "Step 2: Verifying email using test mode..."

# Use test mode verification pattern: verify_<username>
VERIFY_RESP=$(curl -s -X GET "$API_URL/api/v1/auth/verify?token=verify_$USERNAME")
WALLET_ADDRESS=$(echo "$VERIFY_RESP" | jq -r '.wallet_address // empty')

if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" == "null" ]; then
    log_info "Test verification didn't work, checking user profile..."
    
    PROFILE_RESP=$(curl -s -X GET "$API_URL/api/v1/users/me" \
        -H "Authorization: Bearer $ACCESS_TOKEN" 2>/dev/null || echo '{}')
    
    WALLET_ADDRESS=$(echo "$PROFILE_RESP" | jq -r '.wallet_address // empty')
fi

if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" == "null" ]; then
    log_info "Wallet not yet generated. Checking verification status..."
    # The wallet is created after email verification
    # For now, we'll try the dev faucet with the user ID extracted from JWT
    
    # Decode JWT payload (middle part) to get user ID
    PAYLOAD=$(echo "$ACCESS_TOKEN" | cut -d'.' -f2)
    # Add padding if needed
    PADDING=$((4 - ${#PAYLOAD} % 4))
    if [ $PADDING -ne 4 ]; then
        PAYLOAD="${PAYLOAD}$(printf '=%.0s' $(seq 1 $PADDING))"
    fi
    DECODED=$(echo "$PAYLOAD" | tr '_-' '/+' | base64 -d 2>/dev/null || echo '{}')
    USER_ID=$(echo "$DECODED" | jq -r '.sub // empty')
    
    if [ -z "$USER_ID" ]; then
        log_error "Could not extract user ID from token"
    fi
    
    log_info "User ID: $USER_ID"
fi

# If we still don't have a wallet, we need to check if verification worked
if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" == "null" ]; then
    # Check again after a brief delay
    sleep 1
    PROFILE_RESP=$(curl -s -X GET "$API_URL/api/v1/users/me" \
        -H "Authorization: Bearer $ACCESS_TOKEN" 2>/dev/null || echo '{}')
    WALLET_ADDRESS=$(echo "$PROFILE_RESP" | jq -r '.wallet_address // empty')
fi

if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" == "null" ]; then
    log_info "Note: Email verification may be required. Check your email or use the dev setup script."
    log_info "Continuing with role promotion if wallet exists..."
    # Try to get wallet from the wallets endpoint
    WALLETS_RESP=$(curl -s -X GET "$API_URL/api/v1/wallets" \
        -H "Authorization: Bearer $ACCESS_TOKEN" 2>/dev/null || echo '[]')
    WALLET_ADDRESS=$(echo "$WALLETS_RESP" | jq -r '.[0].address // empty')
fi

if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" == "null" ]; then
    log_error "No wallet address found. Email verification may be required. Response: $PROFILE_RESP"
fi

log_success "Wallet address obtained: $WALLET_ADDRESS"

# Step 3: Fund and Promote to Admin
log_info "Step 3: Funding wallet and promoting to admin..."

FAUCET_RESP=$(curl -s -X POST "$API_URL/api/v1/dev/faucet" \
    -H "Content-Type: application/json" \
    -d "{
        \"wallet_address\": \"$WALLET_ADDRESS\",
        \"amount_sol\": 5.0,
        \"promote_to_role\": \"admin\"
    }") || log_error "Faucet request failed"

FAUCET_SUCCESS=$(echo "$FAUCET_RESP" | jq -r '.success // false')
FAUCET_MESSAGE=$(echo "$FAUCET_RESP" | jq -r '.message // "Unknown response"')

if [ "$FAUCET_SUCCESS" != "true" ]; then
    log_error "Faucet/Promotion failed: $FAUCET_MESSAGE\nFull response: $FAUCET_RESP"
fi

log_success "User funded and promoted to admin"
log_info "Faucet response: $FAUCET_MESSAGE"

# Step 4: Verify Admin Status
log_info "Step 4: Verifying admin status..."

PROFILE_RESP=$(curl -s -X GET "$API_URL/api/v1/users/me" \
    -H "Authorization: Bearer $ACCESS_TOKEN" 2>/dev/null || echo '{}')

USER_ROLE=$(echo "$PROFILE_RESP" | jq -r '.role // empty')
FINAL_WALLET=$(echo "$PROFILE_RESP" | jq -r '.wallet_address // empty')
USER_BALANCE=$(echo "$PROFILE_RESP" | jq -r '.balance // "0"')

log_success "Admin user registration complete!"
echo ""
echo "=========================================="
echo "Registration Summary"
echo "=========================================="
echo "Email: $EMAIL"
echo "Username: $USERNAME"
echo "Role: $USER_ROLE"
echo "Wallet: $FINAL_WALLET"
echo "Balance: $USER_BALANCE THB"
echo "=========================================="
echo ""
echo "Access Token:"
echo "$ACCESS_TOKEN"
echo ""
echo "=========================================="
echo "Export for use:"
echo "export GRIDTOKENX_TOKEN='$ACCESS_TOKEN'"
echo "export GRIDTOKENX_API_URL='$API_URL'"
echo "=========================================="
