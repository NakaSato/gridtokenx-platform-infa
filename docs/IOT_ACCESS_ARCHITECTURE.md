# IoT Access Architecture Design

## Executive Summary

This document defines the complete architecture for IoT device access to the GridTokenX platform, following a three-tier pattern:

```
IoT Devices → Oracle Bridge → API Gateway → Blockchain
```

**Design Principles:**
- **Security First**: Multi-layer authentication and authorization
- **Scalability**: Event-driven architecture with backpressure handling
- **Reliability**: At-least-once delivery with idempotency
- **Observability**: End-to-end tracing and metrics
- **Blockchain Efficiency**: Batch submission with PDA optimization

---

## 1. Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         IoT Device Layer                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │ ESP32-S3    │  │ Smart Meter │  │ EV Charger  │  │  Battery    │    │
│  │ Edge Meter  │  │ (DLMS/Modbus)│ │ (OCPP 1.6)  │  │  (SunSpec)  │    │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘    │
│         │                │                │                │            │
│         └────────────────┴────────────────┴────────────────┘            │
│                              │                                           │
│                         HTTP/JSON                                        │
│                      + X-API-KEY Auth                                    │
└──────────────────────────────┼──────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      Oracle Bridge (IoT Gateway)                         │
│                         Port: 4010                                       │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  API Key Authentication Layer                                    │    │
│  │  - Static key validation (fallback)                              │    │
│  │  - IAM gRPC service (primary)                                    │    │
│  │  - Rate limiting per device                                      │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Protocol Adapters                                               │    │
│  │  - Smart Meter Adapter  → DeviceReading                          │    │
│  │  - EV Charger Adapter   → DeviceReading                          │    │
│  │  - Battery Adapter      → DeviceReading                          │    │
│  │  - OpenADR Adapter      → DeviceReading                          │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Event Router                                                    │    │
│  │  - Publish to Redis Streams                                      │    │
│  │  - Stream: gridtokenx:events:v1                                  │    │
│  │  - Stream: gridtokenx:ev:v1                                      │    │
│  │  - Stream: gridtokenx:battery:v1                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Event Ingester (Consumer)                                       │    │
│  │  - Consume Redis Streams                                         │    │
│  │  - Forward to API Gateway (gRPC)                                 │    │
│  │  - Aggregate meter readings                                      │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────┼──────────────────────────────────────────┘
                               │
                               │ gRPC (Protocol Buffers)
                               │ - SubmitMeterReading
                               │ - SubmitEVSession
                               │ - SubmitBatteryState
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         API Gateway                                      │
│                         Port: 4001 (internal)                            │
│                         Port: 4000 (external via Nginx)                  │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  gRPC Service                                                    │    │
│  │  - IoTService.SubmitMeterReading                                 │    │
│  │  - IoTService.SubmitEVSession                                    │    │
│  │  - IoTService.SubmitBatteryState                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Business Logic Layer                                            │    │
│  │  - Validate device ownership                                     │    │
│  │  - Check DR event compliance                                     │    │
│  │  - Calculate energy credits                                      │    │
│  │  - Update user balances                                          │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Data Persistence                                                │    │
│  │  - PostgreSQL: Device metadata, transactions                     │    │
│  │  - InfluxDB: Time-series meter data                              │    │
│  │  - Kafka: Event streaming to other services                      │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Blockchain Oracle Client                                        │    │
│  │  - Batch meter readings                                          │    │
│  │  - Construct Solana transactions                                 │    │
│  │  - Submit to Oracle Program                                      │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────┼──────────────────────────────────────────┘
                               │
                               │ Solana RPC
                               │ - submitMeterReading()
                               │ - submitBatchReadings()
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      Solana Blockchain                                   │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Oracle Program (Smart Contract)                                 │    │
│  │  - Program ID: Ad5crRxCcvKFAShAMYtRAD9XKak1cwH1FCE6TrpUA9i2      │    │
│  │                                                                  │    │
│  │  Accounts:                                                       │    │
│  │  - OracleData PDA: Global oracle state                           │    │
│  │  - MeterState PDA: Per-meter cumulative data                     │    │
│  │  - ReadingLog PDA: Individual reading records (optional)         │    │
│  │                                                                  │    │
│  │  Instructions:                                                   │    │
│  │  - initialize(): Setup oracle authority                          │    │
│  │  - submitMeterReading(): Submit single reading                   │    │
│  │  - submitBatchReadings(): Submit multiple readings (gas efficient)│   │
│  │  - verifyReading(): Verify reading authenticity                  │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Trading Program                                                 │    │
│  │  - Program ID: 5yakTtiNHXHonCPqkwh1M22jujqugCJhEkYaHAoaB6pG      │    │
│  │  - Consumes oracle data for P2P energy trading                   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Component Responsibilities

