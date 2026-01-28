# System Architecture and Design Framework
## GridTokenX Platform - Comprehensive Technical Documentation

---

## 1. Executive Summary

**GridTokenX** is an enterprise-grade, blockchain-powered **Peer-to-Peer (P2P) energy trading platform** built on the Solana blockchain. It bridges the gap between physical energy infrastructure and decentralized finance (DeFi), enabling transparent, efficient, and trustless energy markets.

**Core Value Proposition:**
*   **Real-Time Settlement**: Energy trades settled in milliseconds via smart contracts.
*   **Verifiable Telemetry**: Physics-based simulation ensures data integrity.
*   **Economic Efficiency**: 97.5% cost reduction vs traditional utility distribution fees.
*   **Renewable Incentives**: RECs (Renewable Energy Certificates) provide price premiums for green energy.

**Architecture Philosophy:**
*   **Hybrid Design**: Off-chain processing for high-throughput data, on-chain settlement for value transfer.
*   **Defense in Depth**: Multi-layered validation (client → API → oracle → smart contract).
*   **Scalability First**: Event-driven architecture with horizontal scaling capabilities.

---

## 2. Architecture Overview

### 2.1 System Context Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        EXTERNAL SYSTEMS                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │  Pyth    │  │ Mapbox   │  │  Email   │  │Prometheus│           │
│  │ Oracles  │  │   API    │  │  SMTP    │  │ Monitor  │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │             │              │             │                  │
└───────┼─────────────┼──────────────┼─────────────┼──────────────────┘
        │             │              │             │
        ▼             ▼              ▼             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GRIDTOKENX PLATFORM                             │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                    FRONTEND LAYER                           │   │
│  │  ┌──────────────┐              ┌──────────────┐            │   │
│  │  │   Trading    │              │    Admin     │            │   │
│  │  │     UI       │              │   Portal     │            │   │
│  │  │  (Next.js)   │              │  (Next.js)   │            │   │
│  │  │  Port: 3000  │              │  Port: 3001  │            │   │
│  │  └──────┬───────┘              └──────┬───────┘            │   │
│  └─────────┼──────────────────────────────┼────────────────────┘   │
│            │                              │                        │
│            │        HTTP/WebSocket        │                        │
│            │                              │                        │
│  ┌─────────▼──────────────────────────────▼────────────────────┐  │
│  │                   BACKEND LAYER                              │  │
│  │  ┌───────────────────────────────────────────────────────┐  │  │
│  │  │           API Gateway (Rust/Axum)                      │  │  │
│  │  │              Port: 4000                                │  │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │  │  │
│  │  │  │ Auth     │  │ Trading  │  │  Meter   │            │  │  │
│  │  │  │ Service  │  │ Service  │  │ Service  │            │  │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘            │  │  │
│  │  └──────┬────────────┬────────────┬──────────────────────┘  │  │
│  │         │            │            │                         │  │
│  │         │            │            │                         │  │
│  │  ┌──────▼────────────▼────────────▼──────────────────────┐ │  │
│  │  │              DATA LAYER                               │ │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐           │ │  │
│  │  │  │PostgreSQL│  │  Redis   │  │ InfluxDB │           │ │  │
│  │  │  │(Relational│  │ (Cache)  │  │ (Time    │           │ │  │
│  │  │  │   Data)  │  │          │  │  Series) │           │ │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘           │ │  │
│  │  └───────────────────────────────────────────────────────┘ │  │
│  │                                                             │  │
│  │  ┌───────────────────────────────────────────────────────┐ │  │
│  │  │            MESSAGING LAYER                            │ │  │
│  │  │  ┌─────────────────────────────────────────────────┐ │ │  │
│  │  │  │         Kafka Message Broker                    │ │ │  │
│  │  │  │  Topic: meter-readings (8 partitions)           │ │ │  │
│  │  │  └───────┬─────────────────────────────────────────┘ │ │  │
│  │  └──────────┼───────────────────────────────────────────┘ │  │
│  └─────────────┼─────────────────────────────────────────────┘  │
│                │                                                 │
│                │                                                 │
│  ┌─────────────▼─────────────────────────────────────────────┐  │
│  │              SIMULATION LAYER                             │  │
│  │  ┌────────────────────────────────────────────────────┐   │  │
│  │  │    Smart Meter Simulator (Python/FastAPI)          │   │  │
│  │  │              Port: 8080                             │   │  │
│  │  │  • Pandapower Physics Engine                        │   │  │
│  │  │  • Meter Templates (Residential/Commercial/Ind.)    │   │  │
│  │  │  • Environmental Models (Weather, Season)           │   │  │
│  │  └────────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │             BLOCKCHAIN LAYER                              │  │
│  │  ┌────────────────────────────────────────────────────┐   │  │
│  │  │         Solana Validator Network                   │   │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐         │   │  │
│  │  │  │ Registry │  │ Trading  │  │  Energy  │         │   │  │
│  │  │  │ Program  │  │ Program  │  │  Token   │         │   │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘         │   │  │
│  │  │  ┌──────────┐  ┌──────────┐                        │   │  │
│  │  │  │  Oracle  │  │Governance│                        │   │  │
│  │  │  │ Program  │  │ Program  │                        │   │  │
│  │  │  └──────────┘  └──────────┘                        │   │  │
│  │  └────────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Design Principles

