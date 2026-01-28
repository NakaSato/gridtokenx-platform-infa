# System Architecture & Design Framework
## GridTokenX Platform

---

## 1. Executive Summary

**GridTokenX** is a blockchain-powered Peer-to-Peer (P2P) energy trading platform built on the **Solana** blockchain. 

It acts as a bridge between physical energy infrastructure and decentralized finance (DeFi), enabling:
*   Real-time energy telemetry streaming.
*   Trustless market settlement via Smart Contracts.
*   High-concurrency data orchestration for grid management.

---

## 2. High-Level Architecture Overview

The platform is designed as a **Hybrid Architecture** combining:
1.  **Off-Chain Orchestration**: High-performance Rust backend for data aggregation, telemetry, and API management.
2.  **On-Chain Settlement**: Solana Anchor programs for immutable state, atomic changes, and value transfer.
3.  **Client Interfaces**: Next.js web applications for users and administrators.

---

## 3. Frontend Layer (User Experience)

**Framework**: Next.js / React
**Role**: Provides the interface for Prosumers (Producers/Consumers) and Admins.

### Key Components:
*   **Trading Dashboard**: Real-time energy trading UI.
*   **Wallet Adapter**: Integration with Solana wallets (Phantom, Solflare) for transaction signing.
*   **Visualization**: Mapbox GL for geospatial grid topology.

### Protocols:
*   **HTTP/WebSocket**: Communication with API Gateway.
*   **JSON RPC / WSS**: Direct interaction with Solana L1 RPC nodes for state queries.

---

## 4. Backend Layer (Service Orchestration)

**Framework**: Rust (Axum)
**Role**: Central orchestration, high-concurrency request handling, and business logic.

### Core Services:
*   **API Gateway**: The central nervous system handling business logic.
*   **Storage**: 
    *   **PostgreSQL**: Relational data (User profiles, static meter data).
    *   **Redis**: High-speed caching and session management.
    *   **InfluxDB**: Time-series database for handling massive energy reading logs.
*   **Streaming**: 
    *   **Kafka**: Message broker for decoupled, high-throughput meter telemetry.

---

## 5. Blockchain Layer (Decentralized Infrastructure)

**Framework**: Solana (Anchor Framework)
**Role**: Trustless settlement and digital identity.

### Smart Contracts (Programs):
*   **Registry Program**: Manages Program Derived Addresses (PDAs) to link database IDs to blockchain accounts deterministically.
*   **Trading Program**: Implements the Market Escrow and Atomic Matching Engine for P2P settlement.
*   **SPL Token Program**: Standard implementation for minting and transferring energy tokens (GXT) and stablecoins (USDC).

### Integrations:
*   **Pyth Network**: Oracles for cross-currency energy valuation and real-time feeds.

---

## 6. Data & Simulator Layer

**Framework**: Python (FastAPI)
**Role**: Generates high-fidelity simulated grid telemetry to mirror real-world scenarios.

### Workflow:
1.  **Generation**: Simulator generates energy readings.
2.  **Ingestion**: Readings are emitted to **Kafka** topics.
3.  **Persistence**: Metrics written to **InfluxDB** for analytics.
4.  **Persistance**: Configuration stored in **PostgreSQL**.
5.  **Control**: Controlled via the **API Gateway** (Rust).

---

## 7. Key Design Principles

*   **Sovereignty**: Critical settlement logic lives on-chain; user funds are never held by the backend.
*   **Scalability**: Heavy data lifting (telemetry) is handled off-chain via Kafka/Rust, while value transfer happens on Solana's high-speed L1.
*   **Determinism**: Use of PDAs ensures a mathematical link between Web2 identities and Web3 accounts without centralized mapping tables.
*   **Interoperability**: Standardized interfaces (SPL Token, JSON RPC) allow easy integration with the broader Solana ecosystem.

---

## 8. Technology Stack Summary

| Layer | Technologies |
|-------|--------------|
| **Frontend** | Next.js, React, TailwindCSS, Mapbox |
| **Backend** | Rust, Axum, Tokio |
| **Data** | PostgreSQL, Redis, InfluxDB, Kafka |
| **Blockchain** | Solana, Anchor, SPL Token, Pyth |
| **Simulation** | Python, FastAPI, Pandas |
| **Infrastructure** | Docker Compose |
