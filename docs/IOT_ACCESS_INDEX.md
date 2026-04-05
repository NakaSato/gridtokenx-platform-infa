# IoT Access Architecture - Documentation Index

## Overview

This is the complete documentation for the GridTokenX IoT access architecture, covering the full data flow from IoT devices through the Oracle Bridge, API Gateway, and finally to the Solana blockchain.

---

## 📚 Documentation Structure

### 🎯 Start Here
**File:** [`IOT_ACCESS_REVIEW_PACKAGE.md`](./IOT_ACCESS_REVIEW_PACKAGE.md) - **For team review meetings**  
**File:** [`IOT_ACCESS_FAQ.md`](./IOT_ACCESS_FAQ.md) - **Common questions & answers**

### 1. Core Architecture
**File:** [`IOT_ACCESS_ARCHITECTURE.md`](./IOT_ACCESS_ARCHITECTURE.md)

**Contents:**
- High-level architecture diagram
- Component responsibilities
- Data models (DeviceReading, gRPC, On-Chain)
- API specifications (HTTP, gRPC, Blockchain)
- Security architecture (3-layer authentication)
- Reliability patterns (at-least-once delivery, idempotency)
- Observability (metrics, tracing, alerting)
- Performance benchmarks
- Deployment architecture (dev, staging, production)
- Cost analysis
- Implementation roadmap

**Key Diagrams:**
```
IoT Devices → Oracle Bridge → API Gateway → Blockchain
```

---

### 2. Sequence Diagrams
**File:** [`IOT_ACCESS_SEQUENCE_DIAGRAMS.md`](./IOT_ACCESS_SEQUENCE_DIAGRAMS.md)

**Contents:**
1. **Device Registration Flow** - Ed25519 keypair generation, API key provisioning
2. **Meter Reading Submission Flow** - End-to-end data flow with timing
3. **DR Event Response Flow** - Price signal response and credit calculation
4. **Batch Blockchain Submission Flow** - Gas-optimized batch processing
5. **Error Handling & Retry Flow** - Exponential backoff, dead letter queue
6. **Device Authentication Flow** - API key validation with IAM fallback
7. **Blockchain PDA Derivation Flow** - Account derivation and transaction construction
8. **Complete End-to-End Flow** - Full system integration

**Timing Analysis:**
| Phase | P50 | P95 | P99 |
|-------|-----|-----|-----|
| End-to-End | 550ms | 2.1s | 5.2s |

---

### 3. Implementation Guide
**File:** [`IOT_ACCESS_IMPLEMENTATION.md`](./IOT_ACCESS_IMPLEMENTATION.md)

**Contents:**
1. **Oracle Bridge Implementation**
   - Project structure
   - HTTP handlers (Axum)
   - Protocol adapter pattern
   - Redis Stream router

2. **API Gateway Implementation**
   - gRPC service definition (Protobuf)
   - Service implementation (Tonic)
   - Batch aggregator

3. **Solana Oracle Program**
   - Program structure (Anchor)
   - Account definitions (PDAs)
   - Instructions (submitMeterReading, submitBatchReadings)
   - Events and errors

4. **Configuration Files**
   - Docker Compose
   - Environment variables

5. **Testing**
   - Integration test scripts
   - Example payloads

---

## 🏗️ Architecture Summary

### Component Overview

| Component | Port | Protocol | Responsibility |
|-----------|------|----------|----------------|
| **Oracle Bridge** | 4010 | HTTP/JSON | IoT ingestion, protocol translation |
| **API Gateway** | 4001 | gRPC | Business logic, data persistence |
| **Redis Streams** | 6379 | Redis | Event buffering, backpressure |
| **PostgreSQL** | 5432 | SQL | Relational data storage |
| **Solana RPC** | 8899 | JSON-RPC | Blockchain submission |

### Data Flow

