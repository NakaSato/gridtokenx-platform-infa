# Data Collection and Preprocessing Methodology
## GridTokenX Platform

---

## 1. Overview
The **GridTokenX** platform employs a high-fidelity simulation and ingestion pipeline to model realistic energy markets. This document details the end-to-end data flow, from physics-based generation to asynchronous processing and storage.

**Key Characteristics:**
*   **Physics-First Approach**: Grid telemetry is derived from solving actual power flow equations, not synthetic random data.
*   **Event-Driven Architecture**: Kafka-based streaming decouples generation from processing.
*   **Horizontal Scalability**: Worker pools handle variable load with auto-retry mechanisms.
*   **Multi-Tier Storage**: Hot (Redis), Warm (PostgreSQL), Cold (InfluxDB) for optimized query patterns.

---

## 2. Data Generation (Simulation Layer)
**Component**: `gridtokenx-smartmeter-simulator`  
**Framework**: Python / FastAPI / Pandapower

The platform does not rely on random noise. Instead, it uses **Physics-based Simulation** to generate credible telemetry data that mirrors real-world grid behavior.

### 2.1 Physics Engine
The core engine (`PhysicsSimulationEngine`) leverages the **Pandapower** library to solve power flow equations. This ensures:
*   **Kirchhoff's Laws**: Voltage and current follow physical grid constraints.
*   **Technical Losses**: Line losses and transformer inefficiencies are calculated dynamically.
*   **Power Quality**: Simulates Total Harmonic Distortion (THD) and power factor deviations.
*   **Grid Constraints**: Respects voltage limits (0.95-1.05 p.u.) and thermal line ratings.

### 2.2 Consumer Profiles & Templates
Data generation is driven by **Meter Templates** (`generators.py`) representing diverse grid participants:
*   **Residential**: Variable load profiles (Small/Medium/Large) with optional rooftop solar (3-10 kW).
*   **Commercial**: Optimized for daylight hours (Office/Retail) with battery storage systems (50-100 kWh).
*   **Industrial**: High-load profiles with shift-based operations (Light/Heavy/24h) supporting 24/7 manufacturing.

**Template Configuration:**
```python
MeterTemplateConfig:
    - base_consumption_kwh: Hourly baseline (0.5 - 25.0 kWh)
    - solar_capacity_kw: Rooftop PV rating (3.0 - 50.0 kW)
    - battery_capacity_kwh: Energy storage (5.0 - 100.0 kWh)
    - peak_multiplier: Load spike factor (1.4 - 2.0x)
    - weekend_factor: Occupancy adjustment (0.2 - 1.5x)
```

### 2.3 Environmental Factors
*   **Seasonality**: Adjusts for Thailand's climate (Hot, Rainy, Cool), directly impacting solar PV efficiency and air conditioning loads.
*   **Cloud Cover**: Simulates solar intermittency with variable irradiance factors (0.3 - 1.0).
*   **Temperature**: Impacts battery efficiency and cooling loads.

### 2.4 Meter State Management
Each `SmartMeter` instance maintains persistent state using **Exponential Moving Averages (EMA)** for smooth transitions:
*   **Electrical Parameters**: Voltage (240V ± 10%), Frequency (50Hz ± 0.5Hz), Power Factor (0.85-0.99).
*   **Energy Accumulators**: Lifetime consumption/generation totals (initialized with realistic baselines).
*   **Battery State**: Charge level with realistic charge/discharge curves.

---

## 3. Data Collection (Ingestion Layer)
**Component**: `gridtokenx-apigateway`  
**Protocol**: Apache Kafka (Streaming)

### 3.1 Streaming Architecture
The simulator streams telemetry readings to **Kafka** topics (`meter-readings`) to decouple generation from processing. This architectural pattern provides:
*   **Decoupling**: Simulator and API Gateway operate independently with separate failure domains.
*   **Buffering**: Kafka acts as a distributed commit log, persisting messages for replay.
*   **Scalability**: Horizontal partitioning allows multiple consumers to process in parallel.

### 3.2 Kafka Consumer Service (`consumer.rs`)
A high-performance Rust consumer handles the ingress of massive telemetry streams with sub-millisecond latency.

**Features:**
*   **Deserialization**: Validates incoming JSON payloads against the `KafkaMeterReading` schema.
*   **Buffering**: Instead of processing synchronously, validated readings are pushed to a **Redis List** (`queue:meter_readings`). This acts as a shock absorber during traffic spikes.
*   **Error Handling**: Malformed messages are logged and moved to a dead-letter queue.

### 3.3 Data Schema