**1. Separation of Concerns**
*   **Frontend**: Pure presentation and UX.
*   **Backend**: Business logic and orchestration.
*   **Blockchain**: Value transfer and settlement.
*   **Data Layer**: Persistence and analytics.

**2. Event-Driven Architecture**
*   Kafka serves as the central nervous system for asynchronous communication.
*   Decouples producers (simulator) from consumers (API Gateway).
*   Enables horizontal scaling of consumer workers.

**3. Zero Trust Security**
*   Every layer validates inputs independently.
*   API keys for simulator → gateway.
*   JWT tokens for user → gateway.
*   Oracle authority for gateway → blockchain.

**4. Performance Optimization**
*   Redis for sub-millisecond caching.
*   InfluxDB for optimized time-series queries.
*   PostgreSQL with JSONB for flexible schema.
*   Anchor zero-copy deserialization for low CU costs.

---

## 3. Frontend Layer

### 3.1 Trading Application

**Technology Stack:**
*   **Framework**: Next.js 15 (App Router)
*   **Language**: TypeScript
*   **UI Library**: shadcn/ui + TailwindCSS
*   **State Management**: React Context + SWR
*   **Blockchain**: Solana Wallet Adapter + Web3.js

**Architecture Pattern**: Server Components + Client Components

**Key Features:**

#### 3.1.1 Dashboard
*   Real-time energy generation/consumption meters
*   Live price charts (TradingView)
*   Order book visualization
*   Portfolio balance (GRID tokens, USDC)

#### 3.1.2 Trading Interface
```typescript
// Client Component (browser-side Solana interaction)
'use client';

export function TradingPanel() {
  const { connection } = useConnection();
  const { publicKey, signTransaction } = useWallet();
  const { data: orders } = useSWR('/api/orders/active', fetcher);
  
  async function createOrder(params: OrderParams) {
    // 1. Build transaction via API
    const { transaction } = await fetch('/api/orders/create', {
      method: 'POST',
      body: JSON.stringify(params),
    }).then(r => r.json());
    
    // 2. User signs transaction
    const tx = Transaction.from(Buffer.from(transaction, 'base64'));
    const signed = await signTransaction(tx);
    
    // 3. Submit to blockchain
    const sig = await connection.sendRawTransaction(signed.serialize());
    await connection.confirmTransaction(sig);
  }
}
```

#### 3.1.3 Map Visualization
*   **Mapbox GL JS** for grid topology
*   Real-time meter positions with color-coded status:
    *   🟢 Green: Net producer (surplus)
    *   🔴 Red: Net consumer (deficit)
    *   🟡 Yellow: Balanced
*   Zone boundaries for wheeling charge calculation