| Component | Responsibility | Technology |
|-----------|---------------|------------|
| **IoT Devices** | Data collection, local control | ESP32-S3, Smart Meters |
| **Oracle Bridge** | Protocol translation, event buffering | Rust, Redis Streams |
| **API Gateway** | Business logic, data persistence | Rust/Axum, PostgreSQL |
| **Blockchain** | Immutable records, settlement | Solana/Anchor |

---

## 2. Data Models

### 2.1 IoT Device Reading (Canonical Format)

```rust
// Oracle Bridge: src/models.rs

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceReading {
    pub reading_id: Uuid,              // Unique reading identifier
    pub device_id: String,              // Device identifier (e.g., "ESP32-MTR-001")
    pub device_type: DeviceType,        // Enum: SmartMeter, EvCharger, Battery
    pub serial_number: String,          // Manufacturer serial
    pub zone_id: Option<i32>,           // Geographic zone
    pub timestamp: DateTime<Utc>,       // Reading timestamp
    pub metrics: DeviceMetrics,         // Type-specific metrics
    pub metadata: HashMap<String, Value>, // Extensible metadata
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum DeviceMetrics {
    Energy {
        generated_kwh: f64,
        consumed_kwh: f64,
        net_kwh: f64,
    },
    EvSession {
        energy_delivered_kwh: f64,
        session_id: String,
        connector_id: u32,
        status: EvStatus,
    },
    BatteryState {
        soc_percent: f64,
        power_kw: f64,
        temperature_c: f64,
        mode: BatteryMode,
    },
}
```

### 2.2 gRPC Service Definition

```protobuf
// API Gateway: proto/iot.proto

syntax = "proto3";
package gridtokenx.iot.v1;

service IoTService {
    // Submit single meter reading
    rpc SubmitMeterReading(SubmitMeterReadingRequest) 
        returns (SubmitMeterReadingResponse);
    
    // Submit batch of meter readings (gas efficient)
    rpc SubmitBatchReadings(SubmitBatchReadingsRequest) 
        returns (SubmitBatchReadingsResponse);
    
    // Submit EV charging session
    rpc SubmitEVSession(SubmitEVSessionRequest) 
        returns (SubmitEVSessionResponse);
    
    // Submit battery state
    rpc SubmitBatteryState(SubmitBatteryStateRequest) 
        returns (SubmitBatteryStateResponse);
    
    // Get device metadata
    rpc GetDeviceMetadata(GetDeviceMetadataRequest) 
        returns (GetDeviceMetadataResponse);
}

message SubmitMeterReadingRequest {
    string device_id = 1;
    string serial_number = 2;
    int64 timestamp = 3;  // Unix timestamp (seconds)
    double energy_generated_kwh = 4;
    double energy_consumed_kwh = 5;
    double power_kw = 6;
    map<string, string> metadata = 7;
    string signature = 8;  // Device signature for verification
}

message SubmitMeterReadingResponse {
    string reading_id = 1;
    bool accepted = 2;
    string transaction_hash = 3;  // Solana tx hash (if submitted on-chain)
    int64 block_height = 4;
}

message SubmitBatchReadingsRequest {
    repeated SubmitMeterReadingRequest readings = 1;
    string batch_id = 2;
}

message SubmitBatchReadingsResponse {
    string batch_id = 1;
    int32 accepted_count = 2;
    int32 rejected_count = 3;
    repeated string reading_ids = 4;
    string transaction_hash = 5;
}
```

### 2.3 On-Chain Data Structures (Anchor)

