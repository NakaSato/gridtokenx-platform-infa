# GridTokenX: Core Project Specifications
**Senior Computer Engineering Project | Technical Summary**

## 1. Executive Summary
GridTokenX is a high-fidelity, blockchain-based Decentralized Energy Exchange (DEX). It enables prosumers (producers + consumers) to trade surplus renewable energy directly with neighbors in a trustless environment, bypassing traditional centralized utility inefficiencies.

## 2. Primary Objective
To engineer a scalable, tri-layered infrastructure that facilitates **Atomic Energy Settlement** using real-time IoT telemetry and high-performance blockchain consensus.

## 3. Technology Stack (The Trinity)
- **Consensus Layer**: **Solana (Anchor Framework)** - Chosen for 65,000+ TPS potential and low transaction finality.
- **Middleware Layer**: **Rust (Axum/Tokio)** - An asynchronous API Gateway that manages the P2P order book and abstracts blockchain complexity.
- **Edge Layer**: **Smart Meter Simulator (Node.js)** - A high-fidelity "Digital Twin" generator that models real-world energy generation/consumption curves.

## 4. Key Engineering Components
- **The Oracle**: Bridges physical meter readings to on-chain state.
- **Landed Cost Engine**: A matching algorithm that calculates `Base Price + Zonal Fees + Transmission Loss`.
- **Identity Registry**: Uses Program Derived Addresses (PDAs) for deterministic, secure identity management of meters.
- **Escrow Orchestrator**: Manages a dual-lock system (Postgres cache + On-chain SPL transfer) to prevent double-spending.

## 5. Performance & Validation Metrics
- **Test Coverage**: 100% pass rate for 16 core business scenarios (Registration -> Ingestion -> Settlement).
- **Matching Latency**: Sub-millisecond matching cycles in the Rust middleware.
- **Concurrency**: Optimized for thousands of simultaneous IoT telemetry streams via Tokio's multi-threaded runtime.

## 6. Project Milestones (Mid-Term)
- [x] All 7 Anchor programs deployed to localnet.
- [x] Functional P2P matching engine with zonal cost calculation.
- [x] Automated REC (Renewable Energy Certificate) issuance upon settlement.
- [x] Digital Twin simulator integrated with on-chain Oracle.