```
┌─────────────┐
│ IoT Device  │ (ESP32-S3, Smart Meter, EV Charger)
└──────┬──────┘
       │ HTTP POST /api/v1/ingest/smart-meter
       │ X-API-KEY: device-key
       ▼
┌─────────────┐
│Oracle Bridge│ (Port 4010)
│ - Auth      │ (API key validation)
│ - Adapter   │ (Protocol → DeviceReading)
│ - Router    │ (Publish to Redis)
└──────┬──────┘
       │ XADD gridtokenx:events:v1
       ▼
┌─────────────┐
│ Redis Stream│ (Durable buffer)
└──────┬──────┘
       │ XREAD (Consumer Group)
       ▼
┌─────────────┐
│ API Gateway │ (Port 4001)
│ - gRPC      │ (SubmitMeterReading)
│ - Validate  │ (Signature, ownership)
│ - Persist   │ (PostgreSQL + InfluxDB)
│ - Batch     │ (Aggregate readings)
└──────┬──────┘
       │ submitBatchReadings()
       ▼
┌─────────────┐
│   Solana    │ (Oracle Program)
│ - PDA       │ (MeterState account)
│ - Update    │ (Cumulative energy)
│ - Event     │ (MeterReadingSubmitted)
└─────────────┘
```

---

## 🔐 Security Layers

### Layer 1: API Key Authentication
```
Device → Oracle Bridge
- X-API-KEY header
- Static keys (fallback) or IAM gRPC service
- Rate limiting per device
```

### Layer 2: Device Signature
```
Device signs payload with Ed25519 private key
API Gateway verifies against registered public key
Prevents device spoofing
```

### Layer 3: Oracle Authority
```
API Gateway signs Solana transactions
Oracle Authority keypair
PDA-based program access control
```

---

## 📊 Key Metrics

### Performance Targets

| Metric | Target | Actual (Expected) |
|--------|--------|-------------------|
| Oracle Bridge Ingestion | < 100ms | ~50ms |
| Redis Publish | < 10ms | ~5ms |
| API Gateway gRPC | < 100ms | ~85ms |
| Blockchain Submission | < 5s | ~3s |
| End-to-End | < 10s | ~5s |

### Throughput Capacity

| Component | Max Throughput | Scaling Strategy |
|-----------|---------------|------------------|
| Oracle Bridge | 1000 req/s | Horizontal (K8s HPA) |
| Redis Streams | 10,000 msg/s | Cluster mode |
| API Gateway | 500 req/s | Horizontal (K8s HPA) |
| Solana | 2000 TPS | Batch submissions |

---

## 💰 Cost Optimization

### Blockchain Fees (per device per day)

| Strategy | Cost (USD) | Savings |
|----------|------------|---------|
| Individual submissions | $0.72/day | - |
| Batch (10 readings) | $0.22/day | 70% |

**At 10,000 devices:**
- Individual: $7,200/day
- Batch: $2,200/day
- **Monthly Savings: $150,000**

---

## 🚀 Getting Started

### Quick Start (Development)

```bash
# 1. Start dependencies
cd /Users/chanthawat/Developments/gridtokenx-platform-infa
docker compose up -d redis postgres

# 2. Build and start Oracle Bridge
cargo build --package gridtokenx-oracle-bridge
RUST_LOG=info \
REDIS_URL=redis://localhost:6379 \
API_GATEWAY_URL=http://localhost:4001 \
cargo run --package gridtokenx-oracle-bridge

# 3. Test ingestion
curl -X POST http://localhost:4010/api/v1/ingest/smart-meter \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: test-key" \
  -d '{
    "device_id": "TEST-MTR-001",
    "energy_generated": 1.5,
    "energy_consumed": 0.5
  }'
```

### ESP32-S3 Integration

```cpp
// Update firmware configuration
const char* ORACLE_BRIDGE_HOST = "http://10.41.3.247:4010";
const char* API_KEY = "engineering-department-api-key-2025";

// Send meter reading
void sendMeterReading(float energyWh, float powerW) {
    HTTPClient http;
    http.begin(String(ORACLE_BRIDGE_HOST) + "/api/v1/ingest/smart-meter");
    http.addHeader("X-API-KEY", API_KEY);
    
    // ... (see FIRMWARE_SETUP.md for full implementation)
}
```

---

## 📖 Related Documentation

### Edge Meter Firmware
- [`FIRMWARE_SETUP.md`](../gridtokenx-edge-meter/FIRMWARE_SETUP.md) - ESP32-S3 setup guide
- [`FIRMWARE_UPDATE.md`](../gridtokenx-edge-meter/FIRMWARE_UPDATE.md) - OpenLEADR compatibility updates
- [`SUMMARY.md`](../gridtokenx-edge-meter/SUMMARY.md) - Firmware configuration status

