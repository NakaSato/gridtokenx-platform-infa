# 📈 Trading Service Architecture

**Service Name**: `gridtokenx-trading-service`  
**Port**: `50053` (gRPC) / `8092-8093` (Market Data)  
**Version**: 2.2  
**Status**: ✅ Production Ready

---

## 1. Overview

The **Trading Service** is the high-performance engine of the GridTokenX Platform. It manages market liquidity, matches buy and sell orders in real-time or batches, and executes the final on-chain settlement that transfers energy tokens (GRID) and stablecoin payments.

---

## 2. Core Responsibilities

1.  **Order Book Management**: Maintains thread-safe, in-memory price-time priority queues for all energy pairs.
2.  **Matching Engine**:
    -   **CDA (Continuous Double Auction)**: Immediate matching for low-latency P2P trades.
    -   **Batch Clearing**: Uniform price clearing for high-volume 15-minute energy windows.
3.  **Escrow Management**: Interacts with the **Trading Program** to lock funds during the order lifecycle.
4.  **On-chain Settlement**: Executes atomic transactions that finalize trades and distribute revenue shares (50/30/20 model).
5.  **Market Data Feed**: Publishes trade, ticker, and candle events to Kafka for real-time broadcasting via the API Gateway.

---

## 3. Technical Stack

-   **Framework**: Rust (Tonic for gRPC)
-   **Matching Core**: Proprietary In-memory Engine (Lock-free/Concurrent)
-   **Caching**: Redis 7 (Snapshotting, Locking, and State Recovery)
-   **Blockchain**: `solana-sdk`, `anchor-client` (Trading & Energy Programs)
-   **Analytics**: InfluxDB (OHLCV Candles & Time-series depth)

---

## 4. Blockchain Interactions

The Trading Service owns the **Trading Program** (`69dGp...8na`) and **Energy Token Program** (`n52aK...BGk`).

### Principal PDAs (Program-Derived Addresses)
-   **Market**: `["market", market_name]` - Configuration for fees, shards, and assets.
-   **Order**: `["order", user_pubkey, order_id]` - On-chain record of an active order.
-   **Escrow**: `["escrow", market_pda]` - Vault holding tokens awaiting matching.

### Settlement Logic (50-30-20 Model)
When a match is found, the service calculates the **1.0% Protocol Fee** and distributes it:
-   **50%**: Staking Yield (Distributed to GRX stakers).
-   **30%**: Platform Treasury (Operations & Insurance).
-   **20%**: Buyback & Burn (Deflationary buy-and-burn of GRX).

---

## 5. gRPC API Reference

### `TradingService`
-   `CreateOrder(OrderRequest) -> OrderResponse`: Submits a new limit or market order.
-   `CancelOrder(CancelRequest) -> CommonResponse`: Removes an order from the book and releases escrow.
-   `GetOrderBook(BookRequest) -> BookResponse`: Returns the current bid/ask levels.
-   `SubmitSettlement(SettlementRequest) -> SettlementResponse`: Authorizes on-chain settlement for an Oracle-signed window.

---

## 6. Scalability Model

1.  **Market Sharding**: Trading pairs and geographic zones are partitioned across separate engine instances to scale horizontally.
2.  **Redis Recovery**: Every trade is mirrored to Redis immediately, allowing the engine to recover state in < 1 second after a restart.
3.  **ConnectRPC Pooling**: High-throughput order submission via persistent HTTP/2 connection pooling from the API Gateway.

---

## Related Documentation
-   [Platform Design](../../PLATFORM_DESIGN.md)
-   [Blockchain Architecture](../specs/blockchain-architecture.md)
-   [System Architecture](../specs/system-architecture.md)
