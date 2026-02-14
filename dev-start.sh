#!/bin/bash

# dev-start.sh - GridTokenX Unified Startup Script
# This script launches the full development environment in separate Terminal tabs.

PROJECT_ROOT=$(pwd)

echo "🚀 Starting GridTokenX Development Environment..."

# 1. Start Docker Services (Background)
echo "📦 Starting Docker Containers..."
cd "$PROJECT_ROOT/gridtokenx-trading"
docker-compose up -d
echo "✅ Docker Services Started."

# Function to open a new tab and run a command
open_tab() {
    local title="$1"
    local cmd="$2"
    local dir="$3"
    
    osascript -e "
        tell application \"Terminal\"
            activate
            tell application \"System Events\" to keystroke \"t\" using command down
            repeat while contents of selected tab of window 1 starts with \"line\"
                delay 0.01
            end repeat
            do script \"cd $dir && echo -e '\\033]0;$title\\007' && $cmd\" in front window
        tell application \"System Events\" to keystroke \"k\" using command down
        end tell
    "
}

# 2. Solana Validator
echo "🔗 Launching Solana Validator..."
# We use a simple background check, if not running, we start it in a new tab
if ! pgrep -x "solana-test-validator" > /dev/null; then
    open_tab "Solana Validator" "solana-test-validator" "$PROJECT_ROOT"
else
    echo "   (Validator already running)"
fi

# Give validator a moment if we just started it
sleep 2

# 3. Solana Relay
echo "Tb Launching Relay Service..."
open_tab "GridTokenX Relay" "anchor run relay" "$PROJECT_ROOT/gridtokenx-anchor"

# 4. Frontend
echo "💻 Launching Frontend..."
open_tab "GridTokenX Frontend" "pnpm dev" "$PROJECT_ROOT/gridtokenx-trading"

echo "✨ All services launched! Check your Terminal tabs."
