# IoT Access Implementation Guide

## Overview

This guide provides implementation details, code templates, and configuration for the IoT access architecture.

---

## 1. Oracle Bridge Implementation

### 1.1 Project Structure

```
gridtokenx-oracle-bridge/
├── Cargo.toml
├── src/
│   ├── main.rs              # Entry point
│   ├── handlers.rs          # HTTP handlers
│   ├── models.rs            # Data models
│   ├── state.rs             # Application state
│   ├── auth.rs              # API key authentication
│   ├── router.rs            # Redis Stream router
│   ├── ingester/
│   │   └── mod.rs           # Event ingester (Redis → gRPC)
│   ├── protocol/
│   │   ├── mod.rs           # Protocol trait
│   │   ├── smart_meter.rs   # Smart meter adapter
│   │   ├── ev_charger.rs    # EV charger adapter
│   │   └── battery.rs       # Battery adapter
│   └── blockchain/
│       └── mod.rs           # Solana client (future)
└── proto/
    └── iot.proto            # gRPC service definition
```

### 1.2 HTTP Handler Implementation

```rust
// src/handlers.rs

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde_json::json;
use tracing::{info, warn, error};

use crate::models::*;
use crate::state::AppState;

/// Health check endpoint
pub async fn health() -> impl IntoResponse {
    Json(json!({
        "status": "ok",
        "service": "gridtokenx-iot-gateway",
        "version": env!("CARGO_PKG_VERSION"),
    }))
}

/// Metrics endpoint
pub async fn get_metrics(
    State(state): State<AppState>,
) -> impl IntoResponse {
    use std::sync::atomic::Ordering;
    let m = &state.metrics;

    Json(json!({
        "total_requests": m.total_requests.load(Ordering::Relaxed),
        "authorized_requests": m.authorized_requests.load(Ordering::Relaxed),
        "failed_requests": m.failed_requests.load(Ordering::Relaxed),
        "on_chain_syncs": m.on_chain_syncs.load(Ordering::Relaxed),
    }))
}

/// Smart meter ingestion endpoint
pub async fn ingest_smart_meter(
    State(state): State<AppState>,
    Json(payload): Json<SmartMeterPayload>,
) -> impl IntoResponse {
    info!("📡 Smart meter reading from: {}", payload.device_id);

    // Validate payload
    if payload.device_id.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(json!({ "error": "device_id is required" })),
        ).into_response();
    }

    // Convert to canonical DeviceReading
    let raw = RawPayload {
        device_type: DeviceType::SmartMeter,
        body: serde_json::to_value(&payload).unwrap_or_default(),
    };

    match state.smart_meter_adapter.parse(&raw) {
        Ok(reading) => disseminate_reading(&state, reading).await,
        Err(e) => {
            warn!("⚠️ Failed to parse smart meter payload: {}", e);
            (
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": format!("Invalid payload: {}", e) })),
            ).into_response()
        }
    }
}

/// EV charger ingestion endpoint
pub async fn ingest_ev_charger(
    State(state): State<AppState>,
    Json(payload): Json<EvChargerPayload>,
) -> impl IntoResponse {
    info!("🔌 EV charger reading from: {}", payload.device_id);

    if payload.device_id.is_empty() || payload.session_id.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(json!({ "error": "device_id and session_id are required" })),
        ).into_response();
    }

    let raw = RawPayload {
        device_type: DeviceType::EvCharger,
        body: serde_json::to_value(&payload).unwrap_or_default(),
    };

    match state.ev_charger_adapter.parse(&raw) {
        Ok(reading) => disseminate_reading(&state, reading).await,
        Err(e) => {
            warn!("⚠️ Failed to parse EV charger payload: {}", e);
            (
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": format!("Invalid payload: {}", e) })),
            ).into_response()
        }
    }
}

/// Battery ingestion endpoint
pub async fn ingest_battery(
    State(state): State<AppState>,
    Json(payload): Json<BatteryPayload>,
) -> impl IntoResponse {
    info!("🔋 Battery reading from: {}", payload.device_id);

    if payload.device_id.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(json!({ "error": "device_id is required" })),
        ).into_response();
    }

    let raw = RawPayload {
        device_type: DeviceType::Battery,
        body: serde_json::to_value(&payload).unwrap_or_default(),
    };

    match state.battery_adapter.parse(&raw) {
        Ok(reading) => disseminate_reading(&state, reading).await,
        Err(e) => {
            warn!("⚠️ Failed to parse battery payload: {}", e);
            (
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": format!("Invalid payload: {}", e) })),
            ).into_response()
        }
    }
}

/// Shared dissemination function
async fn disseminate_reading(
    state: &AppState,
    reading: DeviceReading,
) -> axum::response::Response {
    let response = IngestResponse {
        status: "accepted",
        reading_id: reading.reading_id,
        device_type: reading.device_type,
        stream: reading.device_type.target_stream().to_string(),
    };

    match state.router.disseminate(&reading).await {
        Ok(_) => (StatusCode::ACCEPTED, Json(json!(response))).into_response(),
        Err(e) => {
            error!("❌ Failed to disseminate reading: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": "Failed to disseminate reading" })),
            ).into_response()
        }
    }
}
```