```rust
// Oracle Program: programs/oracle/src/state.rs

#[account]
pub struct OracleData {
    pub authority: Pubkey,           // Oracle operator
    pub total_readings: u64,         // Cumulative readings count
    pub total_energy_kwh: u64,       // Total energy tracked (in Wh)
    pub last_update: i64,            // Last update timestamp
    pub bump: u8,                    // PDA bump
}

#[account]
pub struct MeterState {
    pub meter_id: String,            // Meter identifier (UUID without dashes)
    pub owner: Pubkey,               // Meter owner wallet
    pub cumulative_generated: u64,   // Total generated (in Wh)
    pub cumulative_consumed: u64,    // Total consumed (in Wh)
    pub last_reading_time: i64,      // Last reading timestamp
    pub reading_count: u64,          // Number of readings
    pub dr_event_active: bool,       // DR event participation flag
    pub bump: u8,                    // PDA bump
}

#[account]
pub struct ReadingLog {
    pub meter: Pubkey,               // Meter state account
    pub reading_id: String,          // Unique reading ID
    pub timestamp: i64,              // Reading timestamp
    pub energy_generated: u64,       // Generated energy (Wh)
    pub energy_consumed: u64,        // Consumed energy (Wh)
    pub power_kw: u32,               // Power at reading time (W)
    pub dr_active: bool,             // DR event active flag
    pub submitted_by: Pubkey,        // Oracle authority
    pub bump: u8,                    // PDA bump
}
```

---

## 3. API Specifications

### 3.1 Oracle Bridge HTTP API

#### 3.1.1 Smart Meter Ingestion

**Endpoint:** `POST /api/v1/ingest/smart-meter`

**Headers:**
```
Content-Type: application/json
X-API-KEY: <api-key>
```

**Request:**
```json
{
  "device_id": "ESP32-MTR-001",
  "serial_number": "ESP32-S3-001",
  "timestamp": "2026-03-27T14:00:00Z",
  "energy_generated": 1.5,
  "energy_consumed": 0.0,
  "reading_value": 0.75,
  "metadata": {
    "source": "esp32-s3-edge-meter",
    "firmware_version": "1.0.0",
    "dr_event_active": false,
    "wifi_rssi": -65,
    "device_signature": "ed25519_signature_here"
  }
}
```

**Response (202 Accepted):**
```json
{
  "status": "accepted",
  "reading_id": "550e8400-e29b-41d4-a716-446655440000",
  "device_type": "smart_meter",
  "stream": "gridtokenx:events:v1",
  "blockchain_pending": true
}
```

**Error Responses:**
```json
// 400 Bad Request
{
  "error": "Invalid payload",
  "details": "energy_generated must be non-negative"
}

// 401 Unauthorized
{
  "error": "Invalid API key"
}

// 429 Too Many Requests
{
  "error": "Rate limit exceeded",
  "retry_after": 60
}
```

#### 3.1.2 Rate Limiting

| Device Type | Limit | Window |
|-------------|-------|--------|
| ESP32-S3 Edge Meter | 100 requests | 1 minute |
| Smart Meter | 60 requests | 1 minute |
| EV Charger | 30 requests | 1 minute |
| Battery | 60 requests | 1 minute |

