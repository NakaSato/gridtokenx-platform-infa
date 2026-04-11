# GridTokenX Hybrid Messaging Architecture

## Overview

This document defines the hybrid messaging strategy combining **Kafka**, **Redis**, and **RabbitMQ** for optimal performance, reliability, and scalability.

---

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                    **HYBRID MESSAGING LAYER**                         │
│                                                                       │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────────┐      │
│  │     KAFKA        │  │    REDIS     │  │   RABBITMQ       │      │
│  │                  │  │              │  │                  │      │
│  │ Event Streaming  │  │ Cache +      │  │ Task Queues +    │      │
│  │ & Event Sourcing │  │ Real-time    │  │ RPC              │      │
│  │                  │  │              │  │                  │      │
│  │ Port: 9092       │  │ Port: 6379   │  │ Port: 5672       │      │
│  │                  │  │              │  │ Mgmt: 15672      │      │
│  └────────┬─────────┘  └──────┬───────┘  └────────┬─────────┘      │
│           │                   │                    │                 │
└───────────┼───────────────────┼────────────────────┼─────────────────┘
            │                   │                    │
            ▼                   ▼                    ▼
┌────────────────────────────────────────────────────────────────────┐
│                    **MICROSERVICE USAGE**                           │
│                                                                     │
│  Kafka          Redis           RabbitMQ                            │
│  ┌──────────┐  ┌────────────┐  ┌──────────────┐                  │
│  │ IAM:     │  │ IAM:       │  │ IAM:         │                  │
│  │ • User   │  │ • Session  │  │ • Welcome    │                  │
│  │   events │  │ • Tokens   │  │   emails     │                  │
│  │ • KYC    │  │ • Cache    │  │ • Password   │                  │
│  │   events │  │            │  │   resets     │                  │
│  │          │  │            │  │              │                  │
│  │ Trading: │  │ Trading:   │  │ Trading:     │                  │
│  │ • Order  │  │ • Order    │  │ • Settlement │                  │
│  │   events │  │   book     │  │   retries    │                  │
│  │ • Trade  │  │ • Market   │  │ • Failed     │                  │
│  │   events │  │   data     │  │   trades     │                  │
│  │ • Settle │  │ • Price    │  │              │                  │
│  │   events │  │   cache    │  │              │                  │
│  │          │  │            │  │              │                  │
│  │ Oracle:  │  │ Oracle:    │  │ Oracle:      │                  │
│  │ • Meter  │  │ • Reading  │  │ • Meter      │                  │
│  │   events │  │   cache    │  │   retries    │                  │
│  │ • Price  │  │ • Price    │  │ • Data       │                  │
│  │   feeds  │  │   feeds    │  │   validation │                  │
│  │          │  │            │  │   jobs       │                  │
│  │ Edge:    │  │ Edge:      │  │              │                  │
│  │ • Device │  │ • Local    │  │              │                  │
│  │   events │  │   buffer   │  │              │                  │
│  └──────────┘  └────────────┘  └──────────────┘                  │
└────────────────────────────────────────────────────────────────────┘
```

---

## Message Routing Strategy

### **1. Kafka - Event Sourcing & Streaming**

**Purpose**: Immutable event log, replayable, high-throughput, multiple consumers

| Topic | Producer | Consumers | Retention | Partitions |
|-------|----------|-----------|-----------|------------|
| `user.events` | IAM Service | API Gateway, Analytics, Audit | 30 days | 6 |
| `kyc.events` | IAM Service | Compliance, Audit | 7 years | 3 |
| `order.events` | Trading Service | Settlement, Analytics, WS | 90 days | 12 |
| `trade.events` | Trading Service | Blockchain, Reporting, ML | 7 years | 12 |
| `settlement.events` | Trading Service | Blockchain, Reconciliation | 7 years | 6 |
| `meter.readings` | Oracle Service | InfluxDB, Analytics, Billing | 1 year | 24 |
| `price.feeds` | Oracle Service | Trading, Dashboard, ML | 7 days | 6 |
| `edge.telemetry` | Edge Gateway | Oracle Service, Monitoring | 30 days | 12 |

**Key Features:**
- ✅ Event replay for auditing
- ✅ Multiple consumers per topic
- ✅ Exactly-once semantics
- ✅ Schema evolution (Avro/Protobuf)

---

### **2. Redis - Cache & Real-time**

**Purpose**: Ultra-fast access, real-time broadcasting, temporary state

| Feature | Usage | TTL | Persistence |
|---------|-------|-----|-------------|
| **Pub/Sub** | WebSocket broadcasts | N/A | ❌ No |
| **Streams** | Short-term event bus | 24 hours | ✅ AOF |
| **Hashes** | User sessions, tokens | 24 hours | ✅ AOF |
| **Sorted Sets** | Leaderboards, rankings | N/A | ✅ AOF |
| **Lists** | Job queues (non-critical) | N/A | ✅ AOF |

**Key Features:**
- ✅ Sub-millisecond latency
- ✅ Simple API
- ✅ Built-in data structures
- ✅ Pub/Sub for fan-out

---

### **3. RabbitMQ - Task Queues & RPC**

**Purpose**: Guaranteed delivery, retry logic, complex routing, async tasks

| Queue | Exchange | Routing Key | Consumer | DLQ |
|-------|----------|-------------|----------|-----|
| `email.notifications` | `notifications` | `email.*` | Email Worker | ✅ |
| `password.resets` | `auth` | `password.reset` | Auth Worker | ✅ |
| `settlement.retries` | `trading` | `settlement.retry` | Settlement Worker | ✅ |
| `meter.validation` | `oracle` | `meter.validate` | Validation Worker | ✅ |
| `batch.jobs` | `scheduler` | `batch.*` | Batch Processor | ✅ |
| `webhook.deliveries` | `integrations` | `webhook.*` | Webhook Worker | ✅ |

**Key Features:**
- ✅ Message acknowledgment
- ✅ Dead letter queues
- ✅ Priority queues
- ✅ Delayed messages
- ✅ Message TTL

---

## Implementation Plan

### **Phase 1: Infrastructure Setup**

**Docker Compose Additions:**
```yaml
services:
  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: gridtokenx
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD:-rabbitmq_secret}
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - gridtokenx-network

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
    networks:
      - gridtokenx-network

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks:
      - gridtokenx-network