**Kafka Message Schema (`KafkaMeterReading`):**
```rust
{
  "meter_serial": String,           // Unique identifier (e.g., "MEA-RES-001")
  "meter_id": String (optional),    // Alternative identifier
  "kwh": f64,                        // Total accumulated energy (kWh)
  "timestamp": ISO8601 String,       // Reading timestamp
  
  // Energy Metrics
  "energy_generated": f64 (optional),  // Instantaneous generation (kWh)
  "energy_consumed": f64 (optional),   // Instantaneous consumption (kWh)
  "power_generated": f64 (optional),   // Real-time generation (kW)
  "power_consumed": f64 (optional),    // Real-time consumption (kW)
  
  // Electrical Quality
  "voltage": f64 (optional),           // Grid voltage (V)
  "current": f64 (optional),           // Current draw (A)
  "frequency": f64 (optional),         // Grid frequency (Hz)
  "power_factor": f64 (optional),      // Power factor (0-1)
  "thd_voltage": f64 (optional),       // Voltage THD (%)
  "thd_current": f64 (optional),       // Current THD (%)
  
  // Geospatial & Zone
  "latitude": f64 (optional),          // GPS latitude
  "longitude": f64 (optional),         // GPS longitude
  "zone_id": i32 (optional),           // Microgrid zone ID
  
  // Battery State
  "battery_level": f64 (optional)      // State of charge (0-100%)
}
```

**Sample Payload:**
```json
{
  "meter_serial": "MEA-RES-001",
  "kwh": 1254.32,
  "energy_generated": 3.2,
  "energy_consumed": 1.8,
  "voltage": 220.5,
  "current": 5.4,
  "frequency": 50.01,
  "power_factor": 0.95,
  "latitude": 13.7563,
  "longitude": 100.5018,
  "zone_id": 3,
  "timestamp": "2026-01-27T12:00:00Z"
}
```

---

## 4. Preprocessing & Processing Strategy
**Component**: `gridtokenx-apigateway`  
**Mechanism**: Asynchronous Workers (Redis Queue)

### 4.1 Reading Processor Service (`reading_processor.rs`)
A dedicated pool of background workers (Rust/Tokio) continually polls Redis for new tasks. This architecture ensures the API remains responsive even under heavy load.

**Worker Pool Configuration:**
*   **Concurrency**: 4-8 workers (configurable via `READING_PROCESSOR_WORKERS`).
*   **Queue Strategy**: BRPOP (Blocking Right Pop) with 1-second timeout to minimize CPU spinning.
*   **Resource Isolation**: Each worker runs in a separate Tokio task with independent database connections.

### 4.2 Processing Pipeline
Each reading undergoes a multi-stage validation and enrichment process:

**Stage 1: De-queue**
*   Worker pops a `ReadingTask` from Redis (`queue:meter_readings`).
*   Task includes: `serial`, `params`, `request`, `retry_count`.

**Stage 2: Validation**
*   **Serial Number Lookup**: Verifies meter exists in PostgreSQL.
*   **Ownership Check**: Confirms meter belongs to the requesting user.
*   **Data Anomaly Detection**:
    *   Voltage range: 200V - 260V (±10% of 230V nominal).
    *   Frequency range: 49.5Hz - 50.5Hz.
    *   Power factor: 0.7 - 1.0 (lagging/unity).
    *   Negative generation/consumption flagged.

**Stage 3: Enrichment**
*   **Surplus/Deficit Calculation**: `surplus = generation - consumption`.
*   **CO₂ Savings Estimation**: Based on grid emission factors (0.5 kgCO₂/kWh).
*   **Zone Assignment**: Attaches microgrid zone ID for topology awareness.

**Stage 4: Persistence**
*   **Hot Storage (Redis)**:
    *   Key: `meter:{serial}:latest`
    *   TTL: 60 seconds (real-time cache).
    *   Stores: Full reading JSON for instant API responses.
*   **Warm Storage (PostgreSQL)**:
    *   Table: `meter_readings`
    *   Indexed on: `(meter_id, timestamp DESC)`.
    *   Used for: Historical queries, analytics, billing.
*   **Cold Storage (InfluxDB)**:
    *   Measurement: `energy_metrics`
    *   Tags: `meter_serial`, `zone_id`, `meter_type`.
    *   Fields: `voltage`, `current`, `power_factor`, `generation`, `consumption`.
    *   Retention: 90 days (downsampled to hourly after 7 days).

**Stage 5: Metric Tracking**
*   **Prometheus Metrics**:
    *   `meter_reading_total{status="success|failure"}`: Counter.
    *   `meter_processing_duration_seconds`: Histogram.
    *   `meter_processing_queue_depth`: Gauge.
    *   `meter_reading_retries_total`: Counter.

