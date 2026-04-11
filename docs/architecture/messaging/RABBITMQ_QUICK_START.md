# RabbitMQ Quick Start Guide

## 🚀 Start RabbitMQ

```bash
# Option 1: Start RabbitMQ only
docker-compose up -d rabbitmq

# Option 2: Start entire platform
./scripts/app.sh start
```

## ✅ Verify Installation

```bash
# Check container is running
docker ps | grep rabbitmq

# Check RabbitMQ status
docker exec gridtokenx-rabbitmq rabbitmq-diagnostics ping

# Expected output: Server reports status as OK
```

## 🔐 Access Management UI

1. Open browser: **http://localhost:15672**
2. Login credentials:
   - **Username**: `gridtokenx`
   - **Password**: `rabbitmq_secret_2025`

## 📊 Verify Resources

```bash
# List all queues
docker exec gridtokenx-rabbitmq rabbitmqadmin list queues name messages

# Expected output:
# +------------------------+----------+
# |          name          | messages |
# +------------------------+----------+
# | email.notifications    | 0        |
# | password.resets        | 0        |
# | settlement.retries     | 0        |
# | meter.validation       | 0        |
# | batch.jobs             | 0        |
# | webhook.deliveries     | 0        |
# +------------------------+----------+

# List all exchanges
docker exec gridtokenx-rabbitmq rabbitmqadmin list exchanges name type

# Expected output:
# +------------------+------+
# |       name       | type |
# +------------------+------+
# | notifications    | topic|
# | trading          | topic|
# | oracle           | topic|
# | scheduler        | topic|
# | integrations     | topic|
# | dlx.exchange     | direct|
# +------------------+------+
```

## 🧪 Test Message Publishing

```bash
# Publish a test message
docker exec gridtokenx-rabbitmq rabbitmqadmin publish \
  exchange=notifications \
  routing_key=email.welcome \
  payload='{"user_id":"test-123","email":"test@example.com","template":"welcome"}'

# Verify message arrived in queue
docker exec gridtokenx-rabbitmq rabbitmqadmin get queue=email.notifications requeue=false

# Expected output:
# +----------------+----------+---------------+-------------------+
# | routing_key    | exchange | message_count |      payload      |
# +----------------+----------+---------------+-------------------+
# | email.welcome  |          | 0             | {"user_id":...}   |
# +----------------+----------+---------------+-------------------+
```

## 🔍 Monitor Queue Depth

```bash
# Real-time queue monitoring
watch -n 2 'docker exec gridtokenx-rabbitmq rabbitmqctl list_queues name messages consumers'

# Expected output (updates every 2 seconds):
# Listing queues for vhost / ...
# name                   messages  consumers
# email.notifications    5         1
# password.resets        0         1
# settlement.retries     2         2
# meter.validation       10        1
# batch.jobs             0         0
# webhook.deliveries     0         1
```

## 🛠️ Common Commands

```bash
# View logs
docker logs -f gridtokenx-rabbitmq

# Restart RabbitMQ
docker-compose restart rabbitmq

# Stop RabbitMQ
docker-compose stop rabbitmq

# Reset RabbitMQ (deletes all data)
docker-compose down rabbitmq
docker volume rm gridtokenx-platform-infa_rabbitmq_data
docker-compose up -d rabbitmq

# Re-initialize queues and exchanges
docker exec gridtokenx-rabbitmq rabbitmqctl stop_app
docker exec gridtokenx-rabbitmq rabbitmqctl reset
docker exec gridtokenx-rabbitmq rabbitmqctl start_app
./docker/rabbitmq/init-rabbitmq.sh
```

## 🔧 Environment Variables

```bash
# Check current configuration
docker exec gridtokenx-rabbitmq env | grep RABBITMQ

# Override in .env file
RABBITMQ_PORT=5672
RABBITMQ_MGMT_PORT=15672
RABBITMQ_DEFAULT_USER=gridtokenx
RABBITMQ_DEFAULT_PASS=your_secure_password
```

## 📈 Monitoring

### Management UI Features

Access **http://localhost:15672** to:
- **Overview**: Connection counts, message rates
- **Queues**: Depth, consumers, message details
- **Exchanges**: Bindings, routing
- **Connections**: Active AMQP connections
- **Channels**: Channel activity
- **Admin**: User management, policies

### Prometheus Metrics

```bash
# Access metrics endpoint
curl -u gridtokenx:rabbitmq_secret_2025 http://localhost:15672/api/metrics

# Add to Prometheus configuration
# See ../../../docker/rabbitmq/README.md for details
```

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs gridtokenx-rabbitmq

# Common issues:
# 1. Port already in use
lsof -ti:5672 | xargs kill -9
lsof -ti:15672 | xargs kill -9

# 2. Volume permissions
docker volume rm gridtokenx-platform-infa_rabbitmq_data
docker-compose up -d rabbitmq
```

### Queues Not Created

```bash
# Manually run initialization
docker exec gridtokenx-rabbitmq bash /docker-entrypoint-initdb.d/init-rabbitmq.sh 2>/dev/null || \
./docker/rabbitmq/init-rabbitmq.sh
```

### Connection Issues

```bash
# Test AMQP connection
docker run --rm --network gridtokenx-platform-infa_gridtokenx-network \
  rabbitmq:3.13-management-alpine \
  bash -c "apt-get update && apt-get install -y netcat-openbsd && \
  nc -zv rabbitmq 5672"

# Expected output: Connection to rabbitmq 5672 port [tcp/amqp] succeeded!
```

## 📚 Next Steps

1. ✅ RabbitMQ infrastructure is ready
2. ⏳ Add `lapin` dependency to Rust services
3. ⏳ Implement producers and consumers
4. ⏳ Test message flow end-to-end
5. ⏳ Set up monitoring and alerts

## 📖 Documentation

- [Full RabbitMQ Setup Guide](../../../docker/rabbitmq/README.md)
- [Hybrid Messaging Architecture](./HYBRID_MESSAGING_ARCHITECTURE.md)
- [Integration Summary](./RABBITMQ_INTEGRATION_SUMMARY.md)

---

**Need help?** Check the troubleshooting section or view logs with `docker logs gridtokenx-rabbitmq`