### 1.3 Protocol Adapter Pattern

```rust
// src/protocol/smart_meter.rs

use crate::models::*;
use uuid::Uuid;
use chrono::Utc;

pub struct SmartMeterAdapter {
    // Configuration can be added here
}

impl SmartMeterAdapter {
    pub fn new() -> Self {
        Self {}
    }

    pub fn parse(&self, raw: &RawPayload) -> Result<DeviceReading, String> {
        // Extract fields from raw payload
        let device_id = raw.body["device_id"]
            .as_str()
            .ok_or("device_id must be a string")?
            .to_string();

        let serial_number = raw.body["serial_number"]
            .as_str()
            .unwrap_or("unknown")
            .to_string();

        let timestamp = raw.body["timestamp"]
            .as_str()
            .and_then(|s| chrono::DateTime::parse_from_rfc3339(s).ok())
            .map(|dt| dt.with_timezone(&Utc))
            .unwrap_or_else(Utc::now);

        let energy_generated = raw.body["energy_generated"]
            .as_f64()
            .ok_or("energy_generated must be a number")?;

        let energy_consumed = raw.body["energy_consumed"]
            .as_f64()
            .unwrap_or(0.0);

        let metadata: std::collections::HashMap<String, serde_json::Value> = raw.body["metadata"]
            .as_object()
            .map(|m| m.iter().map(|(k, v)| (k.clone(), v.clone())).collect())
            .unwrap_or_default();

        // Create canonical DeviceReading
        Ok(DeviceReading {
            reading_id: Uuid::new_v4(),
            device_id,
            device_type: DeviceType::SmartMeter,
            serial_number,
            zone_id: None,
            timestamp,
            metrics: DeviceMetrics::Energy {
                generated_kwh: energy_generated,
                consumed_kwh: energy_consumed,
                net_kwh: energy_generated - energy_consumed,
            },
            metadata,
        })
    }
}
```

### 1.4 Redis Stream Router