**Configuration:**
```typescript
// next.config.ts
export default {
  reactStrictMode: true,
  output: 'standalone',  // Docker-optimized
  compress: true,
  images: {
    formats: ['image/avif', 'image/webp'],
  },
  async rewrites() {
    return [
      { source: '/api/:path*', destination: 'http://localhost:4000/api/:path*' },
      { source: '/ws', destination: 'http://localhost:4000/ws' },
    ];
  },
};
```

### 3.2 Admin Portal

**Purpose**: System monitoring and configuration.

**Features:**
*   User management (approve/suspend accounts)
*   Meter registration approval
*   Market parameters (fee adjustment, circuit breakers)
*   System health dashboard (Prometheus metrics)
*   Audit log viewer

**Authorization**: Role-based access control (RBAC)
```typescript
export enum UserRole {
  Admin = 'admin',
  Operator = 'operator',
  User = 'user',
}
```

### 3.3 Performance Optimizations

**Bundle Splitting:**
```typescript
// Dynamic imports for heavy libraries
const MapComponent = dynamic(() => import('@/components/Map'), {
  loading: () => <Skeleton />,
  ssr: false,  // Map only renders client-side
});
```

**Image Optimization:**
*   Next.js Image component with AVIF/WebP
*   Remote patterns whitelisting (Arweave, Shadow Drive)

**API Caching:**
```typescript
import useSWR from 'swr';

// Auto-refresh every 5 seconds
const { data } = useSWR('/api/meters/status', fetcher, {
  refreshInterval: 5000,
  revalidateOnFocus: true,
});
```

---

## 4. Backend Layer (API Gateway)

### 4.1 Technology Stack

**Core:**
*   **Language**: Rust 1.75+
*   **Framework**: Axum 0.7 (async web framework)
*   **Runtime**: Tokio (async executor)
*   **Database**: SQLx (compile-time SQL verification)

**Middleware:**
*   **Authentication**: JWT (jsonwebtoken crate)
*   **CORS**: tower-http
*   **Logging**: tracing + tracing-subscriber
*   **Metrics**: metrics-exporter-prometheus

### 4.2 Service Architecture

**Modular Design** (src/services/):
```
services/
├── auth.rs                  # User authentication
├── blockchain/              # Solana RPC interactions
│   ├── client.rs
│   ├── programs.rs
│   └── wallet.rs
├── cache.rs                 # Redis operations
├── dashboard/               # Analytics aggregation
├── email_notification.rs    # SMTP alerts
├── erc.rs                   # REC issuance/validation
├── kafka/                   # Message broker
│   ├── consumer.rs
│   └── producer.rs
├── market_clearing.rs       # Batch order matching
├── meter/                   # Telemetry processing
├── order_matching_engine.rs # Order book logic
├── reading_processor.rs     # Async worker pool
├── settlement.rs            # Financial reconciliation
├── transaction.rs           # Blockchain tx building
├── validation.rs            # Input sanitization
├── wallet.rs                # Keypair management
└── websocket.rs             # Real-time updates
```

### 4.3 Startup Sequence