```

---

### **Phase 2: Service Integration**

#### **IAM Service**

```rust
// gridtokenx-iam-service/src/infra/messaging/mod.rs

pub mod kafka_producer;
pub mod rabbitmq_consumer;

// Kafka Producer for user events
pub struct IamKafkaProducer {
    producer: FutureProducer,
}

impl IamKafkaProducer {
    pub async fn publish_user_event(&self, event: UserEvent) -> Result<()> {
        let payload = serde_json::to_string(&event)?;
        
        self.producer.send(
            FutureRecord::to("user.events")
                .key(&event.user_id.to_string())
                .payload(&payload)
                .timestamp(Utc::now().timestamp_millis()),
            Duration::from_secs(0),
        ).await.map_err(|e| anyhow::anyhow!("Kafka error: {:?}", e))?;
        
        Ok(())
    }
}

// RabbitMQ Consumer for email notifications
pub struct IamRabbitmqConsumer {
    channel: Channel,
}

impl IamRabbitmqConsumer {
    pub async fn consume_email_queue(&self) -> Result<()> {
        let mut stream = self.channel.basic_consume(
            "email.notifications",
            "iam_email_worker",
            BasicConsumeOptions::default(),
            FieldTable::default(),
        )?;
        
        while let Some(delivery) = stream.next().await {
            let delivery = delivery?;
            self.process_email(delivery).await?;
            delivery.ack(BasicAckOptions::default()).await?;
        }
        
        Ok(())
    }
}
```

---

#### **Trading Service**

```rust
// gridtokenx-trading-service/src/infra/messaging/mod.rs

