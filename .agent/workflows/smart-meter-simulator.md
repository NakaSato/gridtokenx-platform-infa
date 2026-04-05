---
description: Run and manage the Smart Meter Simulator
---

# Smart Meter Simulator

Simulate smart meter readings and IoT device data for testing the GridTokenX platform.

## Quick Commands

// turbo

```bash
# Start simulator (API + UI)
./scripts/app.sh start

# Or start manually
docker-compose up -d smartmeter-simulator smartmeter-ui
```

## Architecture

The Smart Meter Simulator consists of:

| Component | Port | Technology |
|-----------|------|------------|
| Simulator API | 8082 | Python/FastAPI |
| Simulator UI | 5173 | React/Vite |

### Data Flow

```
Smart Meter Simulator → Kafka → API Gateway → PostgreSQL/InfluxDB
                              ↓
                        Trading Engine
```

## Starting the Simulator

### With Docker Compose

```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa

# Start simulator services
docker-compose up -d smartmeter-simulator smartmeter-ui

# Check status
docker-compose ps
```

### Manual Start (Development)

```bash
# Start API
cd gridtokenx-smartmeter-simulator
uv run start

# Start UI (in another terminal)
cd gridtokenx-smartmeter-simulator/ui
bun run dev
```

## Accessing the Simulator

### Web Interface

Open http://localhost:5173 to access the simulator UI.

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/meters` | GET | List meters |
| `/api/v1/meters` | POST | Create meter |
| `/api/v1/meters/{id}` | GET | Get meter details |
| `/api/v1/meters/{id}/readings` | GET | Get meter readings |
| `/api/v1/simulate` | POST | Start simulation |
| `/api/v1/simulate/stop` | POST | Stop simulation |

## Configuration

### Environment Variables

```bash
# Smart Meter Simulator
PORT=8080
LOG_LEVEL=info
KAFKA_BOOTSTRAP_SERVERS=kafka:9092
INFLUXDB_URL=http://influxdb:8086
INFLUXDB_TOKEN=your-influxdb-token
INFLUXDB_ORG=gridtokenx
INFLUXDB_BUCKET=energy_readings
DATABASE_URL=postgresql://gridtokenx_user:gridtokenx_password@postgres:5432/gridtokenx
API_GATEWAY_URL=http://host.docker.internal:4000
```

### Simulation Settings

Configure in UI or via API:

```json
{
  "interval_seconds": 60,
  "meters_count": 10,
  "energy_range_kwh": [0.5, 5.0],
  "price_per_kwh": 0.15,
  "enable_randomness": true
}
```

## Simulation Modes

### 1. Real-time Simulation

Meters send readings at configured intervals:

```bash
curl -X POST http://localhost:8082/api/v1/simulate \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "realtime",
    "interval": 60
  }'
```

### 2. Batch Simulation

Send historical data in batches:

```bash
curl -X POST http://localhost:8082/api/v1/simulate \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "batch",
    "start_date": "2024-01-01",
    "end_date": "2024-01-31",
    "batch_size": 1000
  }'
```

### 3. Pattern Simulation

Simulate specific usage patterns:

```bash
curl -X POST http://localhost:8082/api/v1/simulate \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "pattern",
    "pattern": "residential",
    "season": "summer"
  }'
```

Available patterns:
- `residential` - Typical home usage
- `commercial` - Business usage
- `industrial` - Factory usage
- `solar` - Solar panel generation
- `wind` - Wind turbine generation

## Creating Meters

### Single Meter

```bash
curl -X POST http://localhost:8082/api/v1/meters \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Home Meter 1",
    "type": "residential",
    "location": "Zone A",
    "capacity_kwh": 10.0
  }'
```

### Bulk Create

```bash
curl -X POST http://localhost:8082/api/v1/meters/bulk \
  -H "Content-Type: application/json" \
  -d '{
    "count": 100,
    "type": "residential",
    "zones": ["Zone A", "Zone B", "Zone C"]
  }'
```

## Viewing Data

### InfluxDB Query

```bash
# Query recent readings
curl -X POST http://localhost:8086/api/v2/query \
  -H "Authorization: Token your-influxdb-token" \
  -H "Content-Type: application/vnd.flux" \
  -d 'from(bucket:"energy_readings")
    |> range(start: -1h)
    |> filter(fn: (r) => r._measurement == "meter_readings")'
```

### PostgreSQL Query

```bash
docker exec -it gridtokenx-postgres psql \
  -U gridtokenx_user -d gridtokenx \
  -c "SELECT * FROM meter_readings ORDER BY timestamp DESC LIMIT 10"
```

## Integration Testing

### Test Meter Data Pipeline

```bash
./gridtokenx-api/tests/scripts/simulate_grid_readings.sh
```

### Test Tokenization

Verify energy readings are converted to tokens:

```bash
# Check token balances
curl -X GET http://localhost:4000/api/v1/users/{user_id}/tokens \
  -H "Authorization: Bearer $TOKEN"
```

## Troubleshooting

### Simulator Won't Start

```bash
# Check Kafka is running
docker-compose ps kafka

# Check logs
docker-compose logs smartmeter-simulator
```

### No Data in Database

```bash
# Verify Kafka topic exists
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --list

# Check consumer group
docker exec gridtokenx-kafka \
  /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --describe
```

### UI Not Accessible

```bash
# Check container status
docker-compose ps smartmeter-ui

# Restart UI
docker-compose restart smartmeter-ui
```

## Related Workflows

- [Start Development](./start-dev.md) - Start full platform
- [Testing](./testing.md) - Run integration tests
- [Docker Services](./docker-services.md) - Manage containers
