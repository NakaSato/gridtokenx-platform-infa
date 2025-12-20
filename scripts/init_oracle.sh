#!/bin/bash
# Initialize Oracle Authority on Registry Program
# This script sets the API Gateway authority as the oracle for meter readings
#
# Usage: ./init_oracle.sh [oracle_pubkey]
# If no oracle_pubkey provided, uses the authority from dev-wallet.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ANCHOR_DIR="$ROOT_DIR/gridtokenx-anchor"

# Load environment variables
if [ -f "$ROOT_DIR/.env" ]; then
    source "$ROOT_DIR/.env"
fi

# Get oracle pubkey (default to dev-wallet.json public key)
if [ -n "$1" ]; then
    ORACLE_PUBKEY="$1"
else
    # Extract public key from dev-wallet.json
    DEV_WALLET="$ROOT_DIR/dev-wallet.json"
    if [ -f "$DEV_WALLET" ]; then
        ORACLE_PUBKEY=$(solana-keygen pubkey "$DEV_WALLET")
    else
        echo "Error: dev-wallet.json not found and no oracle pubkey provided"
        exit 1
    fi
fi

echo "🔑 Setting oracle authority to: $ORACLE_PUBKEY"

# Check if anchor is available
if ! command -v anchor &> /dev/null; then
    echo "Error: anchor CLI not found. Please install anchor-cli."
    exit 1
fi

# Navigate to anchor directory
cd "$ANCHOR_DIR"

# Run the set_oracle_authority instruction
# Using anchor test with a custom test that sets the oracle
cat << 'EOF' > tests/set_oracle_temp.ts
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";

async function main() {
    const provider = anchor.AnchorProvider.env();
    anchor.setProvider(provider);
    
    const registryProgramId = new anchor.web3.PublicKey(
        process.env.REGISTRY_PROGRAM_ID || "9wvMT6f2Y7A37LB8y5LEQRSJxbnwLYqw1Bqq1RBtD3oM"
    );
    
    const oraclePubkey = new anchor.web3.PublicKey(process.argv[2]);
    
    // Derive registry PDA
    const [registryPda] = anchor.web3.PublicKey.findProgramAddressSync(
        [Buffer.from("registry")],
        registryProgramId
    );
    
    console.log("Registry PDA:", registryPda.toBase58());
    console.log("Oracle Pubkey:", oraclePubkey.toBase58());
    console.log("Authority:", provider.wallet.publicKey.toBase58());
    
    // Build instruction data (discriminator + oracle pubkey)
    const discriminator = Buffer.from([0x42, 0x9e, 0x7e, 0x22, 0x4c, 0x64, 0x5e, 0x44]); // sha256("global:set_oracle_authority")[:8]
    const data = Buffer.concat([discriminator, oraclePubkey.toBuffer()]);
    
    const instruction = new anchor.web3.TransactionInstruction({
        keys: [
            { pubkey: registryPda, isSigner: false, isWritable: true },
            { pubkey: provider.wallet.publicKey, isSigner: true, isWritable: false },
        ],
        programId: registryProgramId,
        data,
    });
    
    const tx = new anchor.web3.Transaction().add(instruction);
    const sig = await provider.sendAndConfirm(tx);
    
    console.log("✅ Oracle authority set! TX:", sig);
}

main().catch(console.error);
EOF

# Run the script
npx ts-node tests/set_oracle_temp.ts "$ORACLE_PUBKEY"

# Clean up temp file
rm tests/set_oracle_temp.ts

echo "✅ Oracle authority configured successfully!"
echo "   Oracle: $ORACLE_PUBKEY"
echo ""
echo "The API Gateway can now submit meter readings to the Registry program."