**Headers in Response:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1711548060
```

### 3.2 API Gateway gRPC API

#### 3.2.1 Submit Meter Reading

**Service:** `gridtokenx.iot.v1.IoTService`

**Request:**
```protobuf
SubmitMeterReadingRequest {
    device_id: "ESP32-MTR-001"
    serial_number: "ESP32-S3-001"
    timestamp: 1711548000
    energy_generated_kwh: 1.5
    energy_consumed_kwh: 0.0
    power_kw: 0.75
    metadata: {
        "dr_event_active": "false"
        "wifi_rssi": "-65"
    }
    signature: "ed25519_signature"
}
```

**Response:**
```protobuf
SubmitMeterReadingResponse {
    reading_id: "550e8400-e29b-41d4-a716-446655440000"
    accepted: true
    transaction_hash: "5KtP...xYz9"  // Solana tx
    block_height: 250000000
}
```

#### 3.2.2 Batch Submission

**Request:**
```protobuf
SubmitBatchReadingsRequest {
    readings: [
        SubmitMeterReadingRequest { ... },
        SubmitMeterReadingRequest { ... },
        SubmitMeterReadingRequest { ... }
    ]
    batch_id: "batch-2026-03-27-14:00"
}
```

**Response:**
```protobuf
SubmitBatchReadingsResponse {
    batch_id: "batch-2026-03-27-14:00"
    accepted_count: 3
    rejected_count: 0
    reading_ids: ["uuid1", "uuid2", "uuid3"]
    transaction_hash: "5KtP...xYz9"
}
```

**Gas Savings:** Batch submission reduces transaction fees by ~70% compared to individual submissions.

### 3.3 Blockchain Program Instructions

#### 3.3.1 Submit Single Reading

**Instruction:** `submitMeterReading`

**Accounts:**
```
0. [writable] OracleData PDA
1. [writable] MeterState PDA (derived from meter_id)
2. [writable] ReadingLog PDA (optional, for audit)
3. [signer] OracleAuthority (signer)
4. [] SystemProgram
```

**Data:**
```rust
pub struct SubmitMeterReadingIx {
    pub reading_id: String,
    pub meter_id: String,
    pub timestamp: i64,
    pub energy_generated: u64,  // in Wh
    pub energy_consumed: u64,
    pub power_kw: u32,
    pub dr_active: bool,
}
```

**Compute Units:** ~15,000 CU  
**Transaction Fee:** ~0.000005 SOL

#### 3.3.2 Submit Batch Readings

**Instruction:** `submitBatchReadings`

**Accounts:**
```
0. [writable] OracleData PDA
1. [writable] MeterState PDA (for each unique meter)
2. [signer] OracleAuthority (signer)
3. [] SystemProgram
```

**Data:**
```rust
pub struct SubmitBatchReadingsIx {
    pub readings: Vec<MeterReadingInput>,
}

pub struct MeterReadingInput {
    pub reading_id: String,
    pub meter_id: String,
    pub timestamp: i64,
    pub energy_generated: u64,
    pub energy_consumed: u64,
    pub power_kw: u32,
}
```

**Compute Units:** ~50,000 CU (for 10 readings)  
**Transaction Fee:** ~0.000015 SOL  
**Savings:** ~65% vs individual submissions

---

## 4. Security Architecture

### 4.1 Authentication Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Device Authentication                              │
│ - X-API-KEY header validation                               │
│ - Static keys (engineering/emergency)                       │
│ - IAM gRPC service (production)                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Device Signature Verification                      │
│ - Ed25519 signature in metadata                             │
│ - Device private key signs reading payload                  │
│ - API Gateway verifies against registered public key        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Oracle Authority Signature                         │
│ - Solana keypair signs blockchain transactions              │
│ - PDA derivation ensures oracle program authority           │
│ - On-chain verification of oracle identity                  │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Device Registration Flow

```
1. Device Manufacturer
   ↓ Generates Ed25519 keypair
   ↓ Stores private key in device secure element
   ↓ Registers public key with GridTokenX

2. GridTokenX Registration
   ↓ POST /api/v1/devices/register
   ↓ Payload: { device_id, serial_number, public_key, owner_wallet }
   ↓ Store in PostgreSQL: devices table

3. API Key Provisioning
   ↓ Generate unique API key for device
   ↓ Store in IAM service
   ↓ Provision to device (QR code, manual entry)

4. Device Activation
   ↓ Device sends first reading with signature
   ↓ API Gateway verifies signature
   ↓ Activate device status
```

### 4.3 Data Integrity

**Device → Oracle Bridge:**
- HTTPS/TLS 1.3 (production)
- X-API-KEY authentication
- Payload signature verification

**Oracle Bridge → API Gateway:**
- gRPC with TLS
- Internal network isolation
- Mutual TLS (mTLS) for service-to-service

**API Gateway → Blockchain:**
- Oracle Authority keypair signs transactions
- PDA-based access control
- On-chain signature verification

---

## 5. Reliability Patterns

### 5.1 Event Delivery Guarantees

**At-Least-Once Delivery:**
```
IoT Device → Oracle Bridge → Redis Streams → API Gateway → Blockchain
     ↓            ↓              ↓              ↓            ↓
  Retry      Persist        Persist        Retry       Commit
  (3x)       (in-memory)    (durable)      (5x)       (on-chain)
