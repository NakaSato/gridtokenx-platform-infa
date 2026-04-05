# IoT Access Sequence Diagrams

## Overview

This document provides detailed sequence diagrams for all major IoT access flows through the GridTokenX platform.

---

## 1. Device Registration Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Device    │      │   Oracle    │      │     API     │      │   IAM       │      │   PostgreSQL│
│  (ESP32-S3) │      │   Bridge    │      │   Gateway   │      │  Service    │      │             │
└──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
       │                    │                    │                    │                    │
       │ 1. Generate Ed25519 Keypair             │                    │                    │
       │─────────────────> │                    │                    │                    │
       │                    │                    │                    │                    │
       │ 2. POST /devices/register               │                    │                    │
       │    {device_id, serial, pubkey, owner}   │                    │                    │
       │─────────────────────────────────────────>│                    │                    │
       │                    │                    │                    │                    │
       │                    │                    │ 3. Create API Key  │                    │
       │                    │                    │───────────────────>│                    │
       │                    │                    │                    │                    │
       │                    │                    │                    │ 4. Store Device    │
       │                    │                    │                    │───────────────────>│
       │                    │                    │                    │                    │
       │                    │                    │ 5. API Key Created │                    │
       │                    │                    │<───────────────────│                    │
       │                    │                    │                    │                    │
       │                    │                    │ 6. Return Device + API Key             │
       │                    │ 7. Registration OK │<───────────────────│                    │
       │<─────────────────────────────────────────│                    │                    │
       │                    │                    │                    │                    │
       │ 8. Store API Key (secure element)       │                    │                    │
       │─────────────────> │                    │                    │                    │
       │                    │                    │                    │                    │
```

**Implementation:**
```bash
# Device Registration API Call
curl -X POST http://localhost:4001/api/v1/devices/register \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "ESP32-MTR-001",
    "serial_number": "ESP32-S3-001",
    "public_key": "ed25519_pubkey_hex",
    "owner_wallet": "SolanaWalletAddress",
    "device_type": "smart_meter"
  }'

# Response
{
  "device_id": "ESP32-MTR-001",
  "api_key": "device-api-key-xxx",
  "status": "active"
}
```

---

## 2. Meter Reading Submission Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Device    │      │   Oracle    │      │    Redis    │      │     API     │      │  PostgreSQL │      │   Solana    │
│  (ESP32-S3) │      │   Bridge    │      │   Streams   │      │   Gateway   │      │             │      │  Blockchain │
└──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
       │                    │                    │                    │                    │                    │
       │ 1. Collect Meter Data                   │                    │                    │                    │
       │─────────────────> │                    │                    │                    │                    │
       │                    │                    │                    │                    │                    │
       │ 2. Sign Payload with Device Key         │                    │                    │                    │
       │─────────────────> │                    │                    │                    │                    │
       │                    │                    │                    │                    │                    │
       │ 3. POST /api/v1/ingest/smart-meter      │                    │                    │                    │
       │    {reading + signature}                │                    │                    │                    │
       │───────────────────>│                    │                    │                    │                    │
       │                    │                    │                    │                    │                    │
       │                    │ 4. Verify API Key  │                    │                    │                    │
       │                    │───────────────────>│                    │                    │                    │
       │                    │                    │                    │                    │                    │
       │                    │ 5. XREAD Streams   │                    │                    │                    │
       │                    │───────────────────>│                    │                    │                    │
       │                    │                    │                    │                    │                    │
       │                    │ 6. XADD Reading    │                    │                    │                    │
       │                    │───────────────────>│                    │                    │                    │
       │                    │                    │                    │                    │                    │
       │                    │ 7. Accept (202)    │                    │                    │                    │
       │<───────────────────│                    │                    │                    │                    │
       │                    │                    │                    │                    │                    │
       │                    │                    │ 8. XREAD (Consumer)│                    │                    │
       │                    │                    │<───────────────────│                    │                    │
       │                    │                    │                    │                    │                    │
       │                    │                    │ 9. gRPC: SubmitMeterReading            │                    │
       │                    │                    │───────────────────>│                    │                    │
       │                    │                    │                    │                    │                    │
       │                    │                    │                    │ 10. Validate & Store│                   │
       │                    │                    │                    │───────────────────>│                   │
       │                    │                    │                    │                    │                    │
       │                    │                    │                    │ 11. Insert Reading │                    │
       │                    │                    │                    │───────────────────>│                    │
       │                    │                    │                    │                    │                    │
       │                    │                    │                    │ 12. Batch Timer    │                    │
       │                    │                    │                    │─────────────────> │                    │
       │                    │                    │                    │                    │                    │
       │                    │                    │                    │ 13. Submit Batch to Blockchain         │
       │                    │                    │                    │─────────────────────────────────────> │
       │                    │                    │                    │                    │                    │
       │                    │                    │                    │ 14. Transaction Submitted              │
       │                    │                    │                    │<───────────────────────────────────── │
       │                    │                    │                    │                    │                    │
       │                    │                    │                    │ 15. Update DB with Tx Hash             │
       │                    │                    │                    │───────────────────>│                    │
       │                    │                    │                    │                    │                    │
```