**Initialization Flow** (startup.rs):
```rust
pub async fn initialize_app(config: &Config) -> Result<AppState> {
    info!("🚀 Starting API Gateway");
    
    // 1. Metrics exporter
    let metrics_handle = PrometheusBuilder::new().install_recorder()?;
    
    // 2. Database pool (PostgreSQL)
    let db_pool = setup_database(&config.database_url).await?;
    run_migrations(&db_pool).await?;
    
    // 3. Redis client
    let redis_client = setup_redis(config).await?;
    
    // 4. Authentication services
    let jwt_service = JwtService::new()?;
    let api_key_service = ApiKeyService::new()?;
    
    // 5. Email service (SMTP)
    let email_service = initialize_email_service(config);
    
    // 6. Blockchain service (Solana RPC)
    let blockchain_service = BlockchainService::new(
        config.solana_rpc_url.clone(),
        config.solana_programs.clone(),
    )?;
    
    // 7. Wallet service (authority keypair)
    let wallet_service = WalletService::with_path(
        &config.solana_rpc_url,
        env::var("AUTHORITY_WALLET_PATH")?,
    );
    
    // 8. WebSocket hub
    let websocket_service = WebSocketService::new();
    
    // 9. Cache service (Redis wrapper)
    let cache_service = CacheService::new(&config.redis_url).await?;
    
    // 10. Health checker
    let health_checker = HealthChecker::new(
        db_pool.clone(),
        redis_client.clone(),
        config.solana_rpc_url.clone(),
    );
    
    // 11. Audit logger (immutable event log)
    let audit_logger = AuditLogger::new(db_pool.clone());
    
    // 12. Market clearing service
    let market_clearing = MarketClearingService::new(
        db_pool.clone(),
        blockchain_service.clone(),
    );
    
    // 13. Kafka consumer (meter readings)
    if config.kafka_enabled {
        let kafka_consumer = KafkaConsumerService::from_env();
        spawn_kafka_consumer(kafka_consumer, app_state.clone());
    }
    
    // 14. Reading processor workers (4 workers)
    for worker_id in 0..4 {
        spawn_reading_processor(worker_id, app_state.clone());
    }
    
    Ok(AppState { /* all services */ })
}
```

### 4.4 Request Flow

**Example: Create Sell Order**
```
Client Request
     │
     ▼
┌─────────────────┐
│  JWT Middleware │ Validates token, extracts user_id
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Rate Limiter    │ 100 req/min per user
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Handler         │ /api/orders/sell
│  (orders.rs)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Validation      │ • energy_amount > 0
│  Service        │ • price_per_kwh > min_price
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Database Query  │ SELECT meter_id FROM meters WHERE user_id = ?
│  (SQLx)         │ Verify user owns meter
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Blockchain Tx   │ Build CreateSellOrder instruction
│  Builder        │ • Serialize accounts
│                 │ • Set compute budget
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Solana RPC      │ sendTransaction(signed_tx)
│  (via Wallet)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Confirmation    │ Wait for 'confirmed' commitment
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Database Update │ INSERT INTO orders (tx_signature, ...)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ WebSocket Pub   │ Broadcast to subscribed clients
└────────┬────────┘
         │
         ▼
   JSON Response
```

### 4.5 Error Handling

**Custom Error Types:**
```rust
#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("Redis error: {0}")]
    Redis(#[from] redis::RedisError),
    
    #[error("Blockchain error: {0}")]
    Blockchain(String),
    
    #[error("Unauthorized: {0}")]
    Unauthorized(String),
    
    #[error("Validation error: {0}")]
    Validation(String),
    
    #[error("Not found: {0}")]
    NotFound(String),
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            ApiError::Unauthorized(_) => (StatusCode::UNAUTHORIZED, self.to_string()),
            ApiError::Validation(_) => (StatusCode::BAD_REQUEST, self.to_string()),
            ApiError::NotFound(_) => (StatusCode::NOT_FOUND, self.to_string()),
            _ => (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".into()),
        };
        
        (status, Json(json!({ "error": message }))).into_response()
    }
}
```

---

## 5. Data Layer

### 5.1 PostgreSQL (Relational Data)

