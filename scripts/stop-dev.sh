#!/bin/bash
# GridTokenX Development Environment Stop Script
# This script gracefully stops all development services
#
# Usage: ./scripts/stop-dev.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Stopping GridTokenX Development Services     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Stop API Gateway
echo -e "${YELLOW}Stopping API Gateway...${NC}"
pkill -f "api-gateway" 2>/dev/null && echo -e "${GREEN}✅ API Gateway stopped${NC}" || echo -e "${YELLOW}⚠️ API Gateway was not running${NC}"

# Stop Solana Test Validator
echo -e "${YELLOW}Stopping Solana Test Validator...${NC}"
pkill -f "solana-test-validator" 2>/dev/null && echo -e "${GREEN}✅ Solana Validator stopped${NC}" || echo -e "${YELLOW}⚠️ Validator was not running${NC}"

# Optionally stop Docker services
if [ "$1" == "--all" ]; then
    echo ""
    echo -e "${YELLOW}Stopping Docker services...${NC}"
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa
    docker-compose down 2>/dev/null && echo -e "${GREEN}✅ Docker services stopped${NC}" || echo -e "${YELLOW}⚠️ Docker services were not running${NC}"
fi

echo ""
echo -e "${GREEN}All services stopped!${NC}"
echo ""
echo -e "${YELLOW}To restart the development environment:${NC}"
echo "  ./scripts/start-dev.sh"
echo ""
if [ "$1" != "--all" ]; then
    echo -e "${YELLOW}Note: Docker services (PostgreSQL, Redis) are still running.${NC}"
    echo "Use './scripts/stop-dev.sh --all' to stop everything including Docker."
fi
