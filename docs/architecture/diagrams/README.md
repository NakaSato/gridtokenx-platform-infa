# Architecture Diagrams

This directory contains all visual diagrams for the GridTokenX platform architecture.

---

## 📊 Diagram Index

### Backend Architecture

| Diagram | Files | Description |
|---------|-------|-------------|
| **Backend Architecture** | [`puml`](./architecture_backend.puml) · [`png`](./architecture_backend.png) | API Gateway, databases, microservices |
| **Protocol Layers** | [`puml`](./architecture_protocols.puml) · [`png`](./architecture_protocols.png) | HTTP, WebSocket, Solana protocol stack |
| **Protocol Details** | [`puml`](./architecture_protocols_detailed.puml) · [`png`](./architecture_protocols_detailed.png) | Detailed protocol interactions |

### Blockchain Architecture

| Diagram | Files | Description |
|---------|-------|-------------|
| **Blockchain Architecture** | [`puml`](./architecture_blockchain.puml) · [`png`](./architecture_blockchain.png) | Solana programs, PDAs, and accounts |
| **On-Chain Minting** | [`puml`](./on_chain_minting.puml) · [`png`](./on_chain_minting.png) | Token minting flow on-chain |
| **Anchor Minting** | [`puml`](./anchor_minting.puml) · [`png`](./anchor_minting.png) | Anchor program minting instructions |
| **Core Minting Program** | [`puml`](./core_minting_program.puml) · [`png`](./core_minting_program.png) · [`svg`](./core_minting_program.svg) | Core minting logic |

### Frontend Architecture

| Diagram | Files | Description |
|---------|-------|-------------|
| **Frontend Architecture** | [`puml`](./architecture_frontend.puml) · [`png`](./architecture_frontend.png) | Next.js apps and UI components |

### Trading & Settlement

| Diagram | Files | Description |
|---------|-------|-------------|
| **Matching Engine** | [`puml`](./matching_engine_trading.puml) · [`png`](./matching_engine_trading.png) | Order matching engine design |
| **Atomic Settlement** | [`puml`](./atomic_settlement.puml) · [`png`](./atomic_settlement.png) | Atomic settlement sequence |
| **Atomic Settlement Detail** | [`puml`](./atomic_settlement_sequence.puml) · [`png`](./atomic_settlement_sequence.png) | Detailed settlement steps |

### Simulator & IoT

| Diagram | Files | Description |
|---------|-------|-------------|
| **Simulator Architecture** | [`puml`](./architecture_simulator.puml) · [`png`](./architecture_simulator.png) | Smart meter simulator design |
| **Preprocessing** | [`puml`](./preprocessing_methodology.puml) · [`png`](./preprocessing_methodology.png) | Data preprocessing pipeline |

### System Context & User Flows

| Diagram | Files | Description |
|---------|-------|-------------|
| **System Context** | [`puml`](./system_context.puml) · [`png`](./system_context.png) | High-level system context diagram |
| **Full System Flow** | [`puml`](./full_system_flow.puml) · [`png`](./full_system_flow.png) · [`svg`](./full_system_flow.svg) | Complete system flow |
| **Energy Minting Lifecycle** | [`puml`](./energy_minting_lifecycle.puml) · [`png`](./energy_minting_lifecycle.png) · [`svg`](./energy_minting_lifecycle.svg) | Energy token lifecycle |
| **User Web2↔Web3 Connection** | [`puml`](./user_web2_web3_connection.puml) · [`png`](./user_web2_web3_connection.png) | Web2 to Web3 identity bridge |
| **Wallet Address Connection** | [`puml`](./wallet_address_connection.puml) · [`png`](./wallet_address_connection.png) | Wallet address derivation |

---

## 🎨 Diagram Types

### Source Files (`.puml`)
PlantUML source files that can be edited and regenerated. Requires PlantUML to render.

### Rendered Images
- **PNG** (`.png`) - Optimized for web viewing and documentation
- **SVG** (`.svg`) - Scalable vector graphics for high-quality rendering (available for select diagrams)

---

## 🔧 Editing Diagrams

1. Install PlantUML: `brew install plantuml`
2. Edit the `.puml` file
3. Regenerate: `plantuml -tpng *.puml`
4. Commit both source and rendered files

---

## 📐 Diagram Conventions

- **Colors**: Use consistent color scheme for different layers
  - Blue: Backend services
  - Green: Blockchain/Solana
  - Orange: Frontend/UI
  - Gray: External systems

- **Notation**: Follow C4 model where applicable
  - Level 1: System Context
  - Level 2: Container
  - Level 3: Component

- **Naming**: Use descriptive, consistent naming for components
  - Services: `api-gateway`, `iam-service`, `trading-service`
  - Programs: `Registry`, `Energy Token`, `Trading`
  - Databases: `PostgreSQL`, `Redis`, `InfluxDB`

---

**Last Updated:** April 6, 2026