**Key Timing:**
- Steps 1-7: < 100ms (fast acknowledgment)
- Steps 8-11: < 200ms (async processing)
- Steps 12-15: 1-5s (blockchain confirmation)

---

## 3. DR Event Response Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Device    │      │  OpenLEADR  │      │   Oracle    │      │     API     │      │   Solana    │
│  (ESP32-S3) │      │    VTN      │      │   Bridge    │      │   Gateway   │      │  Blockchain │
└──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
       │                    │                    │                    │                    │
       │ 1. Poll DR Events (every 30s)           │                    │                    │
       │───────────────────>│                    │                    │                    │
       │                    │                    │                    │                    │
       │ 2. Event Active: Price = $0.35/kWh      │                    │                    │
       │<───────────────────│                    │                    │                    │
       │                    │                    │                    │                    │
       │ 3. Adjust Load (reduce to 3.6kW)        │                    │                    │
       │─────────────────> │                    │                    │                    │
       │                    │                    │                    │                    │
       │ 4. Send Reduced Reading                 │                    │                    │
       │    {power: 3.6kW, dr_active: true}      │                    │                    │
       │───────────────────>│                    │                    │                    │
       │                    │                    │                    │                    │
       │                    │ 5. Forward Reading │                    │                    │
       │                    │───────────────────>│                    │                    │
       │                    │                    │                    │                    │
       │                    │                    │ 6. Submit to Gateway                   │
       │                    │                    │───────────────────>│                    │
       │                    │                    │                    │                    │
       │                    │                    │                    │ 7. Record DR Compliance│
       │                    │                    │                    │───────────────────> │
       │                    │                    │                    │                    │
       │                    │                    │                    │ 8. Calculate Credits   │
       │                    │                    │                    │───────────────────> │
       │                    │                    │                    │                    │
       │                    │                    │                    │ 9. Credit Tokens   │
       │                    │                    │                    │<─────────────────── │
       │                    │                    │                    │                    │
       │                    │                    │                    │                    │
```

---

## 4. Batch Blockchain Submission Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Oracle    │      │     API     │      │  Batch      │      │   Solana    │
│   Bridge    │      │   Gateway   │      │  Aggregator │      │  Blockchain │
└──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
       │                    │                    │                    │
       │ 1. Stream Readings │                    │                    │
       │───────────────────>│                    │                    │
       │                    │                    │                    │
       │                    │ 2. Queue Reading   │                    │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 3. Check Batch Size (10 readings)       │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 4. Batch Ready     │                    │
       │                    │<───────────────────│                    │
       │                    │                    │                    │
       │                    │ 5. Construct Batch Transaction          │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 6. Calculate Priority Fee               │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 7. Sign with Oracle Authority           │
       │                    │─────────────────────────────────────>  │
       │                    │                    │                    │
       │                    │ 8. Submit Transaction                   │
       │                    │─────────────────────────────────────>  │
       │                    │                    │                    │
       │                    │ 9. Wait for Confirmation (1-2 blocks)   │
       │                    │<─────────────────────────────────────  │
       │                    │                    │                    │
       │                    │ 10. Parse Transaction Result            │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 11. Update All Readings with Tx Hash    │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 12. Clear Batch Queue                   │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
```

**Batch Optimization:**
```rust
// Batch submission logic
pub struct BatchAggregator {
    readings: Vec<MeterReading>,
    max_batch_size: usize,
    max_wait_time: Duration,
    last_flush: Instant,
}

impl BatchAggregator {
    pub async fn add_reading(&mut self, reading: MeterReading) -> Result<()> {
        self.readings.push(reading);
        
        // Flush if batch is full or timeout
        if self.readings.len() >= self.max_batch_size 
            || self.last_flush.elapsed() > self.max_wait_time 
        {
            self.flush().await?;
        }
        
        Ok(())
    }
    
    async fn flush(&mut self) -> Result<()> {
        if self.readings.is_empty() {
            return Ok(());
        }
        
        // Group by meter for efficient PDA updates
        let grouped = self.readings.iter()
            .chunk_by(|r| &r.meter_id)
            .into_iter()
            .map(|(k, g)| (k, g.collect()))
            .collect::<HashMap<_, _>>();
        
        // Submit batch transaction
        let tx_hash = submit_batch_readings(grouped).await?;
        
        // Update database
        for reading in &self.readings {
            update_reading_blockchain_tx(reading.id, &tx_hash).await?;
        }
        
        self.readings.clear();
        self.last_flush = Instant::now();
        
        Ok(())
    }
}
```

