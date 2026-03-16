#!/bin/bash
echo "=== High Load Stress Test ==="
echo ""
echo "Sending 100 concurrent requests to port 4000..."
echo ""

# Send 100 concurrent requests
for i in {1..100}; do
    curl -s http://localhost:4000/health -o /dev/null &
done

# Wait for all to complete
wait

echo ""
echo "All 100 requests completed!"
echo ""

# Check API Gateway logs for load distribution
echo "Checking API Gateway Node 1 (Port 4001) process:"
ps aux | grep "api-gateway" | grep -v grep | head -2

echo ""
echo "Checking Nginx container:"
docker-compose ps nginx

echo ""
echo "Checking Prometheus metrics endpoint:"
curl -s http://localhost:9090/api/v1/query?query=up | head -100 || echo "Prometheus not responding"
