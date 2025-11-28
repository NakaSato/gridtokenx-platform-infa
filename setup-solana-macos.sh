#!/bin/bash
# Setup script for running Solana validator natively on macOS (Apple Silicon)
# This script installs Solana CLI and provides instructions for running the validator

set -e

echo "=================================================="
echo "GridTokenX - Solana Setup for macOS (Apple Silicon)"
echo "=================================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is for macOS only."
    echo "   For Linux, you can use the Docker service with: docker-compose --profile solana up"
    exit 1
fi

# Check if running on Apple Silicon
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo "⚠️  Warning: You appear to be on an Intel Mac ($ARCH)."
    echo "   This script is optimized for Apple Silicon (M1/M2/M3/M4)."
    echo "   You may be able to use the Docker service instead."
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if Solana is already installed
if command -v solana &> /dev/null; then
    SOLANA_VERSION=$(solana --version | head -n 1)
    echo "✅ Solana is already installed: $SOLANA_VERSION"
    echo ""
else
    echo "📦 Installing Solana CLI..."
    echo ""
    
    # Install Solana
    sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
    
    echo ""
    echo "✅ Solana CLI installed successfully!"
    echo ""
fi

# Add to PATH instructions
SOLANA_PATH="$HOME/.local/share/solana/install/active_release/bin"

echo "=================================================="
echo "📝 Setup Instructions"
echo "=================================================="
echo ""
echo "1. Add Solana to your PATH (if not already added):"
echo "   Add this line to your ~/.zshrc or ~/.bash_profile:"
echo ""
echo "   export PATH=\"$SOLANA_PATH:\$PATH\""
echo ""
echo "2. Reload your shell configuration:"
echo "   source ~/.zshrc  # or source ~/.bash_profile"
echo ""
echo "3. Verify installation:"
echo "   solana --version"
echo ""
echo "4. Run the Solana test validator:"
echo "   solana-test-validator --reset"
echo ""
echo "5. In another terminal, start your Docker services:"
echo "   docker-compose up"
echo ""
echo "=================================================="
echo "🚀 Quick Start"
echo "=================================================="
echo ""

# Check if PATH is already configured
if [[ ":$PATH:" == *":$SOLANA_PATH:"* ]]; then
    echo "✅ Solana is already in your PATH"
    echo ""
    read -p "Would you like to start the Solana test validator now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🚀 Starting Solana test validator..."
        echo "   Press Ctrl+C to stop"
        echo ""
        solana-test-validator --reset
    fi
else
    echo "⚠️  Solana is not in your PATH yet."
    echo "   Please add it to your shell configuration and reload."
    echo ""
    echo "   Run this command:"
    echo "   echo 'export PATH=\"$SOLANA_PATH:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    echo ""
    echo "   Then run: solana-test-validator --reset"
fi

echo ""
echo "=================================================="
echo "📚 Additional Resources"
echo "=================================================="
echo ""
echo "• Solana Documentation: https://docs.solanalabs.com/"
echo "• Test Validator Guide: https://docs.solanalabs.com/cli/examples/test-validator"
echo "• RPC Endpoint: http://localhost:8899"
echo "• WebSocket Endpoint: ws://localhost:8900"
echo "• Faucet: http://localhost:9900"
echo ""