---

## 5. Error Handling & Retry Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Device    │      │   Oracle    │      │     API     │      │   Dead      │
│  (ESP32-S3) │      │   Bridge    │      │   Gateway   │      │   Letter    │
└──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
       │                    │                    │                    │
       │ 1. Submit Reading  │                    │                    │
       │───────────────────>│                    │                    │
       │                    │                    │                    │
       │                    │ 2. Forward to Gateway                   │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │                    │ 3. Gateway Timeout │
       │                    │                    │ (network error)    │
       │                    │                    │                    │
       │                    │ 4. Retry (delay=1s)│                    │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │                    │ 5. Gateway Error   │
       │                    │                    │ (503 unavailable)  │
       │                    │                    │                    │
       │                    │ 6. Retry (delay=2s)│                    │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │                    │ 6. Gateway Error   │
       │                    │                    │ (503 unavailable)  │
       │                    │                    │                    │
       │                    │ 7. Retry (delay=4s)│                    │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │                    │ 7. Gateway Error   │
       │                    │                    │ (503 unavailable)  │
       │                    │                    │                    │
       │                    │ 8. Move to DLQ     │                    │
       │                    │───────────────────────────────────────>│
       │                    │                    │                    │
       │ 9. Acknowledge (accepted, pending)       │                    │
       │<───────────────────│                    │                    │
       │                    │                    │                    │
       │                    │                    │                    │
       │                    │ 10. Background Recovery               │
       │                    │<──────────────────────────────────────│
       │                    │                    │                    │
       │                    │ 11. Retry Failed Readings (periodic)  │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
```

**Retry Configuration:**
```yaml
# Oracle Bridge retry policy
retry:
  max_attempts: 6
  initial_delay_ms: 1000
  max_delay_ms: 32000
  multiplier: 2.0
  jitter: 0.1
  
# Dead letter queue
dlq:
  stream_name: "gridtokenx:dlq:v1"
  max_age_hours: 24
  recovery_interval_minutes: 5
```

---

## 6. Device Authentication Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Device    │      │   Oracle    │      │     IAM     │      │   PostgreSQL│
│  (ESP32-S3) │      │   Bridge    │      │   Service   │      │             │
└──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
       │                    │                    │                    │
       │ 1. POST /ingest/smart-meter             │                    │
       │    X-API-KEY: device-key-xxx            │                    │
       │───────────────────>│                    │                    │
       │                    │                    │                    │
       │                    │ 2. Check Static Keys (fallback)         │
       │                    │───────────────┐    │                    │
       │                    │               │    │                    │
       │                    │<──────────────┘    │                    │
       │                    │                    │                    │
       │                    │ 3. Not Found       │                    │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 4. gRPC: VerifyApiKey                   │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │                    │ 5. Lookup API Key │
       │                    │                    │───────────────────>│
       │                    │                    │                    │
       │                    │                    │ 6. Key Valid       │
       │                    │                    │<───────────────────│
       │                    │                    │                    │
       │                    │ 7. Valid (role=device)                  │
       │                    │<───────────────────│                    │
       │                    │                    │                    │
       │                    │ 8. Process Request │                    │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
```

---

## 7. Blockchain PDA Derivation Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│     API     │      │   Solana    │      │   Oracle    │      │   Meter     │
│   Gateway   │      │    SDK      │      │   Program   │      │   State     │
└──────┬──────┘      └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
       │                    │                    │                    │
       │ 1. Prepare submitMeterReading           │                    │
       │───────────────────>│                    │                    │
       │                    │                    │                    │
       │                    │ 2. Derive OracleData PDA                │
       │                    │    seeds: ["oracle_data"]               │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 3. Derive MeterState PDA                │
       │                    │    seeds: ["meter", meter_id]           │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 4. Derive ReadingLog PDA                │
       │                    │    seeds: ["reading", reading_id]       │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 5. Construct Transaction                │
       │                    │    accounts: [OracleData, MeterState,   │
       │                    │                 ReadingLog, Authority]  │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 6. Sign Transaction                       │
       │                    │───────────────────>│                    │
       │                    │                    │                    │
       │                    │ 7. Submit to Network                    │
       │                    │─────────────────────────────────────>  │
       │                    │                    │                    │
       │                    │ 8. Execute Instruction                  │
       │                    │─────────────────────────────────────>  │
       │                    │                    │                    │
       │                    │ 9. Update MeterState Account            │
       │                    │    cumulative_generated += new_energy   │
       │                    │    reading_count += 1                   │
       │                    │─────────────────────────────────────>  │
       │                    │                    │                    │
       │                    │ 10. Create ReadingLog Account           │
       │                    │─────────────────────────────────────>  │
       │                    │                    │                    │
       │                    │ 11. Transaction Complete                │
       │                    │<─────────────────────────────────────  │
       │                    │                    │                    │
