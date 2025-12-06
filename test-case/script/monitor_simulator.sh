#!/bin/bash
# Start Smart Meter Simulator and Monitor Real-Time Readings

SIMULATOR_URL="http://localhost:8000"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo "================================================================================"
echo "Smart Meter Simulator - Real-Time Monitoring"
echo "================================================================================"
echo ""

# 1. Check current status
echo -e "${BLUE}Step 1: Checking Simulator Status${NC}"
STATUS=$(curl -s "$SIMULATOR_URL/api/status")
IS_RUNNING=$(echo "$STATUS" | jq -r '.running')
NUM_METERS=$(echo "$STATUS" | jq -r '.num_meters')

echo "Status: $(echo "$STATUS" | jq -r '.status')"
echo "Running: $IS_RUNNING"
echo "Meters: $NUM_METERS"
echo ""

# 2. Start simulator if not running
if [ "$IS_RUNNING" != "true" ]; then
    echo -e "${BLUE}Step 2: Starting Simulator${NC}"
    START_RESPONSE=$(curl -s -X POST "$SIMULATOR_URL/api/control/start")
    echo "$START_RESPONSE" | jq '.'
    echo -e "${GREEN}✅ Simulator started${NC}"
    echo ""
    sleep 2
else
    echo -e "${YELLOW}Simulator already running${NC}"
    echo ""
fi

# 3. Get meter IDs
METER_IDS=$(curl -s "$SIMULATOR_URL/api/status" | jq -r '.meters[].meter_id')

if [ -z "$METER_IDS" ]; then
    echo -e "${RED}❌ No meters found in simulator${NC}"
    exit 1
fi

echo -e "${BLUE}Step 3: Monitoring Meter Readings${NC}"
echo "Press Ctrl+C to stop monitoring"
echo ""
echo "Time          | Generation | Consumption | Net      | Voltage | Current | Temp   | Battery"
echo "--------------|------------|-------------|----------|---------|---------|--------|--------"

# 4. Monitor readings in real-time
COUNTER=0
while true; do
    for METER_ID in $METER_IDS; do
        METER_DATA=$(curl -s "$SIMULATOR_URL/api/meters/$METER_ID/status")
        
        # Extract latest reading
        TIMESTAMP=$(echo "$METER_DATA" | jq -r '.latest_reading.timestamp // "N/A"')
        GENERATION=$(echo "$METER_DATA" | jq -r '.latest_reading.energy_generated // 0')
        CONSUMPTION=$(echo "$METER_DATA" | jq -r '.latest_reading.energy_consumed // 0')
        NET=$(echo "$METER_DATA" | jq -r '.latest_reading.net_emission // 0')
        VOLTAGE=$(echo "$METER_DATA" | jq -r '.latest_reading.voltage // 0')
        CURRENT=$(echo "$METER_DATA" | jq -r '.latest_reading.current // 0')
        TEMP=$(echo "$METER_DATA" | jq -r '.latest_reading.temperature // 0')
        BATTERY=$(echo "$METER_DATA" | jq -r '.latest_reading.battery_level // 0')
        
        # Format time
        TIME_DISPLAY=$(date +"%H:%M:%S")
        
        # Color code based on net energy
        if (( $(echo "$NET > 0" | bc -l) )); then
            NET_COLOR=$GREEN
        elif (( $(echo "$NET < 0" | bc -l) )); then
            NET_COLOR=$YELLOW
        else
            NET_COLOR=$NC
        fi
        
        # Display reading
        printf "%s | ${GREEN}%8.4f${NC} | ${YELLOW}%9.4f${NC} | ${NET_COLOR}%7.4f${NC} | %7.2f | %7.3f | %6.1f | %7.1f%%\n" \
            "$TIME_DISPLAY" "$GENERATION" "$CONSUMPTION" "$NET" "$VOLTAGE" "$CURRENT" "$TEMP" "$BATTERY"
    done
    
    COUNTER=$((COUNTER + 1))
    
    # Show summary every 10 readings
    if [ $((COUNTER % 10)) -eq 0 ]; then
        echo ""
        echo -e "${CYAN}--- Reading #$COUNTER ---${NC}"
        echo ""
    fi
    
    sleep 5
done