pub struct TradingKafkaProducer {
    producer: FutureProducer,
}

impl TradingKafkaProducer {
    pub async fn publish_order_event(&self, event: OrderEvent) -> Result<()> {
        let payload = serde_json::to_string(&event)?;
        
        self.producer.send(
            FutureRecord::to("order.events")
                .key(&event.order_id.to_string())
                .payload(&payload),
            Duration::from_secs(0),
        ).await?;
        
        Ok(())
    }
    
    pub async fn publish_trade_event(&self, event: TradeEvent) -> Result<()> {
        let payload = serde_json::to_string(&event)?;
        
        self.producer.send(
            FutureRecord::to("trade.events")
                .key(&event.trade_id.to_string())
                .payload(&payload),
            Duration::from_secs(0),
        ).await?;
        
        Ok(())
    }
}

// RabbitMQ for settlement retries
pub struct TradingRabbitmqProducer {
    channel: Channel,
}

impl TradingRabbitmqProducer {
    pub async fn publish_settlement_retry(&self, retry: SettlementRetry) -> Result<()> {
        let payload = serde_json::to_string(&retry)?;
        
        self.channel.basic_publish(
            "trading",
            "settlement.retry",
            BasicPublishOptions::default(),
            payload.as_bytes(),
            BasicProperties::default()
                .delivery_mode(DeliveryMode::Persistent)
                .priority(retry.priority),
        ).await?;
        
        Ok(())
    }
}
```

---

#### **Oracle Service**

```rust
// gridtokenx-oracle-bridge/src/infra/messaging/mod.rs

pub struct OracleKafkaProducer {
    producer: FutureProducer,
}

impl OracleKafkaProducer {
    pub async fn publish_meter_reading(&self, reading: MeterReading) -> Result<()> {
        let payload = serde_json::to_string(&reading)?;
        
        self.producer.send(
            FutureRecord::to("meter.readings")
                .key(&reading.meter_id.to_string())
                .payload(&payload),
            Duration::from_secs(0),
        ).await?;
        
        Ok(())
    }
    
    pub async fn publish_price_feed(&self, feed: PriceFeed) -> Result<()> {
        let payload = serde_json::to_string(&feed)?;
        
        self.producer.send(
            FutureRecord::to("price.feeds")
                .key(&feed.timestamp.to_string())
                .payload(&payload),
            Duration::from_secs(0),
        ).await?;
        
        Ok(())
    }
}
```

---

#### **API Gateway**

```rust
// gridtokenx-api/src/infra/messaging/kafka_consumer.rs

pub struct KafkaEventConsumer {
    consumer: StreamConsumer,
    redis_client: RedisClient,
}

impl KafkaEventConsumer {
    pub async fn consume_and_broadcast(&self) -> Result<()> {
        let mut stream = self.consumer.stream();
        
        while let Some(message) = stream.next().await {
            let message = message?;
            
            // Extract event type from topic
            let event_type = message.topic();
            let payload = message.payload_view::<str>().unwrap_or("").to_string();
            
            // Publish to Redis Pub/Sub for WebSocket broadcast
            self.redis_client.publish("gridtokenx_market_events", &payload).await?;
            
            // Acknowledge Kafka message
            message.commit(CommitMode::Sync).await?;
        }
        
        Ok(())
    }
}
```

---

### **Phase 3: Configuration**

#### **Environment Variables**

```bash
# Kafka Configuration
KAFKA_BROKERS=localhost:9092
KAFKA_CONSUMER_GROUP=gridtokenx-api
KAFKA_AUTO_OFFSET_RESET=earliest
KAFKA_ENABLE_AUTO_COMMIT=false

