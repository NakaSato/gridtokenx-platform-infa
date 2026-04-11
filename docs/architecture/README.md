# GridTokenX Architecture Index

**Version**: 2.2 (Microservices)  
**Last Updated**: April 10, 2026  
**Status**: ✅ Production Ready

Welcome to the internal technical documentation for the GridTokenX Platform. This index serves as a guide to the various specifications, models, and workflows that define our decentralized energy trading ecosystem.

---

## 1. Core Platform Specifications

These documents define the high-level design and underlying technical standards of the GridTokenX ecosystem.

*   [**Platform Design (Source of Truth)**](../PLATFORM_DESIGN.md)  
    The primary entry point for understanding the Dual-Platform strategy (Exchange & Infrastructure) and high-level service orchestration.
*   [**System Architecture Overview**](./specs/system-architecture.md)  
    Detailed technical specification of microservices, ports, and container orchestration.
*   [**Blockchain Architecture**](./specs/blockchain-architecture.md)  
    The Solana-based settlement layer, tri-token model, and accounts sharding strategy.
*   [**Secure Telemetry Pipeline**](./specs/system-architecture.md#6-secure-telemetry-pipeline)  
    The end-to-end cryptographic trust chain from Edge Meter to Blockchain.

---

## 2. Microservice Architecture

Detailed technical guides for each independent service within the GridTokenX ecosystem.

*   [**IAM Service Architecture**](./services/IAM_SERVICE_ARCHITECTURE.md)  
    Identity management, Ed25519 wallet encryption, KYC, and Registry Program interactions.
*   [**Trading Service Architecture**](./services/TRADING_SERVICE_ARCHITECTURE.md)  
    Matching engine (CDA/Batch), Order Book logic, and atomic on-chain settlement.
*   [**Oracle Bridge Architecture**](./services/ORACLE_BRIDGE_ARCHITECTURE.md)  
    IoT ingestion, zone-based shard partitioning, and cryptographic validation.
*   [**Grid Protocol Integration Guide**](./services/ORACLE_BRIDGE_GRID_PROTOCOL.md)  
    Trust tier model, multi-domain protocol mappings (AMI/V2G/ESS), and energy balance reconciliation.
*   [**API Services (Orchestrator)**](./specs/system-architecture.md#3-container-diagram-c4-level-2)  
    ConnectRPC orchestration, Kafka event sinking, and real-time frontend broadcasting.

---

## 3. Integration & Workflows

Step-by-step guides for common cross-service operations.

*   [**P2P Trading Lifecycle**](./guides/p2p-trading-flow.md)  
    The end-to-end path from order creation to matched settlement.
*   [**User Registration Flow**](./guides/user-registration-workflow.md)  
    IAM onboarding, wallet generation, and meter registration.
*   [**Telemetry Provenance Flow**](./guides/data-flow-simulator-to-blockchain.md)  
    The journey of a single energy reading from the Edge to a Minted Token.
*   [**Hybrid Messaging Strategy**](./messaging/HYBRID_MESSAGING_ARCHITECTURE.md)  
    How we use Kafka, RabbitMQ, and Redis to achieve high-throughput, reliable messaging.

---

## 4. Economic & Governance Models

The underlying logic for tokens, fees, and community participation.

*   [**Tri-Token Economic Model**](./economic-models/km-blockchain-core.md)  
    Economic utility of GRX, GRID, and REC tokens.
*   [**Governance & DAO**](./specs/smart-contract-architecture.md)  
    On-chain proposal and voting mechanisms.

---

## 5. Performance & Reliability

*   [**Observability & Monitoring**](./specs/system-architecture.md#9-monitoring--observability)  
    Grafana stacks, alerting thresholds, and distributed tracing.
*   [**Platform Targets**](./specs/system-architecture.md#5-technology-stack)  
    Latency, throughput, and scalability benchmarks.

---

**Last Reviewed**: April 10, 2026  
**Point of Contact**: Engineering Architecture Team
