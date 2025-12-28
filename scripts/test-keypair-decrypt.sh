#!/bin/bash
# Test keypair decryption for seller account
# This tests the same decryption logic used by the settlement service

set -e

cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-apigateway

# Load env
export $(grep -v '^#' .env | grep -v "^$" | xargs)

echo "=== Testing Seller Keypair Decryption ==="
echo "ENCRYPTION_SECRET is set: $([ -n "$ENCRYPTION_SECRET" ] && echo "YES (length: ${#ENCRYPTION_SECRET})" || echo "NO")"
echo ""

# Get seller's encrypted key data as Base64
echo "Fetching seller's encrypted key from database..."

SELLER_ID="000bbedb-b66f-4bd2-ac9e-491aea99ec2a"

# Get the encrypted key data
docker exec gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -t -c "
SELECT 
    encode(encrypted_private_key, 'base64') as encrypted_key,
    encode(wallet_salt, 'base64') as salt,
    encode(encryption_iv, 'base64') as iv,
    wallet_address
FROM users 
WHERE id = '$SELLER_ID'
" | while read line; do
    if [ -n "$line" ]; then
        ENCRYPTED_KEY=$(echo "$line" | cut -d'|' -f1 | xargs)
        SALT=$(echo "$line" | cut -d'|' -f2 | xargs)
        IV=$(echo "$line" | cut -d'|' -f3 | xargs)
        WALLET=$(echo "$line" | cut -d'|' -f4 | xargs)
        
        echo "Wallet Address: $WALLET"
        echo "Encrypted Key (base64, first 40 chars): ${ENCRYPTED_KEY:0:40}..."
        echo "Salt (base64): $SALT"
        echo "IV (base64): $IV"
        echo ""
        echo "Key length: ${#ENCRYPTED_KEY}"
        echo "Salt length: ${#SALT}"
        echo "IV length: ${#IV}"
    fi
done

echo ""
echo "=== To properly test decryption, run the force_settle binary ==="
echo "cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-apigateway"
echo "export \$(grep -v '^#' .env | grep -v \"^\$\" | xargs)"
echo "cargo run --bin force_settle"