# RabbitMQ Configuration
RABBITMQ_URL=amqp://gridtokenx:rabbitmq_secret@localhost:5672
RABBITMQ_EXCHANGE_EVENTS=gridtokenx_events
RABBITMQ_EXCHANGE_TASKS=gridtokenx_tasks

# Redis Configuration (existing)
REDIS_URL=redis://localhost:6379
REDIS_STREAM_NAME=gridtokenx:events:v1
```

---

### **Phase 4: Topic & Queue Creation**

**Kafka Topics (auto-created or manual):**
```bash
# Create topics with proper partitions
kafka-topics --create --topic user.events --partitions 6 --replication-factor 1
kafka-topics --create --topic kyc.events --partitions 3 --replication-factor 1
kafka-topics --create --topic order.events --partitions 12 --replication-factor 1
kafka-topics --create --topic trade.events --partitions 12 --replication-factor 1
kafka-topics --create --topic settlement.events --partitions 6 --replication-factor 1
kafka-topics --create --topic meter.readings --partitions 24 --replication-factor 1
kafka-topics --create --topic price.feeds --partitions 6 --replication-factor 1
kafka-topics --create --topic edge.telemetry --partitions 12 --replication-factor 1
```

**RabbitMQ Queues & Exchanges:**
```rust
// Declare on service startup
channel.exchange_declare("notifications", ExchangeKind::Topic, ...);
channel.exchange_declare("trading", ExchangeKind::Topic, ...);
channel.exchange_declare("oracle", ExchangeKind::Topic, ...);

channel.queue_declare("email.notifications", ...);
channel.queue_declare("password.resets", ...);
channel.queue_declare("settlement.retries", ...);
channel.queue_declare("meter.validation", ...);

// Bind queues to exchanges
channel.queue_bind("email.notifications", "notifications", "email.*", ...);
channel.queue_bind("settlement.retries", "trading", "settlement.retry", ...);
```

---

## Migration Strategy

### **From Redis Streams to Hybrid**

```
Step 1: Deploy Kafka + RabbitMQ (parallel to Redis)
        ↓
Step 2: Dual-write events (Redis + Kafka) for 1 week
        ↓
Step 3: Migrate consumers to Kafka
        ↓
Step 4: Keep Redis for cache + Pub/Sub only
        ↓
Step 5: Remove Redis Streams usage
```

---

## Monitoring & Observability

### **Metrics to Track**

| System | Metrics | Alerts |
|--------|---------|--------|
| **Kafka** | Consumer lag, throughput, latency | Lag > 10K, errors |
| **RabbitMQ** | Queue depth, unacked messages, DLQ size | DLQ > 100, queues full |
| **Redis** | Memory usage, hit rate, Pub/Sub subscribers | Memory > 80%, misses |

### **Dashboards**

- **Kafka**: Confluent Control Center or Kafka Eagle
- **RabbitMQ**: Built-in Management UI (port 15672)
- **Redis**: RedisInsight or Grafana dashboard

---

## Performance Benchmarks

| Scenario | Redis Streams | Kafka | RabbitMQ |
|----------|--------------|-------|----------|
| **Simple pub/sub** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Event replay** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ |
| **High throughput** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Task queues** | ⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ |
| **Guaranteed delivery** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Complex routing** | ⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## Cost Estimate

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| **Redis** | 1 node (2GB) | 2 nodes (4GB) | 3 nodes (8GB) |
| **Kafka** | 1 broker (4GB) | 3 brokers (8GB) | 5 brokers (16GB) |
| **RabbitMQ** | 1 node (2GB) | 2 nodes (4GB) | 3 nodes (8GB) |
| **Total RAM** | ~8GB | ~20GB | ~60GB |

---

## Conclusion

The hybrid approach provides:
- ✅ **Kafka**: Reliable event sourcing & streaming
- ✅ **Redis**: Ultra-fast cache & real-time broadcast
- ✅ **RabbitMQ**: Guaranteed task delivery & complex routing

This architecture scales from MVP to production without major refactoring.