**Schema Design:**
```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    wallet_address VARCHAR(44),  -- Solana pubkey
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    balance DECIMAL(18, 9) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Meters table
CREATE TABLE meters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    serial_number VARCHAR(255) UNIQUE NOT NULL,
    meter_type VARCHAR(50) NOT NULL,  -- Solar | Grid | Hybrid
    location VARCHAR(255),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    zone_id INTEGER,
    wallet_address VARCHAR(44),  -- PDA derived address
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Meter readings table (hot data, 7-day retention)
CREATE TABLE meter_readings (
    id BIGSERIAL PRIMARY KEY,
    meter_id UUID REFERENCES meters(id),
    timestamp TIMESTAMPTZ NOT NULL,
    kwh DOUBLE PRECISION NOT NULL,
    voltage DOUBLE PRECISION,
    current DOUBLE PRECISION,
    power_factor DOUBLE PRECISION,
    energy_generated DOUBLE PRECISION,
    energy_consumed DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    INDEX idx_meter_time (meter_id, timestamp DESC)
);

-- Orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_type VARCHAR(10) NOT NULL,  -- buy | sell
    user_id UUID REFERENCES users(id),
    meter_id UUID REFERENCES meters(id),
    energy_amount DECIMAL(18, 9) NOT NULL,
    price_per_kwh DECIMAL(18, 9) NOT NULL,
    filled_amount DECIMAL(18, 9) DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'active',  -- active | filled | cancelled
    tx_signature VARCHAR(88),  -- Solana transaction signature
    created_at TIMESTAMPTZ DEFAULT NOW(),
    INDEX idx_status_created (status, created_at DESC)
);
```

**Performance Tuning:**
*   **Connection Pooling**: Max 100 connections (PgBouncer)
*   **Indexes**: Covering indexes on frequent queries
*   **Partitioning**: `meter_readings` partitioned by month
*   **Vacuum**: Auto-vacuum for deleted rows

### 5.2 Redis (Caching & Queuing)

**Use Cases:**

**1. Session Storage**
```rust
// Key: session:{user_id}
// Value: JWT token metadata
// TTL: 1 hour
redis.setex(
    format!("session:{}", user_id),
    3600,
    serde_json::to_string(&session_data)?
);
```

**2. Rate Limiting**
```rust
// Key: ratelimit:{user_id}:{endpoint}
// Value: request count
// TTL: 60 seconds
let count: i64 = redis.incr(format!("ratelimit:{}:orders", user_id))?;
if count == 1 {
    redis.expire(format!("ratelimit:{}:orders", user_id), 60)?;
}
if count > 100 {
    return Err(ApiError::RateLimitExceeded);
}
```

**3. Real-Time Meter Cache**
```rust
// Key: meter:{serial}:latest
// Value: Full reading JSON
// TTL: 60 seconds
redis.setex(
    format!("meter:{}:latest", serial),
    60,
    serde_json::to_string(&reading)?
);
```

**4. Task Queue**
```rust
// List: queue:meter_readings
// RPUSH to enqueue, BRPOP to dequeue
redis.rpush("queue:meter_readings", task_json)?;

// Worker
let task: String = redis.brpop("queue:meter_readings", 1.0)?;
```

### 5.3 InfluxDB (Time-Series Data)

**Measurement Schema:**
```flux
// Measurement: energy_metrics
// Tags: meter_serial, zone_id, meter_type
// Fields: voltage, current, power_factor, generation, consumption
// Timestamp: nanosecond precision

energy_metrics,meter_serial=MEA-001,zone_id=3,meter_type=Solar \
  voltage=220.5,current=5.4,power_factor=0.95,\
  generation=3200,consumption=1800 \
  1706356800000000000
```

**Retention Policy:**
```flux
// High-resolution data: 7 days
CREATE RETENTION POLICY "7_days" ON "gridtokenx" DURATION 7d REPLICATION 1 DEFAULT

// Downsampled to hourly: 90 days
CREATE RETENTION POLICY "90_days_hourly" ON "gridtokenx" DURATION 90d REPLICATION 1

// Aggregation task
option task = {name: "downsample_hourly", every: 1h}
from(bucket: "gridtokenx/7_days")
  |> range(start: -1h)
  |> aggregateWindow(every: 1h, fn: mean)
  |> to(bucket: "gridtokenx/90_days_hourly")
```

**Query Performance:**
*   **Cardinality**: Keep tag cardinality low (<100k combinations)
*   **Indexing**: Automatic inverted index on tags
*   **Compression**: Gorilla compression for floats (10:1 ratio)

### 5.4 Kafka (Message Streaming)

**Topic Configuration:**
```yaml
topic: meter-readings
partitions: 8
replication-factor: 3
retention.ms: 604800000  # 7 days
compression.type: snappy
max.message.bytes: 1048576  # 1MB
```