```rust
// src/router.rs

use redis::{Client, ConnectionManager, streams::StreamMaxlen};
use tracing::{info, error};
use crate::models::DeviceReading;

pub struct Router {
    client: Client,
    max_len: StreamMaxlen,
}

impl Router {
    pub async fn new(redis_url: &str) -> Result<Self, redis::RedisError> {
        let client = Client::open(redis_url)?;
        
        // Configure max stream length (~100k entries)
        let max_len = StreamMaxlen::Approx(100000);

        info!("📏 Redis stream MAXLEN cap: ~{}", max_len.approx_limit());

        Ok(Self { client, max_len })
    }

    pub async fn disseminate(&self, reading: &DeviceReading) -> Result<(), redis::RedisError> {
        let mut conn = self.client.get_tokio_connection_manager().await?;
        
        let stream_name = reading.device_type.target_stream();
        
        // Serialize reading to hash
        let mut fields = Vec::new();
        fields.push(("reading_id", reading.reading_id.to_string()));
        fields.push(("device_id", reading.device_id.clone()));
        fields.push(("device_type", format!("{:?}", reading.device_type)));
        fields.push(("serial_number", reading.serial_number.clone()));
        fields.push(("timestamp", reading.timestamp.to_rfc3339()));
        
        // Serialize metrics based on type
        match &reading.metrics {
            DeviceMetrics::Energy { generated_kwh, consumed_kwh, net_kwh } => {
                fields.push(("energy_generated", generated_kwh.to_string()));
                fields.push(("energy_consumed", consumed_kwh.to_string()));
                fields.push(("net_energy", net_kwh.to_string()));
            }
            DeviceMetrics::EvSession { energy_delivered_kwh, session_id, connector_id, status } => {
                fields.push(("energy_delivered", energy_delivered_kwh.to_string()));
                fields.push(("session_id", session_id.clone()));
                fields.push(("connector_id", connector_id.to_string()));
                fields.push(("status", format!("{:?}", status)));
            }
            DeviceMetrics::BatteryState { soc_percent, power_kw, temperature_c, mode } => {
                fields.push(("soc_percent", soc_percent.to_string()));
                fields.push(("power_kw", power_kw.to_string()));
                fields.push(("temperature", temperature_c.to_string()));
                fields.push(("mode", format!("{:?}", mode)));
            }
        }

        // Add metadata
        for (key, value) in &reading.metadata {
            fields.push((format!("meta_{}", key), value.to_string()));
        }

        // Add to stream with MAXLEN
        redis::cmd("XADD")
            .arg(stream_name)
            .arg(&self.max_len)
            .arg("*")  // Auto-generate entry ID
            .args(&fields)
            .query_async(&mut conn)
            .await?;

        info!("📤 Published to {}: {}", stream_name, reading.reading_id);

        Ok(())
    }
}
```

---

## 2. API Gateway Implementation

### 2.1 gRPC Service Definition

```protobuf
// proto/iot.proto

syntax = "proto3";
package gridtokenx.iot.v1;

service IoTService {
    rpc SubmitMeterReading(SubmitMeterReadingRequest) 
        returns (SubmitMeterReadingResponse);
    
    rpc SubmitBatchReadings(SubmitBatchReadingsRequest) 
        returns (SubmitBatchReadingsResponse);
    
    rpc SubmitEVSession(SubmitEVSessionRequest) 
        returns (SubmitEVSessionResponse);
    
    rpc SubmitBatteryState(SubmitBatteryStateRequest) 
        returns (SubmitBatteryStateResponse);
}

message SubmitMeterReadingRequest {
    string device_id = 1;
    string serial_number = 2;
    int64 timestamp = 3;
    double energy_generated_kwh = 4;
    double energy_consumed_kwh = 5;
    double power_kw = 6;
    map<string, string> metadata = 7;
    string signature = 8;
}

message SubmitMeterReadingResponse {
    string reading_id = 1;
    bool accepted = 2;
    string transaction_hash = 3;
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

### 2.2 gRPC Service Implementation

```rust
// gridtokenx-api/src/grpc/iot_service.rs

use tonic::{Request, Response, Status};
use crate::proto::iot_service_server::IoTService;
use crate::proto::*;
use crate::db::DatabasePool;
use crate::blockchain::SolanaClient;

pub struct IotServiceImpl {
    db: DatabasePool,
    blockchain: SolanaClient,
    batch_aggregator: Arc<Mutex<BatchAggregator>>,
}