```

**Idempotency:**
- Each reading has unique `reading_id` (UUID)
- API Gateway deduplicates by `reading_id`
- On-chain: ReadingLog PDA prevents duplicates

### 5.2 Backpressure Handling

**Redis Streams Configuration:**
```bash
# Max entries per stream
XADD gridtokenx:events:v1 MAXLEN ~100000 * ...

# Consumer group for load balancing
XGROUP CREATE gridtokenx:events:v1 api-gateway-group $ MKSTREAM

# Acknowledge processing
XACK gridtokenx:events:v1 api-gateway-group <entry-id>
```

**Backpressure Flow:**
```
High Load → Redis Stream fills → Oracle Bridge slows ingestion
          → API Gateway batches more aggressively
          → Blockchain queue builds
          → Alert triggered (Prometheus)
```

### 5.3 Retry Logic

**Oracle Bridge → API Gateway:**
```rust
// Exponential backoff
let retries = [1, 2, 4, 8, 16, 32];  // seconds
for delay in retries {
    match submit_to_gateway(reading).await {
        Ok(_) => break,
        Err(e) if delay == retries.last() => {
            // Move to dead letter queue
            send_to_dlq(reading, e).await;
        }
        Err(_) => tokio::time::sleep(delay).await,
    }
}
```

**API Gateway → Blockchain:**
```rust
// Transaction retry with priority fee bump
let mut priority_fee = 1000;  // microlamports
for attempt in 0..5 {
    match submit_transaction(tx).await {
        Ok(sig) => return Ok(sig),
        Err(SolanaError::BlockhashNotFound) => {
            priority_fee *= 2;  // Double priority fee
            tx.set_priority_fee(priority_fee);
        }
        Err(e) => return Err(e),
    }
}
```

---

## 6. Observability

### 6.1 Metrics (Prometheus)

**Oracle Bridge Metrics:**
```rust
// Total ingestion requests
gridtokenx_oracle_bridge_requests_total{device_type="smart_meter"}

// Request latency histogram
gridtokenx_oracle_bridge_request_latency_seconds{quantile="0.95"}

// Redis stream depth
gridtokenx_redis_stream_length{stream="gridtokenx:events:v1"}

// API Gateway gRPC latency
gridtokenx_gateway_grpc_latency_seconds{method="SubmitMeterReading"}
```

**API Gateway Metrics:**
```rust
// gRPC requests
gridtokenx_gateway_grpc_requests_total{method="SubmitMeterReading", status="ok"}

// Blockchain submission
gridtokenx_blockchain_submissions_total{status="success"}
gridtokenx_blockchain_submission_latency_seconds

// PostgreSQL queries
gridtokenx_db_query_duration_seconds{query="insert_meter_reading"}

// Kafka events
gridtokenx_kafka_events_published_total{topic="meter.readings.created"}
```

### 6.2 Distributed Tracing (OpenTelemetry)

**Trace Flow:**
```
ESP32-S3 (span: device_reading)
    ↓ traceparent header
Oracle Bridge (span: ingest_reading → publish_redis)
    ↓ traceparent header
API Gateway (span: handle_grpc → validate → persist_db → submit_blockchain)
    ↓ traceparent header
