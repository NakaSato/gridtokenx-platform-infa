#!/bin/bash
# Smart Meter Simulator - Data Retrieval Guide
# Shows how to get meter data from the simulator API

SIMULATOR_URL="http://localhost:8000"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================================================"
echo "Smart Meter Simulator - Data Retrieval"
echo "================================================================================"
echo ""

# 1. Get Simulator Status
echo -e "${BLUE}1. Simulator Status${NC}"
echo "GET $SIMULATOR_URL/api/status"
echo ""
STATUS=$(curl -s "$SIMULATOR_URL/api/status")
echo "$STATUS" | jq '.'
echo ""

# Extract meter IDs
METER_IDS=$(echo "$STATUS" | jq -r '.meters[].meter_id')
NUM_METERS=$(echo "$STATUS" | jq -r '.num_meters')

echo -e "${GREEN}Found $NUM_METERS meter(s)${NC}"
echo ""

# 2. Get Individual Meter Data
if [ "$NUM_METERS" -gt 0 ]; then
    echo -e "${BLUE}2. Individual Meter Data${NC}"
    
    for METER_ID in $METER_IDS; do
        echo "GET $SIMULATOR_URL/api/meters/$METER_ID/status"
        echo ""
        
        METER_DATA=$(curl -s "$SIMULATOR_URL/api/meters/$METER_ID/status")
        echo "$METER_DATA" | jq '.'
        echo ""
        
        # Extract key metrics
        NAME=$(echo "$METER_DATA" | jq -r '.name // "N/A"')
        LOCATION=$(echo "$METER_DATA" | jq -r '.location // "N/A"')
        GENERATION=$(echo "$METER_DATA" | jq -r '.current_generation // 0')
        CONSUMPTION=$(echo "$METER_DATA" | jq -r '.current_consumption // 0')
        NET=$(echo "$METER_DATA" | jq -r '.net_emission // 0')
        
        echo -e "${CYAN}Meter Summary:${NC}"
        echo "  Name: $NAME"
        echo "  Location: $LOCATION"
        echo "  Generation: ${GREEN}$GENERATION kW${NC}"
        echo "  Consumption: ${YELLOW}$CONSUMPTION kW${NC}"
        echo "  Net: $NET kW"
        echo ""
    done
fi

# 3. Get Simulation Parameters
echo -e "${BLUE}3. Simulation Parameters${NC}"
echo "GET $SIMULATOR_URL/api/simulation/parameters"
echo ""
curl -s "$SIMULATOR_URL/api/simulation/parameters" | jq '.'
echo ""

# 4. Summary
echo "================================================================================"
echo -e "${GREEN}Available Simulator API Endpoints:${NC}"
echo ""
echo "Status & Control:"
echo "  GET  /api/status                    - Get simulator status"
echo "  POST /api/control/start             - Start simulation"
echo "  POST /api/control/stop              - Stop simulation"
echo "  POST /api/control/pause             - Pause simulation"
echo "  POST /api/control/resume            - Resume simulation"
echo ""
echo "Meter Management:"
echo "  POST /api/meters/add                - Add new meter"
echo "  GET  /api/meters/{id}/status        - Get meter data"
echo "  DEL  /api/meters/{id}               - Remove meter"
echo ""
echo "Simulation:"
echo "  GET  /api/simulation/parameters     - Get parameters"
echo "  POST /api/simulation/parameters     - Update parameters"
echo "  POST /api/simulation/preset/{name}  - Load preset"
echo ""
echo "Documentation:"
echo "  GET  /docs                          - Swagger UI"
echo "  GET  /openapi.json                  - OpenAPI spec"
echo "================================================================================"
echo ""