#[tonic::async_trait]
impl IoTService for IotServiceImpl {
    async fn submit_meter_reading(
        &self,
        request: Request<SubmitMeterReadingRequest>,
    ) -> Result<Response<SubmitMeterReadingResponse>, Status> {
        let req = request.into_inner();
        
        // 1. Validate signature
        if !verify_device_signature(&req).await? {
            return Err(Status::unauthenticated("Invalid device signature"));
        }
        
        // 2. Generate reading ID
        let reading_id = Uuid::new_v4().to_string();
        
        // 3. Store in PostgreSQL
        let query = r#"
            INSERT INTO meter_readings 
            (reading_id, device_id, timestamp, energy_generated_kwh, 
             energy_consumed_kwh, power_kw, metadata)
            VALUES ($1, $2, to_timestamp($3), $4, $5, $6, $7)
            ON CONFLICT (reading_id) DO NOTHING
        "#;
        
        sqlx::query(query)
            .bind(&reading_id)
            .bind(&req.device_id)
            .bind(req.timestamp)
            .bind(req.energy_generated_kwh)
            .bind(req.energy_consumed_kwh)
            .bind(req.power_kw)
            .bind(&serde_json::to_value(&req.metadata).unwrap())
            .execute(&self.db)
            .await
            .map_err(|e| Status::internal(format!("Database error: {}", e)))?;
        
        // 4. Add to batch aggregator
        {
            let mut aggregator = self.batch_aggregator.lock().await;
            aggregator.add_reading(req.clone()).await?;
        }
        
        Ok(Response::new(SubmitMeterReadingResponse {
            reading_id,
            accepted: true,
            transaction_hash: String::new(),  // Will be updated when batch is submitted
            block_height: 0,
        }))
    }
    
    async fn submit_batch_readings(
        &self,
        request: Request<SubmitBatchReadingsRequest>,
    ) -> Result<Response<SubmitBatchReadingsResponse>, Status> {
        let req = request.into_inner();
        
        let mut accepted = Vec::new();
        let mut rejected = Vec::new();
        
        // Process each reading
        for reading in req.readings {
            match self.submit_meter_reading(Request::new(reading)).await {
                Ok(resp) => accepted.push(resp.into_inner().reading_id),
                Err(_) => rejected.push(reading.device_id),
            }
        }
        
        Ok(Response::new(SubmitBatchReadingsResponse {
            batch_id: req.batch_id,
            accepted_count: accepted.len() as i32,
            rejected_count: rejected.len() as i32,
            reading_ids: accepted,
            transaction_hash: String::new(),
        }))
    }
    
    // Implement other methods similarly...
}
```

### 2.3 Batch Aggregator

```rust
// gridtokenx-api/src/blockchain/batch_aggregator.rs

use tokio::time::{interval, Duration};
use crate::blockchain::SolanaClient;
use crate::proto::SubmitMeterReadingRequest;

pub struct BatchAggregator {
    readings: Vec<SubmitMeterReadingRequest>,
    max_batch_size: usize,
    max_wait_time: Duration,
    last_flush: Instant,
    blockchain: SolanaClient,
}

impl BatchAggregator {
    pub fn new(blockchain: SolanaClient, max_batch_size: usize, max_wait_secs: u64) -> Self {
        Self {
            readings: Vec::with_capacity(max_batch_size),
            max_batch_size,
            max_wait_time: Duration::from_secs(max_wait_secs),
            last_flush: Instant::now(),
            blockchain,
        }
    }
    
    pub async fn add_reading(&mut self, reading: SubmitMeterReadingRequest) -> Result<(), Status> {
        self.readings.push(reading);
        
        // Flush if batch is full or timeout
        if self.readings.len() >= self.max_batch_size 
            || self.last_flush.elapsed() > self.max_wait_time 
        {
            self.flush().await?;
        }
        
        Ok(())
    }
    