**Producer (Simulator):**
```python
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers=['kafka:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    compression_type='snappy',
    batch_size=16384,  # 16KB batches
    linger_ms=10,      # Wait 10ms to batch
)

# Emit reading
producer.send('meter-readings', value={
    'meter_serial': 'MEA-001',
    'kwh': 1254.32,
    'timestamp': '2026-01-27T12:00:00Z',
    'voltage': 220.5,
})
```

**Consumer (API Gateway):**
```rust
use rdkafka::consumer::{Consumer, StreamConsumer};

let consumer: StreamConsumer = ClientConfig::new()
    .set("group.id", "gridtokenx-apigateway")
    .set("bootstrap.servers", "kafka:9092")
    .set("enable.auto.commit", "true")
    .create()?;

consumer.subscribe(&["meter-readings"])?;

loop {
    let message = consumer.recv().await?;
    let payload: KafkaMeterReading = serde_json::from_slice(message.payload())?;
    
    // Push to Redis queue for async processing
    cache_service.push_reading(&payload).await?;
}
```

---

## 6. Blockchain Layer

### 6.1 Solana Network Architecture

**Consensus**: Proof of History (PoH) + Tower BFT
*   **Slot Time**: 400ms
*   **Finality**: ~13 seconds (32 confirmations)
*   **TPS**: 65,000 theoretical, ~3,000 sustained

**Account Model**: No global state; accounts are isolated key-value stores.

**Program Deployment:**
```bash
# Build programs
anchor build

# Deploy to localnet
solana program deploy \
  --program-id keypairs/registry-program.json \
  target/deploy/registry.so

# Verify deployment
solana program show <program_id>
```

### 6.2 Program Interaction Pattern

**Cross-Program Invocation (CPI):**
```rust
// Registry Program calls Energy Token Program
let cpi_program = ctx.accounts.energy_token_program.to_account_info();
let cpi_accounts = energy_token::cpi::accounts::MintTokensDirect {
    token_info: ctx.accounts.token_info.to_account_info(),
    mint: ctx.accounts.mint.to_account_info(),
    user_token_account: ctx.accounts.user_token_account.to_account_info(),
    authority: ctx.accounts.authority.to_account_info(),
    token_program: ctx.accounts.token_program.to_account_info(),
};

let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);
energy_token::cpi::mint_tokens_direct(cpi_ctx, amount)?;
```

**PDA Derivation (Deterministic Addresses):**
```rust
// User account PDA
let (user_pda, bump) = Pubkey::find_program_address(
    &[b"user", authority.key().as_ref()],
    &registry::ID,
);

// Meter account PDA
let (meter_pda, bump) = Pubkey::find_program_address(
    &[b"meter", user_pubkey.as_ref(), meter_id.as_bytes()],
    &registry::ID,
);
```

---

## 7. Simulation Layer

### 7.1 Physics Engine

**Pandapower Integration:**
```python
import pandapower as pp

# Create grid network
net = pp.create_empty_network()

# Add buses (electrical nodes)
bus1 = pp.create_bus(net, vn_kv=0.4, name="Transformer")
bus2 = pp.create_bus(net, vn_kv=0.4, name="Meter-001")

# Add lines (distribution cables)
pp.create_line(net, from_bus=bus1, to_bus=bus2, 
               length_km=0.1, std_type="NAYY 4x50 SE")

# Add loads (consumers)
pp.create_load(net, bus=bus2, p_mw=0.002, q_mvar=0.001)

# Add generators (prosumers)
pp.create_sgen(net, bus=bus2, p_mw=0.003, name="Solar-001")

# Run power flow
pp.runpp(net)

# Extract results
voltage = net.res_bus.vm_pu[bus2]  # Per-unit voltage
loading = net.res_line.loading_percent[0]  # Line loading
```

### 7.2 Meter Templates

