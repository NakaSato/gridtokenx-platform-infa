---
name: Kafka Management
description: Manage Kafka services, topics, and message debugging for GridTokenX platform
---

# Kafka Management Skill

This skill provides instructions for managing Kafka in the GridTokenX platform.

## Prerequisites

- Docker and Docker Compose installed
- GridTokenX platform repository cloned
- Kafka service defined in `docker-compose.yml`

## Service Details

| Property | Value |
|----------|-------|
| Image | `apache/kafka:3.7.0` |
| Container | `gridtokenx-kafka` |
| Port | `9092` |
| Topic | `meter-readings` |
| Mode | KRaft (no Zookeeper) |

## Common Operations

### Start Kafka Only
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa
docker compose up -d kafka
```

### Check Kafka Status
```bash
docker compose ps kafka
docker compose logs kafka --tail 50
```

### List Topics
```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list
```

### Create Topic Manually
```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic meter-readings \
  --partitions 3 \
  --replication-factor 1
```

### Describe Topic
```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --topic meter-readings
```

### Consume Messages (from beginning)
```bash
docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic meter-readings \
  --from-beginning
```

### Consume Messages (latest only)
```bash
docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic meter-readings
```

### Produce Test Message
```bash
docker compose exec kafka bash -c "echo '{\"meter_serial\":\"TEST-001\",\"kwh\":12.5,\"timestamp\":\"2026-01-16T12:00:00Z\"}' | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic meter-readings"
```

### Check Consumer Groups
```bash
docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list
```

### Describe Consumer Group Lag
```bash
docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --group gridtokenx-apigateway
```

### Delete Topic (caution!)
```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --delete \
  --topic meter-readings
```

### Reset Consumer Group Offset
```bash
docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group gridtokenx-apigateway \
  --topic meter-readings \
  --reset-offsets \
  --to-earliest \
  --execute
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KAFKA_PORT` | `9092` | Kafka broker port |
| `KAFKA_BOOTSTRAP_SERVERS` | `kafka:9092` | Bootstrap servers for clients |
| `KAFKA_TOPIC` | `meter-readings` | Default topic for meter readings |
| `KAFKA_CONSUMER_GROUP` | `gridtokenx-apigateway` | Consumer group ID |
| `KAFKA_ENABLED` | `true` | Enable/disable Kafka integration |

## Troubleshooting

### Kafka container not starting
```bash
# Check logs
docker compose logs kafka

# Remove volume and restart
docker compose down -v
docker compose up -d kafka
```

### Connection refused from host
- Kafka's advertised listener is `kafka:9092` (Docker internal)
- From host machine, access via `localhost:9092` only if port is mapped
- From other containers, use `kafka:9092`

### Topic not found
Topics are auto-created when the first message is sent. If auto-create is disabled:
```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic meter-readings \
  --partitions 3 \
  --replication-factor 1
```

## Related Files

- Producer: `gridtokenx-smartmeter-simulator/src/app/transport/kafka.py`
- Consumer: `gridtokenx-apigateway/src/services/kafka/consumer.rs`
- Docker: `docker-compose.yml` (kafka service)
- Config: `.env.example` (Kafka variables)