### 4.3 Reliability & Fault Tolerance
The system implements multiple layers of reliability guarantees:

**Retry Mechanism:**
*   **Exponential Backoff**: `delay = 2^retry_count` seconds (2s, 4s, 8s).
*   **Max Retries**: 3 attempts before escalation.
*   **Idempotency**: Upsert operations prevent duplicate entries.

**Dead Letter Queue (DLQ):**
*   **Trigger**: Readings exceeding max retries.
*   **Storage**: Redis list (`queue:dlq`).
*   **Monitoring**: Alerts triggered if DLQ depth > 10.
*   **Recovery**: Manual inspection + replay via admin dashboard.

**Queue Monitoring:**
*   **Depth Threshold**: Warning logged if `queue:meter_readings` > 1000 items.
*   **Backpressure**: Kafka consumer pauses if Redis queue > 10,000 (prevents OOM).
*   **Health Checks**: `/health` endpoint exposes queue depth and worker status.

**Circuit Breaker (Database):**
*   **Condition**: If PostgreSQL fails 3 consecutive queries.
*   **Action**: Workers pause for 10 seconds, then retry connection.
*   **Fallback**: Readings cached in Redis until DB recovers.

---

## 5. Data Quality Assurance

### 5.1 Validation Rules
| Field | Rule | Action on Violation |
|-------|------|---------------------|
| `voltage` | 200 - 260V | Log warning, store as-is |
| `frequency` | 49.5 - 50.5 Hz | Log warning, store as-is |
| `power_factor` | 0.7 - 1.0 | Reject if < 0.5 or > 1.0 |
| `energy_*` | ≥ 0 | Reject negative values |
| `timestamp` | Within ±5 min of now | Reject stale/future readings |
| `meter_serial` | Exists in DB | Reject unknown meters |

### 5.2 Data Integrity
*   **Checksums**: Not currently implemented (roadmap item).
*   **Digital Signatures**: Meter readings signed with Ed25519 keys (simulator-side).
*   **Tamper Detection**: Blockchain anchoring planned for audit trails.

---

## 6. Performance Characteristics

### 6.1 Throughput
*   **Ingestion Rate**: 10,000 readings/second (Kafka consumer).
*   **Processing Rate**: 2,500 readings/second (4-worker pool).
*   **Latency (p99)**: < 50ms (Redis pop → DB write).

### 6.2 Storage Efficiency
*   **PostgreSQL**: ~200 bytes/reading (compressed).
*   **InfluxDB**: ~80 bytes/point (columnar storage).
*   **Redis**: ~500 bytes/reading (includes metadata).

---

## 7. Summary Flow

```
┌─────────────┐
│  Simulator  │ Solves grid physics equations
└──────┬──────┘
       │ Emits JSON
       ▼
┌─────────────┐
│    Kafka    │ Topic: meter-readings
│   Broker    │ Partitions: 8, Replication: 3
└──────┬──────┘
       │ Consumes (rdkafka)
       ▼
┌─────────────┐
│ API Gateway │ Rust Consumer (consumer.rs)
│  (Consumer) │ Validates schema
└──────┬──────┘
       │ RPUSH
       ▼
┌─────────────┐
│    Redis    │ List: queue:meter_readings
│    Queue    │ Depth monitoring
└──────┬──────┘
       │ BRPOP (1s timeout)
       ▼
┌─────────────┐
│Worker Pool  │ 4 Tokio tasks (reading_processor.rs)
│ (Processor) │ Validation → Enrichment → Persistence
└──────┬──────┘
       │
       ├─────────────────────┐
       │                     │
       ▼                     ▼
┌─────────────┐      ┌─────────────┐
│    Redis    │      │ PostgreSQL  │
│  (Hot: 60s) │      │ (Warm: ∞)   │
└─────────────┘      └─────────────┘
       │
       ▼
┌─────────────┐
│  InfluxDB   │
│ (Cold: 90d) │
└─────────────┘
```

---

## 8. Future Enhancements

1.  **ML-Based Anomaly Detection**: Train models on historical data to detect grid faults.
2.  **Real-Time Aggregation**: Implement Kafka Streams for zone-level rollups.
3.  **Blockchain Anchoring**: Merkle root of daily readings written to Solana for tamper-proof audit trails.
4.  **Adaptive Backpressure**: Dynamic queue limits based on system load.
5.  **Multi-Region Replication**: Geo-distributed Kafka clusters for disaster recovery.