    async fn flush(&mut self) -> Result<(), Status> {
        if self.readings.is_empty() {
            return Ok(());
        }
        
        // Group readings by meter_id for efficient PDA updates
        let mut grouped: HashMap<String, Vec<&SubmitMeterReadingRequest>> = HashMap::new();
        for reading in &self.readings {
            grouped.entry(reading.device_id.clone())
                .or_insert_with(Vec::new)
                .push(reading);
        }
        
        // Construct batch instruction
        let mut instructions = Vec::new();
        for (meter_id, readings) in grouped {
            let meter_readings: Vec<MeterReadingInput> = readings.iter()
                .map(|r| MeterReadingInput {
                    reading_id: Uuid::new_v4().to_string(),
                    meter_id: meter_id.clone(),
                    timestamp: r.timestamp,
                    energy_generated: (r.energy_generated_kwh * 1000.0) as u64,
                    energy_consumed: (r.energy_consumed_kwh * 1000.0) as u64,
                    power_kw: (r.power_kw * 1000.0) as u32,
                })
                .collect();
            
            instructions.push(meter_readings);
        }
        
        // Submit batch transaction to Solana
        let tx_hash = self.blockchain.submit_batch_readings(instructions).await?;
        
        // Update database with transaction hash
        for reading in &self.readings {
            // Update reading with tx_hash
            // (implementation depends on your database layer)
        }
        
        info!("✅ Batch submitted: {} readings, tx: {}", self.readings.len(), tx_hash);
        
        self.readings.clear();
        self.last_flush = Instant::now();
        
        Ok(())
    }
}
```

---

## 3. Solana Oracle Program

### 3.1 Program Structure

```rust
// gridtokenx-anchor/programs/oracle/src/lib.rs

use anchor_lang::prelude::*;
use anchor_lang::solana_program::system_program;

declare_id!("Ad5crRxCcvKFAShAMYtRAD9XKak1cwH1FCE6TrpUA9i2");

#[program]
pub mod oracle {
    use super::*;
    
    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let oracle_data = &mut ctx.accounts.oracle_data;
        oracle_data.authority = ctx.accounts.authority.key();
        oracle_data.total_readings = 0;
        oracle_data.total_energy_kwh = 0;
        oracle_data.last_update = Clock::get()?.unix_timestamp;
        oracle_data.bump = ctx.bumps.oracle_data;
        
        Ok(())
    }
    
    pub fn submitMeterReading(ctx: Context<SubmitMeterReading>, 
                              reading_id: String,
                              timestamp: i64,
                              energy_generated: u64,
                              energy_consumed: u64,
                              power_kw: u32,
                              dr_active: bool) -> Result<()> {
        let meter_state = &mut ctx.accounts.meter_state;
        let oracle_data = &mut ctx.accounts.oracle_data;
        
        // Update meter state
        meter_state.cumulative_generated = meter_state.cumulative_generated
            .checked_add(energy_generated)
            .ok_or(OracleError::Overflow)?;
        
        meter_state.cumulative_consumed = meter_state.cumulative_consumed
            .checked_add(energy_consumed)
            .ok_or(OracleError::Overflow)?;
        
        meter_state.last_reading_time = timestamp;
        meter_state.reading_count = meter_state.reading_count
            .checked_add(1)
            .ok_or(OracleError::Overflow)?;
        
        meter_state.dr_event_active = dr_active;
        
        // Update global oracle data
        oracle_data.total_readings = oracle_data.total_readings
            .checked_add(1)
            .ok_or(OracleError::Overflow)?;
        
        oracle_data.total_energy_kwh = oracle_data.total_energy_kwh
            .checked_add(energy_generated)
            .ok_or(OracleError::Overflow)?;
        
        oracle_data.last_update = Clock::get()?.unix_timestamp;
        
        // Optionally create ReadingLog account for audit trail
        // (implementation omitted for brevity)
        
        emit!(MeterReadingSubmitted {
            meter_id: meter_state.meter_id.clone(),
            reading_id,
            timestamp,
            energy_generated,
            energy_consumed,
        });
        
        Ok(())
    }
    
    pub fn submitBatchReadings(ctx: Context<SubmitBatchReadings>,
                               readings: Vec<MeterReadingInput>) -> Result<()> {
        let oracle_data = &mut ctx.accounts.oracle_data;
        
        for reading in readings {
            // Find or create meter state account
            // Update cumulative values
            // (implementation similar to submitMeterReading)
        }
        
        Ok(())
    }
}