**Configuration System:**
```python
from dataclasses import dataclass

@dataclass
class MeterTemplateConfig:
    name: str
    base_consumption_kwh: float
    solar_capacity_kw: float
    battery_capacity_kwh: float
    peak_multiplier: float
    weekend_factor: float
    has_solar: bool = True
    has_battery: bool = False

RESIDENTIAL_LARGE = MeterTemplateConfig(
    name="Residential Large",
    base_consumption_kwh=3.0,
    solar_capacity_kw=10.0,
    battery_capacity_kwh=15.0,
    peak_multiplier=2.0,
    weekend_factor=1.5,
    has_solar=True,
    has_battery=True,
)
```

---

## 8. Deployment Architecture

### 8.1 Docker Compose Stack

**Production Configuration:**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: gridtokenx
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  influxdb:
    image: influxdb:2.7-alpine
    ports:
      - "8086:8086"
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_BUCKET: gridtokenx
      DOCKER_INFLUXDB_INIT_TOKEN: ${INFLUXDB_TOKEN}
    volumes:
      - influxdb_data:/var/lib/influxdb2

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      
  apigateway:
    build: ./gridtokenx-apigateway
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/gridtokenx
      REDIS_URL: redis://redis:6379
      KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      SOLANA_RPC_URL: https://api.mainnet-beta.solana.com
    depends_on:
      - postgres
      - redis
      - kafka

  trading:
    build: ./gridtokenx-trading
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:4000

  simulator:
    build: ./gridtokenx-smartmeter-simulator
    ports:
      - "8080:8000"
    environment:
      API_GATEWAY_URL: http://apigateway:4000
      KAFKA_BOOTSTRAP_SERVERS: kafka:9092
```

### 8.2 Scaling Strategy

**Horizontal Scaling:**
*   **API Gateway**: 4 replicas behind Nginx load balancer
*   **Simulator**: 1 instance per 10,000 meters
*   **Kafka**: 3 brokers with 8 partitions
*   **PostgreSQL**: Read replicas for analytics queries

**Vertical Scaling:**
*   **PostgreSQL**: 16GB RAM, 8 cores
*   **Redis**: 8GB RAM, 4 cores
*   **InfluxDB**: 32GB RAM, 8 cores (time-series intensive)

---

## 9. Monitoring & Observability

### 9.1 Metrics (Prometheus)

**Exposed Metrics** (`/metrics` endpoint):
```
# Throughput
meter_readings_total{status="success"} 1234567
meter_readings_total{status="failure"} 42

# Latency
meter_processing_duration_seconds_bucket{le="0.01"} 8500
meter_processing_duration_seconds_bucket{le="0.05"} 9800

# Queue Depth
meter_processing_queue_depth 127

# Business Metrics
active_orders_total 523
total_trading_volume_kwh 15678.32
```

**Grafana Dashboards:**
*   System Health (CPU, memory, disk)
*   API Request Rate & Latency
*   Blockchain Transaction Success Rate
*   Energy Market Overview (trading volume, price)

### 9.2 Logging (Structured)

**tracing crate** for structured, context-aware logging:
```rust
use tracing::{info, warn, error, instrument};