Solana RPC (span: send_transaction)
```

**Span Attributes:**
```json
{
  "trace_id": "5bd74975e7d58247a8d8a9c7f1f8e3d2",
  "span_id": "8a3f7c2e1b9d4f6a",
  "operation_name": "submit_meter_reading",
  "tags": {
    "device_id": "ESP32-MTR-001",
    "reading_id": "550e8400-e29b-41d4-a716-446655440000",
    "energy_kwh": "1.5",
    "blockchain_tx": "5KtP...xYz9",
    "duration_ms": "245"
  }
}
```

### 6.3 Alerting Rules (Prometheus)

```yaml
groups:
  - name: iot-alerts
    rules:
      # Oracle Bridge down
      - alert: OracleBridgeDown
        expr: up{job="oracle-bridge"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Oracle Bridge is down"
          
      # High Redis stream depth
      - alert: RedisStreamBacklog
        expr: gridtokenx_redis_stream_length > 10000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Redis stream {{ $labels.stream }} has {{ $value }} entries"
          
      # Blockchain submission failures
      - alert: BlockchainSubmissionFailures
        expr: rate(gridtokenx_blockchain_submissions_total{status="error"}[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High blockchain submission failure rate"
          
      # High API Gateway latency
      - alert: GatewayLatencyHigh
        expr: histogram_quantile(0.99, rate(gridtokenx_gateway_grpc_request_latency_seconds_bucket[5m])) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "API Gateway p99 latency is {{ $value }}s"
```

---

## 7. Performance Benchmarks

### 7.1 Target Performance

| Metric | Target | P95 | P99 |
|--------|--------|-----|-----|
| Oracle Bridge Ingestion | < 50ms | 45ms | 80ms |
| Redis Publish | < 10ms | 8ms | 15ms |
| API Gateway gRPC | < 100ms | 85ms | 150ms |
| Blockchain Submission | < 5s | 3s | 8s |
| End-to-End Latency | < 10s | 7s | 15s |

### 7.2 Throughput Capacity

| Component | Max Throughput | Current Load | Headroom |
|-----------|---------------|--------------|----------|
| Oracle Bridge | 1000 req/s | 100 req/s | 10x |
| Redis Streams | 10,000 msg/s | 500 msg/s | 20x |
| API Gateway | 500 req/s | 50 req/s | 10x |
| Solana Blockchain | 2000 TPS | 10 TPS | 200x |

### 7.3 Scaling Strategy

**Horizontal Scaling:**
```yaml
# Kubernetes HPA configuration
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: oracle-bridge-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: oracle-bridge
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: redis_stream_depth
      target:
        type: AverageValue
        averageValue: 5000
```

---

## 8. Deployment Architecture

### 8.1 Development (Local)

```
┌────────────────────────────────────────────┐
│           Developer Machine                 │
│  ┌──────────────────────────────────────┐  │
│  │  Docker Compose                       │  │
│  │  - Redis (single instance)            │  │
│  │  - Oracle Bridge (1 replica)          │  │
│  │  - API Gateway (1 replica)            │  │
│  │  - PostgreSQL (single)                │  │
│  │  - Solana Test Validator              │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ESP32-S3 → localhost:4010                 │
└────────────────────────────────────────────┘
```

### 8.2 Staging

```
┌─────────────────────────────────────────────────────────┐
│                  Staging Cluster (K8s)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ Oracle      │  │ Oracle      │  │ Oracle      │     │
│  │ Bridge x2   │  │ Bridge x2   │  │ Bridge x2   │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         └────────────────┴────────────────┘              │
│                        │                                 │
│              ┌─────────▼─────────┐                       │
│              │  Redis Cluster    │                       │
│              │  (3 nodes)        │                       │
│              └─────────┬─────────┘                       │
│                        │                                 │
│         ┌──────────────┼──────────────┐                 │
│         │              │              │                 │
│  ┌──────▼──────┐ ┌─────▼──────┐ ┌────▼──────┐         │
│  │ API Gateway │ │ API Gateway│ │  PostgreSQL│         │
│  │ x2          │ │ x2         │ │  (HA)      │         │
│  └──────┬──────┘ └─────┬──────┘ └───────────┘         │
│         └──────────────┴────────────────┘              │
│                        │                               │
│              ┌─────────▼─────────┐                     │
│              │ Solana Devnet RPC │                     │
│              └───────────────────┘                     │
└─────────────────────────────────────────────────────────┘
```

### 8.3 Production

```
┌──────────────────────────────────────────────────────────────┐
│                 Production (Multi-Region)                     │
│                                                               │
│  ┌─────────────────────┐         ┌─────────────────────┐    │
│  │   Region: US-West   │         │   Region: US-East   │    │
│  │                     │         │                     │    │
│  │  ┌───────────────┐  │         │  ┌───────────────┐  │    │
│  │  │ Oracle Bridge │  │         │  │ Oracle Bridge │  │    │
│  │  │ x5 (Auto-scale)│ │         │  │ x5 (Auto-scale)│ │    │
│  │  └───────┬───────┘  │         │  └───────┬───────┘  │    │
│  │          │          │         │          │          │    │
│  │  ┌───────▼───────┐  │         │  ┌───────▼───────┐  │    │
│  │  │ Redis Cluster │  │◄───────►│  │ Redis Cluster │  │    │
│  │  │ (6 nodes)     │  │  Sync   │  │ (6 nodes)     │  │    │
│  │  └───────┬───────┘  │         │  └───────┬───────┘  │    │
│  │          │          │         │          │          │    │
│  │  ┌───────▼───────┐  │         │  ┌───────▼───────┐  │    │
│  │  │ API Gateway   │  │         │  │ API Gateway   │  │    │
│  │  │ x10 (Auto-scale)│        │  │ x10 (Auto-scale)│  │    │
│  │  └───────┬───────┘  │         │  └───────┬───────┘  │    │
│  │          │          │         │          │          │    │
│  │  ┌───────▼───────┐  │         │  ┌───────▼───────┐  │    │
│  │  │ PostgreSQL    │  │         │  │ PostgreSQL    │  │    │
│  │  │ (CockroachDB) │  │         │  │ (CockroachDB) │  │    │
│  │  └───────────────┘  │         │  └───────────────┘  │    │
│  └─────────────────────┘         └─────────────────────┘    │
│           │                              │                   │
│           └──────────────┬───────────────┘                   │
│                          │                                   │
│              ┌───────────▼───────────┐                       │
│              │  Solana Mainnet RPC   │                       │
│              │  (Helius/QuickNode)   │                       │
│              └───────────────────────┘                       │
└──────────────────────────────────────────────────────────────┘
```

---

## 9. Cost Analysis

### 9.1 Blockchain Transaction Costs

**Per Device Per Day (assuming 1 reading/minute):**
```
Readings per day: 1440
Individual submissions: 1440 tx/day
  - Cost: 1440 × 0.000005 SOL = 0.0072 SOL/day
  - USD: 0.0072 × $100 = $0.72/day per device

Batch submissions (10 readings/batch): 144 tx/day
  - Cost: 144 × 0.000015 SOL = 0.00216 SOL/day
  - USD: 0.00216 × $100 = $0.22/day per device

Savings: 70% ($0.50/day per device)
```

**At Scale (10,000 devices):**
```
Individual: $7,200/day
Batch: $2,200/day
Monthly Savings: $150,000
```

### 9.2 Infrastructure Costs (Monthly)

| Component | Staging | Production |
|-----------|---------|------------|
| Compute (K8s) | $500 | $5,000 |
| Redis Cluster | $200 | $2,000 |
| PostgreSQL | $300 | $3,000 |
| Solana RPC | $100 | $1,000 |
| Blockchain Fees | $50 | $50,000 |
| **Total** | **$1,150** | **$61,000** |

---

## 10. Implementation Roadmap

### Phase 1: Core Infrastructure (Weeks 1-4)
- [ ] Oracle Bridge HTTP API
- [ ] Redis Streams integration
- [ ] API Gateway gRPC service
- [ ] PostgreSQL schema
- [ ] Basic device authentication

### Phase 2: Blockchain Integration (Weeks 5-8)
- [ ] Oracle Program deployment
- [ ] PDA derivation logic
- [ ] Transaction submission
- [ ] Batch reading optimization
- [ ] On-chain verification

### Phase 3: Security Hardening (Weeks 9-10)
- [ ] Device signature verification
- [ ] IAM service integration
- [ ] Rate limiting
- [ ] TLS/mTLS configuration
- [ ] Security audit

### Phase 4: Observability (Weeks 11-12)
- [ ] Prometheus metrics
- [ ] Grafana dashboards
- [ ] Distributed tracing
- [ ] Alerting rules
- [ ] Log aggregation

### Phase 5: Performance & Scale (Weeks 13-16)
- [ ] Load testing
- [ ] Performance optimization
- [ ] Auto-scaling configuration
- [ ] Multi-region deployment
- [ ] Disaster recovery

---

## 11. Risk Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Blockchain congestion | High | Medium | Batch submissions, priority fees |
| Redis cluster failure | High | Low | Multi-region replication, failover |
| API Gateway overload | Medium | Medium | Auto-scaling, rate limiting |
| Device spoofing | High | Low | Signature verification, device registration |
| Data loss | Critical | Low | At-least-once delivery, idempotency |
| Oracle program bug | Critical | Low | Formal verification, audit, upgrade authority |

---

## 12. Appendix

### A. Device Firmware Example

```cpp
// ESP32-S3: Send meter reading to Oracle Bridge
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <mbedtls/ed25519.h>

const char* ORACLE_BRIDGE_URL = "http://api.gridtokenx.io:4010";
const char* API_KEY = "device-api-key-xxx";
const uint8_t DEVICE_PRIVATE_KEY[32] = { /* device private key */ };

void sendMeterReading() {
    float energyWh = readEnergyMeter();
    float powerW = readPowerMeter();
    
    // Create reading payload
    StaticJsonDocument<512> doc;
    doc["device_id"] = "ESP32-MTR-001";
    doc["energy_generated"] = energyWh / 1000.0;
    doc["reading_value"] = powerW / 1000.0;
    doc["timestamp"] = getUnixTimestamp();
    
    // Sign payload
    String payload;
    serializeJson(doc, payload);
    
    uint8_t signature[64];
    mbedtls_ed25519_sign(signature, payload.c_str(), payload.length(), 
                         DEVICE_PRIVATE_KEY);
    
    // Add signature to metadata
    doc["signature"] = bytesToHex(signature, 64);
    
    // Send to Oracle Bridge
    HTTPClient http;
    http.begin(String(ORACLE_BRIDGE_URL) + "/api/v1/ingest/smart-meter");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-API-KEY", API_KEY);
    
    String json;
    serializeJson(doc, json);
    
    int httpCode = http.POST(json);
    
    if (httpCode == HTTP_CODE_ACCEPTED) {
        Serial.println("✅ Reading submitted");
    } else {
        Serial.println("❌ Submission failed");
    }
    
    http.end();
}
```

### B. PostgreSQL Schema

```sql
-- Devices table
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(64) UNIQUE NOT NULL,
    device_type VARCHAR(32) NOT NULL,
    serial_number VARCHAR(128),
    owner_wallet VARCHAR(64),
    public_key BYTEA,  -- Ed25519 public key
    api_key_hash VARCHAR(256),
    status VARCHAR(32) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Meter readings table
CREATE TABLE meter_readings (
    reading_id UUID PRIMARY KEY,
    device_id VARCHAR(64) REFERENCES devices(device_id),
    timestamp TIMESTAMPTZ NOT NULL,
    energy_generated_kwh DECIMAL(12,6),
    energy_consumed_kwh DECIMAL(12,6),
    power_kw DECIMAL(10,6),
    dr_event_active BOOLEAN DEFAULT FALSE,
    blockchain_tx_hash VARCHAR(128),
    blockchain_block_height BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_readings_device ON meter_readings(device_id, timestamp DESC);
CREATE INDEX idx_readings_blockchain ON meter_readings(blockchain_tx_hash) 
    WHERE blockchain_tx_hash IS NOT NULL;

-- DR events table
CREATE TABLE dr_events (
    event_id UUID PRIMARY KEY,
    event_name VARCHAR(256),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    price_per_kwh DECIMAL(10,6),
    status VARCHAR(32) DEFAULT 'scheduled'
);
```

### C. Environment Variables

```bash
# Oracle Bridge
REDIS_URL=redis://redis:6379
API_GATEWAY_URL=http://api-gateway:4001
IOT_GATEWAY_PORT=4010
GRIDTOKENX_API_KEYS=key1,key2,key3
IAM_SERVICE_URL=http://iam-service:8080
RUST_LOG=info

# API Gateway
DATABASE_URL=postgresql://user:pass@postgres:5432/gridtokenx
REDIS_URL=redis://redis:6379
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
ORACLE_PROGRAM_ID=Ad5crRxCcvKFAShAMYtRAD9XKak1cwH1FCE6TrpUA9i2
ORACLE_AUTHORITY_WALLET=/secrets/oracle-authority.json
GRPC_PORT=4001
ENABLE_METRICS=true
ENABLE_TRACING=true

# Blockchain
PAYER_PRIVATE_KEY=<base64-encoded-key>
COMPUTE_UNIT_PRICE=1000  # microlamports
BATCH_SIZE=10
```

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-27  
**Author:** GridTokenX Engineering  
**Status:** Draft for Review