// Account structures
#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + OracleData::INIT_SPACE,
        seeds = [b"oracle_data"],
        bump
    )]
    pub oracle_data: Account<'info, OracleData>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(reading_id: String)]
pub struct SubmitMeterReading<'info> {
    #[account(
        mut,
        seeds = [b"oracle_data"],
        bump = oracle_data.bump
    )]
    pub oracle_data: Account<'info, OracleData>,
    
    #[account(
        mut,
        seeds = [b"meter", meter_id.as_bytes()],
        bump = meter_state.bump
    )]
    pub meter_state: Account<'info, MeterState>,
    
    #[account(
        init_if_needed,
        payer = authority,
        space = 8 + ReadingLog::INIT_SPACE,
        seeds = [b"reading", reading_id.as_bytes()],
        bump
    )]
    pub reading_log: Option<Account<'info, ReadingLog>>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

// State structs
#[account]
#[derive(InitSpace)]
pub struct OracleData {
    pub authority: Pubkey,
    pub total_readings: u64,
    pub total_energy_kwh: u64,
    pub last_update: i64,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct MeterState {
    #[max_len(36)]
    pub meter_id: String,
    pub owner: Pubkey,
    pub cumulative_generated: u64,
    pub cumulative_consumed: u64,
    pub last_reading_time: i64,
    pub reading_count: u64,
    pub dr_event_active: bool,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct ReadingLog {
    pub meter: Pubkey,
    #[max_len(36)]
    pub reading_id: String,
    pub timestamp: i64,
    pub energy_generated: u64,
    pub energy_consumed: u64,
    pub power_kw: u32,
    pub dr_active: bool,
    pub submitted_by: Pubkey,
    pub bump: u8,
}

#[derive(AnchorSerialize, AnchorDeserialize)]
pub struct MeterReadingInput {
    pub reading_id: String,
    pub meter_id: String,
    pub timestamp: i64,
    pub energy_generated: u64,
    pub energy_consumed: u64,
    pub power_kw: u32,
}

// Events
#[event]
pub struct MeterReadingSubmitted {
    pub meter_id: String,
    pub reading_id: String,
    pub timestamp: i64,
    pub energy_generated: u64,
    pub energy_consumed: u64,
}

// Errors
#[error_code]
pub enum OracleError {
    #[msg("Integer overflow")]
    Overflow,
    #[msg("Invalid meter ID")]
    InvalidMeterId,
    #[msg("Reading already submitted")]
    DuplicateReading,
}
```

---

## 4. Configuration Files

### 4.1 Docker Compose

```yaml
# docker-compose.oracle-bridge.yml
version: '3.8'

services:
  oracle-bridge:
    build:
      context: ./
      dockerfile: gridtokenx-oracle-bridge/Dockerfile
    container_name: gridtokenx-oracle-bridge
    ports:
      - "4010:4010"
    environment:
      RUST_LOG: info
      REDIS_URL: redis://redis:6379
      API_GATEWAY_URL: http://api-gateway:4001
      IOT_GATEWAY_PORT: 4010
      GRIDTOKENX_API_KEYS: engineering-key,production-key
      IAM_SERVICE_URL: http://iam-service:8080
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - gridtokenx-network
    restart: unless-stopped

  api-gateway:
    build:
      context: ./
      dockerfile: gridtokenx-api/Dockerfile
    container_name: gridtokenx-api-gateway
    ports:
      - "4001:4001"
    environment:
      DATABASE_URL: postgresql://user:pass@postgres:5432/gridtokenx
      REDIS_URL: redis://redis:6379
      SOLANA_RPC_URL: http://solana-validator:8899
      ORACLE_PROGRAM_ID: Ad5crRxCcvKFAShAMYtRAD9XKak1cwH1FCE6TrpUA9i2
      GRPC_PORT: 4001
    depends_on:
      - postgres
      - redis
    networks:
      - gridtokenx-network

  redis:
    image: redis:7-alpine
    container_name: gridtokenx-redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - gridtokenx-network

volumes:
  redis-data:

networks:
  gridtokenx-network:
    driver: bridge
```

### 4.2 Environment Variables

```bash
# .env.oracle-bridge

# Oracle Bridge
REDIS_URL=redis://localhost:6379
API_GATEWAY_URL=http://localhost:4001
IOT_GATEWAY_PORT=4010
GRIDTOKENX_API_KEYS=dev-key-123,prod-key-456
IAM_SERVICE_URL=http://localhost:50051
RUST_LOG=info,tower_http=debug

# API Gateway
DATABASE_URL=postgresql://gridtokenx:password@localhost:5432/gridtokenx
SOLANA_RPC_URL=http://localhost:8899
ORACLE_PROGRAM_ID=Ad5crRxCcvKFAShAMYtRAD9XKak1cwH1FCE6TrpUA9i2
ORACLE_AUTHORITY_WALLET=/path/to/oracle-authority.json
GRPC_PORT=4001
BATCH_SIZE=10
BATCH_TIMEOUT_SECS=5

# Blockchain
COMPUTE_UNIT_PRICE=1000
PRIORITY_FEE_MULTIPLIER=2.0
```

---

## 5. Testing

### 5.1 Integration Test Script

```python
#!/usr/bin/env python3
# test_iot_access.py

import requests
import grpc
import time
from proto.iot_pb2 import SubmitMeterReadingRequest
from proto.iot_pb2_grpc import IoTServiceStub

ORACLE_BRIDGE_URL = "http://localhost:4010"
API_GATEWAY_URL = "localhost:4001"
API_KEY = "dev-key-123"

def test_oracle_bridge_ingestion():
    """Test Oracle Bridge HTTP ingestion"""
    print("Testing Oracle Bridge ingestion...")
    
    payload = {
        "device_id": "TEST-MTR-001",
        "energy_generated": 1.5,
        "energy_consumed": 0.5,
        "reading_value": 0.75,
        "metadata": {"test": True}
    }
    
    headers = {"X-API-KEY": API_KEY, "Content-Type": "application/json"}
    
    response = requests.post(
        f"{ORACLE_BRIDGE_URL}/api/v1/ingest/smart-meter",
        json=payload,
        headers=headers
    )
    
    assert response.status_code == 202
    data = response.json()
    assert data["status"] == "accepted"
    assert "reading_id" in data
    
    print(f"✅ Oracle Bridge test passed: {data['reading_id']}")

def test_grpc_submission():
    """Test API Gateway gRPC submission"""
    print("Testing API Gateway gRPC...")
    
    channel = grpc.insecure_channel(API_GATEWAY_URL)
    stub = IoTServiceStub(channel)
    
    request = SubmitMeterReadingRequest(
        device_id="TEST-MTR-001",
        timestamp=int(time.time()),
        energy_generated_kwh=1.5,
        energy_consumed_kwh=0.5,
        power_kw=0.75
    )
    
    response = stub.SubmitMeterReading(request)
    
    assert response.accepted
    assert response.reading_id
    
    print(f"✅ gRPC test passed: {response.reading_id}")

if __name__ == "__main__":
    test_oracle_bridge_ingestion()
    test_grpc_submission()
    print("All tests passed!")
```

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-27
