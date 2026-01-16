4. gridtokenx-anchor (Solana Smart Contracts)
The on-chain business logic layer.

Solana Protocol (Sealevel):
Role: The execution environment for all "backend" logic on-chain.
SPL Token Standard:
Role: The standard protocol for fungible tokens (Energy Tokens, USDC).
Implementation: Interacted via anchor-spl.
Anchor IDL (Interface Description Language):
Role: JSON-based protocol for defining program interfaces, enabling the frontend/backend to know how to serialize instructions.

#### MAIN
1. gridtokenx-apigateway (Rust)
HTTP/1.1 & HTTP/2: Core API transport via axum and hyper (server) and reqwest (client).
WebSocket: Real-time streaming for trading data via axum.
PostgreSQL Wire Protocol: Database communication via sqlx.
Redis serialization protocol (RESP): Caching and pub/sub messaging via redis.
Solana JSON RPC: Blockchain interaction via solana-client.
Prometheus: Metrics exposition via metrics-exporter-prometheus.
SMTP: Email delivery via lettre.

2. gridtokenx-trading (Frontend)
HTTPS: Client-server communication (SSR/CSR).
Solana JSON RPC & WebSocket: Direct blockchain connection via @solana/web3.js (account subscriptions, transaction submission).
Wallet Standard: Communication between dApp and browser wallets (Phantom, Solflare) via @solana/wallet-adapter.
Pyth Network Protocol: Real-time oracle price feeds via @pythnetwork/client.
Mapbox Vector Tiles: Grid topology rendering via mapbox-gl.

3. gridtokenx-smartmeter-simulator (Python)
HTTP: Simulator control API via fastapi / uvicorn.
Kafka Protocol: High-throughput event streaming for meter readings via kafka-python.
InfluxDB Line Protocol: Time-series metric ingestion via influxdb-client.
WebSocket: Real-time simulated data streaming via websockets.
PostgreSQL: State persistence via psycopg2.

4. gridtokenx-anchor (Smart Contracts)
Solana Sealevel: On-chain execution environment transaction format.
Anchor IDL (Interface Description Language): JSON-based protocol for program interface definition.
CPI (Cross-Program Invocation): Protocol for internal contract-to-contract calls.