### Oracle Bridge
- [`INTEGRATION_GUIDE.md`](../gridtokenx-oracle-bridge/INTEGRATION_GUIDE.md) - Oracle Bridge integration
- [`SUMMARY.md`](../gridtokenx-oracle-bridge/SUMMARY.md) - Oracle Bridge status

### VTN/DR Events
- [`VTN_INTEGRATION_TEST.md`](../gridtokenx-edge-meter/openleadr-rs/VTN_INTEGRATION_TEST.md) - VTN testing
- [`QUICK_TEST.md`](../gridtokenx-edge-meter/openleadr-rs/QUICK_TEST.md) - Quick test reference

---

## 🔧 Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid API key | Check `X-API-KEY` header, verify in IAM |
| 429 Too Many Requests | Rate limit exceeded | Implement backoff, check device frequency |
| Redis connection failed | Redis not running | `docker compose up -d redis` |
| Blockchain tx failed | Insufficient fees | Increase priority fee, check SOL balance |

### Debug Commands

```bash
# Check Oracle Bridge logs
docker compose logs -f oracle-bridge

# Monitor Redis streams
docker exec gridtokenx-redis redis-cli XREVRANGE gridtokenx:events:v1 + - COUNT 5

# Check API Gateway metrics
curl http://localhost:4001/metrics

# Verify blockchain submission
solana confirm <tx-hash> --url localhost
```

---

## 📋 Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Oracle Bridge HTTP API
- [ ] Redis Streams integration
- [ ] API Gateway gRPC service
- [ ] PostgreSQL schema
- [ ] Basic device authentication

### Phase 2: Blockchain Integration
- [ ] Oracle Program deployment
- [ ] PDA derivation logic
- [ ] Transaction submission
- [ ] Batch reading optimization
- [ ] On-chain verification

### Phase 3: Security Hardening
- [ ] Device signature verification
- [ ] IAM service integration
- [ ] Rate limiting
- [ ] TLS/mTLS configuration
- [ ] Security audit

### Phase 4: Observability
- [ ] Prometheus metrics
- [ ] Grafana dashboards
- [ ] Distributed tracing
- [ ] Alerting rules
- [ ] Log aggregation

### Phase 5: Performance & Scale
- [ ] Load testing
- [ ] Performance optimization
- [ ] Auto-scaling configuration
- [ ] Multi-region deployment
- [ ] Disaster recovery

---

## 🤔 Design Decisions FAQ

### Why three-tier architecture instead of direct device-to-blockchain?

**A**: Direct device-to-blockchain has several issues:

1. **Cost**: Each reading would cost $0.0005 (1440 readings/day = $0.72/day per device)
2. **Latency**: Devices would wait for blockchain confirmation (2-5s)
3. **Complexity**: Devices need to manage Solana accounts, keys, and RPC connections
4. **Scalability**: 10,000 devices × 1440 readings/day = 14.4M transactions/day

**Solution**: Oracle Bridge handles device complexity, Redis Streams buffer, batch submission reduces costs by 70%, devices get fast acknowledgment (< 100ms).

---

### Why Redis Streams instead of Kafka?

**A**: Both work, but Redis Streams is better for our use case:

| Criteria | Redis Streams | Kafka |
|----------|---------------|-------|
| Latency | < 10ms | 50-100ms |
| Throughput | 10K msg/s | 100K+ msg/s |
| Complexity | Single binary | Zookeeper + Brokers |
| Operations | Simple | Complex |
| Our Scale Need | 500 msg/s | 500 msg/s |

**Decision**: Redis Streams (simpler, faster, sufficient). Consider Kafka only if we exceed 50K msg/s.

---

### Why HTTP/REST instead of MQTT?

**A**: HTTP/REST is better for our case:
- Universal support (ESP32 Arduino libraries)
- Firewall-friendly (port 80/443)
- Simpler authentication (X-API-KEY header)
- Easier debugging

MQTT can be added later as an optional protocol if needed.

---

### How do we handle device offline scenarios?

**A**: Multiple strategies:
1. **Device-Side Buffering**: ESP32 stores readings in flash if offline
2. **Oracle Bridge Retry**: Exponential backoff (1, 2, 4, 8, 16, 32 seconds)
3. **Dead Letter Queue**: After 6 failures → DLQ, background retry every 5 minutes
4. **Data Retention**: Device flash (100 readings), Redis Streams (100K entries ~7 days)

---

**Document Version:** 1.0
**Last Updated:** 2026-03-27
**Maintained By:** GridTokenX Engineering