```

**PDA Derivation Code:**
```rust
// Derive OracleData PDA
let (oracle_data_pda, oracle_bump) = Pubkey::find_program_address(
    &[b"oracle_data"],
    &oracle_program_id
);

// Derive MeterState PDA
let seed_id = meter_id.replace("-", ""); // UUID to 32 bytes
let (meter_state_pda, meter_bump) = Pubkey::find_program_address(
    &[b"meter", seed_id.as_bytes()],
    &oracle_program_id
);

// Derive ReadingLog PDA
let reading_seed = reading_id.replace("-", "");
let (reading_log_pda, reading_bump) = Pubkey::find_program_address(
    &[b"reading", reading_seed.as_bytes()],
    &oracle_program_id
);
```

---

## 8. Complete End-to-End Flow

```
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ Device │ │ Oracle │ │ Redis  │ │  API   │ │  Post- │ │ Kafka  │ │Solana  │ │Trading │
│        │ │ Bridge │ │Streams │ │ Gateway│ │gres   │ │        │ │        │ │Service │
└───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘
    │          │          │          │          │          │          │          │
    │ 1. Read  │          │          │          │          │          │          │
    │─────────>│          │          │          │          │          │          │
    │          │          │          │          │          │          │          │
    │          │ 2. POST  │          │          │          │          │          │
    │          │<─────────│          │          │          │          │          │
    │          │          │          │          │          │          │          │
    │          │ 3. XADD  │          │          │          │          │          │
    │          │─────────>│          │          │          │          │          │
    │          │          │          │          │          │          │          │
    │          │ 4. 202   │          │          │          │          │          │
    │<─────────│          │          │          │          │          │          │
    │          │          │          │          │          │          │          │
    │          │          │          │          │          │          │          │
    │          │          │ 5. XREAD │          │          │          │          │
    │          │          │<─────────│          │          │          │          │
    │          │          │          │          │          │          │          │
    │          │          │ 6. gRPC  │          │          │          │          │
    │          │          │─────────>│          │          │          │          │
    │          │          │          │          │          │          │          │
    │          │          │          │ 7. INSERT│          │          │          │
    │          │          │          │─────────>│          │          │          │
    │          │          │          │          │          │          │          │
    │          │          │          │ 8. Kafka │          │          │          │
    │          │          │          │─────────────────>│          │          │
    │          │          │          │          │          │          │          │
    │          │          │          │ 9. Batch │          │          │          │
    │          │          │          │─────────────────────────────>│          │
    │          │          │          │          │          │          │          │
    │          │          │          │10. Tx Hash          │          │          │
    │          │          │          │<─────────────────────────────│          │
    │          │          │          │          │          │          │          │
    │          │          │          │11. Update│          │          │          │
    │          │          │          │<─────────│          │          │          │
    │          │          │          │          │          │          │          │
    │          │          │          │          │12. Event │          │          │
    │          │          │          │          │<─────────│          │          │
    │          │          │          │          │          │          │          │
    │          │          │          │          │          │          │13. Trade │
    │          │          │          │          │          │          │─────────>│
    │          │          │          │          │          │          │          │
```

---

## Timing Analysis

| Phase | Operation | P50 | P95 | P99 |
|-------|-----------|-----|-----|-----|
| 1 | Device → Oracle Bridge | 20ms | 50ms | 100ms |
| 2 | Oracle Bridge → Redis | 5ms | 10ms | 20ms |
| 3 | Redis → API Gateway | 10ms | 25ms | 50ms |
| 4 | API Gateway → PostgreSQL | 15ms | 40ms | 80ms |
| 5 | API Gateway → Solana | 500ms | 2s | 5s |
| **Total** | **End-to-End** | **550ms** | **2.1s** | **5.2s** |

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-27