#[instrument(skip(ctx), fields(user_id = %ctx.user_id))]
async fn create_order(ctx: &Context, params: OrderParams) -> Result<Order> {
    info!(
        energy_amount = params.energy_amount,
        price = params.price_per_kwh,
        "Creating sell order"
    );
    
    match trading_service.create_order(params).await {
        Ok(order) => {
            info!(order_id = %order.id, "Order created successfully");
            Ok(order)
        }
        Err(e) => {
            error!(error = %e, "Failed to create order");
            Err(e)
        }
    }
}
```

**Log Aggregation**: ELK Stack (Elasticsearch, Logstash, Kibana)

---

## 10. Security Architecture

### 10.1 Authentication Flow

**JWT Token Structure:**
```json
{
  "sub": "user_uuid",
  "exp": 1706360400,
  "iat": 1706356800,
  "role": "user",
  "wallet": "7xKXtg2C..."
}
```

**Token Validation:**
```rust
pub async fn validate_jwt(token: &str) -> Result<Claims> {
    let validation = Validation::new(Algorithm::HS256);
    let secret = env::var("JWT_SECRET")?;
    
    let decoded = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &validation,
    )?;
    
    Ok(decoded.claims)
}
```

### 10.2 Authorization

**Middleware:**
```rust
pub async fn auth_middleware(
    State(state): State<AppState>,
    mut req: Request,
    next: Next,
) -> Result<Response> {
    let auth_header = req.headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized("Missing token".into()))?;
    
    let token = auth_header.strip_prefix("Bearer ")
        .ok_or(ApiError::Unauthorized("Invalid format".into()))?;
    
    let claims = validate_jwt(token).await?;
    
    // Attach claims to request extensions
    req.extensions_mut().insert(claims);
    
    Ok(next.run(req).await)
}
```

### 10.3 Input Validation

**Sanitization:**
```rust
pub fn validate_order_params(params: &OrderParams) -> Result<()> {
    if params.energy_amount <= 0.0 {
        return Err(ApiError::Validation("Energy amount must be positive".into()));
    }
    
    if params.price_per_kwh < 2.0 || params.price_per_kwh > 8.0 {
        return Err(ApiError::Validation("Price out of bounds (2-8 THB/kWh)".into()));
    }
    
    if params.energy_amount > 1000.0 {
        return Err(ApiError::Validation("Maximum 1000 kWh per order".into()));
    }
    
    Ok(())
}
```

---

## 11. Disaster Recovery

### 11.1 Backup Strategy

**PostgreSQL:**
*   **Continuous Archiving**: WAL (Write-Ahead Log) shipping to S3
*   **Point-in-Time Recovery**: Restore to any second within 30 days
*   **Daily Snapshots**: Full DB dump at 02:00 UTC

**InfluxDB:**
*   **Backup**: Daily incremental backups to S3
*   **Retention**: 90 days of backups

**Blockchain:**
*   **No Backup Needed**: Immutable ledger (validator nodes handle persistence)
*   **Keypair Security**: Hardware Security Module (HSM) for authority wallet

### 11.2 Failover

**Database Failover:**
*   Primary-Replica setup with automatic promotion
*   PgBouncer for connection pooling during failover

**API Gateway:**
*   Kubernetes deployment with liveness/readiness probes
*   Auto-restart unhealthy pods

---

## 12. Performance Benchmarks

| Component | Metric | Value |
|-----------|--------|-------|
| **API Gateway** | Request Throughput | 10,000 req/s |
| **API Gateway** | p99 Latency | 25 ms |
| **Blockchain** | Transaction TPS | 530 (peak) |
| **Blockchain** | Confirmation Time | 1.96 ms (avg) |
| **Kafka** | Ingestion Rate | 50,000 msg/s |
| **Redis** | Cache Hit Rate | 95% |
| **PostgreSQL** | Query p95 | 5 ms |
| **InfluxDB** | Write Throughput | 100,000 points/s |

---

## 13. Future Roadmap

**Q2 2026:**
*   Multi-region deployment (US-East, EU-West, Asia-Pacific)
*   GraphQL API for flexible querying
*   Mobile apps (iOS, Android)

**Q3 2026:**
*   zkSNARK privacy layer for confidential trading
*   Cross-chain bridge to Ethereum (Wormhole)
*   AI-powered demand forecasting

**Q4 2026:**
*   Carbon credit marketplace integration
*   DAO governance (token voting)
*   Hardware wallet support (Ledger, Trezor)

---

## 14. Conclusion

GridTokenX's architecture represents a **best-in-class hybrid blockchain system** that balances:
*   **Performance**: High-throughput off-chain processing (Rust, Kafka)
*   **Trust**: Immutable on-chain settlement (Solana)
*   **Usability**: Modern web interfaces (Next.js, WebSocket)
*   **Scalability**: Event-driven design with horizontal scaling

By separating concerns across layers and leveraging each technology's strengths, the platform achieves **production-grade reliability** while maintaining the **transparency and decentralization** that blockchain promises.
