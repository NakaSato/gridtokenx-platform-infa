# GridTokenX — Oracle-Bridge Grid Protocol Integration Guide

**Service Name**: `gridtokenx-oracle-bridge`  
**Version**: 2.2  
**Last Updated**: April 10, 2026  
**Status**: 🔬 Design Specification (Phase 1 In Progress)

> **Related Documentation:**
> - [Oracle Bridge Architecture](./ORACLE_BRIDGE_ARCHITECTURE.md) - Core service design
> - [Smart Contract Architecture](../specs/smart-contract-architecture.md) - Oracle Program specification
> - [System Architecture](../specs/system-architecture.md) - Platform-wide integration context
> - [Security Analysis](../../academic/07-security-analysis.md) - Threat model and defenses
> - [Platform Algorithms](../../academic/ALGORITHMS.md) - Oracle validation algorithms

---

## 1. Overview

The oracle-bridge serves as the trust boundary between GridTokenX's blockchain settlement layer and the operational technology (OT) ecosystem of Thailand's power grid. As the platform scales beyond peer-to-peer prosumer trading into integration with PEA's existing grid management infrastructure, the oracle-bridge must interface with seven distinct grid domains, each governed by different protocols, data semantics, trust models, and timing requirements.

This document defines the integration architecture, protocol mappings, validation rules, and trust tiers for each domain. The guiding principle is that **only utility-grade, cryptographically signed metering data at the grid connection point may trigger GRID token minting**. All other grid data serves as pricing context, validation constraint, or informational input — never as a minting authority.

---

## 2. Trust Tier Model

Every data source entering the oracle-bridge is classified into one of three trust tiers. The tier determines what the oracle-bridge is permitted to do with the data.

**Tier 1 — Authoritative (minting authority).** Data from this tier directly triggers `mint_grid` on the Oracle Program. Sources must be utility-grade metering devices with Ed25519 hardware signing, temporal monotonicity, and physical plausibility validation. Only three source types qualify: AMI grid meters, microgrid PCC meters, and V2G session meters.

**Tier 2 — Contextual (pricing and validation).** Data from this tier informs the trading engine's price signals, constrains the oracle-bridge's validation rules, and feeds the energy balance reconciliation engine. Sources include demand response signals, substation topology/status, and ESS state-of-charge. Tier 2 data is validated and persisted but never triggers minting.

**Tier 3 — Informational (UX and forecasting).** Data from this tier feeds prosumer dashboards, demand forecasting models, and platform analytics. Sources include HEMS appliance telemetry, weather/irradiance data, and EV charging session metadata. Tier 3 data bypasses the oracle-bridge entirely and flows directly to the frontend and InfluxDB via Kafka.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          TRUST TIER DATA FLOW                               │
│                                                                             │
│  Tier 1 (Authoritative)           Tier 2 (Contextual)    Tier 3 (Info)     │
│  ┌──────────┐ ┌──────┐ ┌────┐   ┌────┐ ┌────┐ ┌────┐   ┌────┐ ┌────┐    │
│  │AMI Meter │ │PCC   │ │V2G │   │ DR │ │Sub │ │ESS │   │HEMS│ │Wx  │    │
│  └────┬─────┘ └──┬───┘ └─┬──┘   └─┬──┘ └─┬──┘ └─┬──┘   └─┬──┘ └─┬──┘    │
│       │          │       │        │      │      │        │      │         │
│       ▼          ▼       ▼        ▼      ▼      ▼        │      │         │
│  ┌──────────────────────────────────────────────────┐     │      │         │
│  │              Oracle Bridge                       │     │      │         │
│  │  ┌──────────────────┐  ┌──────────────────────┐  │     │      │         │
│  │  │  Domain Adapters  │  │  Validation Core     │  │     │      │         │
│  │  │  (Layer 1)        │→│  (Layer 2)            │  │     │      │         │
│  │  └──────────────────┘  └─────────┬────────────┘  │     │      │         │
│  │                                  │               │     │      │         │
│  │  ┌──────────────────────────────┐│               │     │      │         │
│  │  │  On-Chain Committer (Layer 3)││               │     │      │         │
│  │  │  mint_grid / submit_reading  ││               │     │      │         │
│  │  └──────────────┬───────────────┘│               │     │      │         │
│  └─────────────────│────────────────┘               │      │         │
│                    │                                 │      │         │
│                    ▼                                 ▼      ▼         │
│  ┌──────────────────────┐  ┌──────────────────────────────────────┐  │
│  │  Solana Blockchain   │  │  Kafka → InfluxDB / Frontend        │  │
│  │  (Oracle Program)    │  │  (Persistence & Visualization)      │  │
│  └──────────────────────┘  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Tier 1 — Authoritative Sources

### 3.1 AMI (Advanced Metering Infrastructure)

**Protocol stack:**
DLMS/COSEM (IEC 62056) is the primary metering protocol. PEA's AMI deployment uses CyanConnode Omnimesh as the RF mesh communication layer between meters and data concentrators (DCUs). The DCU aggregates readings from up to 200 meters per 15-minute interval and forwards them to the AMI head-end system via KEPCO-style proprietary framing or RESTful LwM2M.

**Integration path:**
Smart meter → Neuron gateway (DLMS → MQTT) → EMQX broker → Kafka (raw telemetry topic) → oracle-bridge (validation) → Oracle Program (on-chain commitment + mint).

**Key DLMS OBIS codes for settlement:**

| OBIS Code | Description | Settlement Role |
|---|---|---|
| 1.0.1.8.0 | Active energy import (cumulative) | Consumer consumption |
| 1.0.2.8.0 | Active energy export (cumulative) | Prosumer generation (minting basis) |
| 1.0.3.8.0 | Reactive energy import | Power quality validation |
| 1.0.4.8.0 | Reactive energy export | Power quality validation |
| 1.0.1.7.0 | Active power import (instantaneous) | Real-time dashboard |
| 1.0.2.7.0 | Active power export (instantaneous) | Real-time dashboard |
| 0.0.1.0.0 | Billing period reset timestamp | Interval boundary alignment |

**Validation rules:**
- Ed25519 signature verification against the meter's registered public key in the Registry Program.
- Temporal monotonicity: each reading's timestamp must be strictly greater than the previous accepted reading for that meter ID.
- Physical ceiling: export energy per interval must not exceed the meter's registered panel capacity (kWp) × interval duration (hours) × 1.15 (tolerance for irradiance peaks).
- Rate-of-change bound: delta between consecutive intervals must not exceed 3× the rolling 24-hour average delta for that meter. Violations are flagged for manual review, not auto-rejected.
- Interval alignment: readings must fall on 15-minute boundaries (±30 seconds). Misaligned readings are interpolated to the nearest boundary using linear interpolation and flagged as estimated.

**PEA VEE reconciliation:**
PEA's MDM system performs Validation, Estimation, and Editing (VEE) on interval data before publishing to downstream systems. If GridTokenX receives both a raw Neuron reading and a VEE-processed reading from PEA's MDM for the same meter and interval, the oracle-bridge applies the following precedence:
1. If both readings agree within 1% tolerance → use the raw Neuron reading (higher trust, Ed25519 signed).
2. If readings disagree by 1–5% → use the PEA VEE reading (benefit of utility-grade estimation) and flag the raw reading for audit.
3. If readings disagree by >5% → reject both, pause minting for that meter, and alert the platform operator. This delta likely indicates a meter fault, Neuron firmware bug, or VEE estimation failure.

### 3.2 Microgrid PCC Metering

**Protocol stack:**
Microgrid controllers (Schneider EcoStruxure, ABB MGMS, Siemens SICAM) communicate via IEC 61850 MMS for protection and monitoring, and Modbus TCP for energy management system (EMS) data exchange. The PCC meter is typically a high-accuracy revenue-grade meter (class 0.2S per IEC 62053) with its own DLMS interface.

**Integration path:**
PCC meter → Neuron gateway (DLMS or Modbus → MQTT) → EMQX → Kafka → oracle-bridge → Oracle Program.

**Critical design rule — PCC as settlement boundary:**
Individual prosumer meters within a microgrid report generation and consumption, but these readings may not reflect actual grid exchange. The microgrid controller may have curtailed generation, discharged local storage, or shifted loads. The PCC meter measures what actually crossed the grid boundary. For GRID token minting:
- Net export at the PCC is the total minting authority for the microgrid.
- Individual prosumer readings within the microgrid are used only for internal allocation (proportional split of PCC export based on each prosumer's contribution).
- If the sum of individual prosumer exports exceeds PCC export, the oracle-bridge scales down individual allocations proportionally. Tokens are never minted for energy that didn't leave the microgrid.

**Validation rules:**
All AMI validation rules apply to the PCC meter, plus:
- Energy balance check: sum of individual prosumer net exports within the microgrid must be ≥ PCC net export (after accounting for microgrid internal losses, typically 2–5%). A delta exceeding 10% triggers a minting pause for the entire microgrid.
- Microgrid islanding detection: if the PCC breaker status (from the microgrid controller via IEC 61850 GOOSE) indicates islanded mode, all minting for that microgrid is paused — energy generated during islanding doesn't reach the main grid.

### 3.3 V2G Discharge Metering

**Protocol stack:**
ISO 15118 governs EV-to-EVSE (charger) communication, including Plug & Charge mutual TLS authentication via contract certificates. OCPP 2.0.1 governs EVSE-to-CSMS (Charging Station Management System) communication, providing session start/stop events, energy metered values, and transaction IDs.

**Integration path:**
EV → EVSE (ISO 15118) → CSMS (OCPP 2.0.1) → Neuron gateway (OCPP WebSocket → MQTT) → EMQX → Kafka → oracle-bridge → Oracle Program.

**Settlement attribution model:**
V2G discharge involves two parties: the EVSE owner (prosumer who hosts the charger) and the EV owner (who owns the energy in the battery). The oracle-bridge must split minting based on a pre-registered agreement:
- The EVSE owner's wallet receives a platform-defined hosting fee (e.g., 10% of minted GRID tokens) for providing grid connection and EVSE infrastructure.
- The EV owner's wallet receives the remainder. The EV owner is identified via the ISO 15118 contract certificate chain, which maps to a wallet address in the Registry Program.
- If the EV owner is not registered in GridTokenX, discharge tokens are held in escrow by the Trading Program until the EV owner registers and claims them (or a configurable timeout returns them to the platform treasury).

**Validation rules:**
- OCPP 2.0.1 `MeterValues` with measurand `Energy.Active.Export.Register` is the minting basis. Signed meter values (OCPP security profile 3) are required; unsigned sessions are rejected.
- Session duration and energy must be physically plausible: a 7 kW EVSE cannot discharge 50 kWh in 30 minutes.
- The oracle-bridge must verify that the EVSE is registered in the Registry Program and that the prosumer's grid connection supports bidirectional flow (not all PEA service points allow export).
- V2G discharge sessions are metered per-session, not per-interval. The oracle-bridge batches completed sessions and submits them to the Oracle Program with the session's total kWh, not individual interval readings.

---

## 4. Tier 2 — Contextual Sources

### 4.1 Demand Response (OpenADR 2.0b)

**Protocol stack:**
OpenADR 2.0b defines VTN (Virtual Top Node, PEA's DR management system) and VEN (Virtual End Node, GridTokenX acting as an aggregator). Communication uses HTTP/XML with EiEvent, EiReport, and EiRegisterParty services.

**Integration path:**
PEA VTN → GridTokenX VEN endpoint (OpenADR HTTP) → EMQX (published as MQTT event) → Kafka (DR event topic) → trading-service (price signal adjustment).

**How DR events affect the oracle-bridge:**
The oracle-bridge does not process DR events directly. Instead:
1. The trading-service receives the DR event and adjusts dynamic pricing (higher buy price during DR events to incentivize export).
2. Prosumers who increase export during the DR window earn GRID tokens at the elevated price through normal trading settlement.
3. DR compliance verification (did prosumers actually reduce/shift load?) is performed by a separate DR compliance engine that compares actual metered consumption against a baseline.

**Baseline calculation methods:**
- **PEA default**: 10-in-10 baseline — average consumption for the same hour across the 10 most recent non-event days. Suitable for residential prosumers.
- **Microgrid adjusted**: baseline calculated at the PCC level, not individual meter level, to account for microgrid-internal optimization.
- **Weather-adjusted**: baseline scaled by a temperature/irradiance ratio (event day vs. baseline days) to correct for weather-driven consumption changes.

**Risk — phantom DR compliance:**
A prosumer who was already planning to reduce consumption (e.g., going on vacation) would appear to comply with a DR event without actually responding. The oracle-bridge mitigates this by not minting bonus tokens for DR compliance — the elevated trading price is the only incentive. Prosumers who would have exported anyway still benefit from higher prices, but there's no double-counting of DR response and normal generation.

### 4.2 Substation Monitoring (IEC 61850 / DNP3)

**Protocol stack:**
IEC 61850 MMS provides structured data from Intelligent Electronic Devices (IEDs) at substations — breaker status (XCBR), transformer loading (MMXU), fault indicators (RFLO), and protection relay events (PTRC). DNP3 provides SCADA polling for legacy substations and distribution automation.

**Integration path:**
Substation IEDs → PEA SCADA master → DNP3 bridge service → Kafka (grid topology topic) → oracle-bridge (constraint engine).

**How substation data constrains the oracle-bridge:**
The oracle-bridge maintains an in-memory grid topology model updated from substation events. This model is used to:
- **Feeder validation**: reject export readings from meters on a de-energized feeder (breaker open). The oracle-bridge maps each meter to its feeder via the Registry Program's grid connection metadata.
- **Congestion pricing**: if transformer loading on a feeder exceeds 80% capacity, the trading-service receives a congestion signal and may curtail new buy orders on that feeder to prevent overloading.
- **Fault isolation**: if an IEC 61850 GOOSE message indicates a protection relay trip on a feeder, the oracle-bridge pauses minting for all meters on that feeder until the fault is cleared and the breaker is reclosed.

**Staleness policy:**
Substation data must carry an explicit timestamp. The oracle-bridge maintains a staleness threshold per data type:
- Breaker status (XCBR): 30-second maximum staleness. If the last breaker status update is older than 30 seconds, the oracle-bridge treats the feeder status as UNKNOWN and defers (does not reject) validation for meters on that feeder.
- Transformer loading (MMXU): 5-minute maximum staleness. Loading data is used for congestion pricing, not minting decisions, so a longer staleness window is acceptable.
- Protection events (PTRC): event-driven, no staleness window. Events are consumed as they arrive and the oracle-bridge reacts immediately.

### 4.3 ESS / Battery Management (Modbus TCP / CAN)

**Protocol stack:**
Residential and commercial battery systems (Tesla Powerwall, BYD Battery-Box, Huawei LUNA, LG RESU) expose state-of-charge (SoC), charge/discharge power, and cumulative energy via Modbus TCP registers or vendor-specific APIs. Industrial BMS communicates via CAN bus. Neuron handles both Modbus TCP and selected vendor APIs.

**Integration path:**
BMS → Neuron gateway (Modbus/API → MQTT) → EMQX → Kafka (ESS telemetry topic) → oracle-bridge (energy balance engine).

**Energy balance reconciliation (anti-double-counting):**
The oracle-bridge maintains a per-device energy balance ledger to prevent the same kWh from being counted twice:

| Event | Grid Meter Sees | Battery SoC Change | Oracle-Bridge Action |
|---|---|---|---|
| Solar → grid (no battery) | Export ↑ | No change | Mint GRID (normal) |
| Solar → battery (charging) | No export | SoC ↑ | No mint (energy didn't reach grid) |
| Battery → grid (discharging) | Export ↑ | SoC ↓ | Mint GRID only if SoC decrease matches export |
| Battery → home (self-consumption) | No export | SoC ↓ | No mint (energy didn't reach grid) |
| Solar → grid + battery simultaneously | Export ↑ | SoC ↑ | Mint only for the export portion |

**Critical rule:** The grid meter (Tier 1 AMI) is always the minting authority. ESS data is used only to explain behind-the-meter behavior and validate that the grid meter's export reading is consistent with the expected energy flows. If ESS data is unavailable or inconsistent, the oracle-bridge falls back to grid-meter-only validation — it never blocks minting due to missing Tier 2 data.

**SoC drift detection:**
Battery SoC sensors degrade over time. The oracle-bridge compares cumulative charge/discharge energy (from Modbus registers) against SoC delta × rated capacity. A persistent drift exceeding 5% over a 7-day window triggers a recalibration alert to the prosumer and flags the ESS data as unreliable for energy balance reconciliation.

---

## 5. Tier 3 — Informational Sources

### 5.1 HEMS (Home Energy Management System)

**Protocol stack:**
ZigBee Smart Energy Profile (SEP) 2.0, ECHONET Lite (prevalent in Japan, emerging in ASEAN), Matter (Thread-based, Google/Apple/Samsung alliance), Wi-Fi direct for inverter monitoring (SolarEdge, Enphase, Fronius APIs).

**Integration path:**
Home appliances → HEMS hub → Cloud API or local MQTT → EMQX → Kafka (HEMS telemetry topic) → InfluxDB + frontend dashboard.

**The oracle-bridge does NOT process HEMS data.** HEMS data bypasses the oracle-bridge entirely and flows directly to persistence and visualization layers. This is a deliberate architectural constraint:
- HEMS devices are consumer-grade, not utility-grade. Sensors are uncalibrated, connections are unreliable, and data formats vary wildly across vendors.
- HEMS data is useful for prosumer dashboards (appliance-level consumption breakdown, self-consumption ratio visualization, optimization recommendations) and demand forecasting (aggregate HEMS data predicts residential load curves).
- If HEMS data were used to infer behind-the-meter behavior for minting decisions, a miscalibrated sensor or a spoofed HEMS device could create phantom export claims.

**Exception — HEMS as Tier 2 (future consideration):**
If a HEMS device is paired with a calibrated CT (Current Transformer) clamp at the main panel and the CT clamp is registered and Ed25519-signed like a smart meter, the CT clamp's data could be elevated to Tier 2 (contextual) for energy balance reconciliation. The HEMS hub itself remains Tier 3. This hybrid model is not implemented in the current architecture but is a viable V2 enhancement.

### 5.2 Weather and Irradiance Data

**Sources:**
Pyth oracle (on-chain price feeds, can include weather derivatives), Thai Meteorological Department (TMD) API, local pyranometer sensors at microgrid sites.

**Integration path:**
TMD API / Pyth → Kafka (weather topic) → InfluxDB + trading-service (forecast model input).

**Usage:**
- Solar generation forecasting: predict next-interval generation for each prosumer based on panel capacity × forecasted irradiance × temperature-adjusted efficiency.
- DR baseline adjustment: weather-normalized baselines for demand response compliance (Section 4.1).
- Rate-of-change validation: the oracle-bridge may optionally cross-reference export spikes against irradiance data. A prosumer reporting 5 kWh export during a cloudy interval (irradiance < 200 W/m²) is flagged for review. This is a soft check, not a hard rejection — irradiance data may be spatially imprecise.

---

## 6. Protocol Compatibility Matrix

| Domain | Primary Protocol | Transport | Neuron Support | EMQX Gateway | Update Freq | Trust Tier |
|---|---|---|---|---|---|---|
| AMI meters | DLMS/COSEM (IEC 62056) | HDLC/TCP, RF mesh | Native | Via Neuron | 15 min | Tier 1 |
| Microgrid PCC | IEC 61850 MMS / Modbus | TCP/IP | Modbus native | Via Neuron | 1 min | Tier 1 |
| V2G session | OCPP 2.0.1 / ISO 15118 | WebSocket / TLS | OCPP via plugin | Via Neuron | Per-session | Tier 1 |
| Demand response | OpenADR 2.0b | HTTP/XML | Custom adapter | HTTP bridge | Event-driven | Tier 2 |
| Substation | IEC 61850 GOOSE / DNP3 | Ethernet / Serial | DNP3 partial | Custom bridge | Real-time | Tier 2 |
| ESS / BMS | Modbus TCP / CAN / API | TCP / CAN bus | Modbus native | Via Neuron | 1–5 min | Tier 2 |
| HEMS | ZigBee SEP / Matter / API | Various | Limited | MQTT native | 5–60 sec | Tier 3 |
| Weather | REST API / Oracle | HTTPS | N/A | N/A | 5–15 min | Tier 3 |

---

## 7. Oracle-Bridge Decomposition Architecture

The monolithic oracle-bridge must evolve into a modular architecture to handle multi-domain integration without coupling protocol-specific logic to the core validation engine.

**Layer 1 — Domain adapters (protocol translation).**
Each grid domain has a dedicated adapter responsible for protocol-specific parsing, initial plausibility checks, and normalization into a common internal event format. Adapters are independently deployable, versioned, and testable. Adapters for Tier 1 sources must preserve the original Ed25519 signature for end-to-end verification.

- `adapter-ami`: DLMS OBIS code parsing, interval alignment, VEE reconciliation.
- `adapter-microgrid`: PCC metering, islanding detection, internal allocation calculation.
- `adapter-v2g`: OCPP session parsing, ISO 15118 certificate chain validation, split attribution.
- `adapter-dr`: OpenADR event parsing, baseline calculation, compliance signal generation.
- `adapter-substation`: IEC 61850/DNP3 topology updates, breaker status, fault events.
- `adapter-ess`: Modbus register mapping, SoC tracking, charge/discharge event classification.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   ORACLE-BRIDGE DECOMPOSITION                          │
│                                                                        │
│  Layer 1: Domain Adapters                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │adapter   │ │adapter   │ │adapter   │ │adapter   │ │adapter   │    │
│  │-ami      │ │-microgrid│ │-v2g      │ │-dr       │ │-ess      │    │
│  │          │ │          │ │          │ │          │ │          │    │
│  │DLMS      │ │IEC 61850 │ │OCPP 2.0  │ │OpenADR   │ │Modbus    │    │
│  │OBIS      │ │Modbus    │ │ISO 15118 │ │2.0b      │ │CAN       │    │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘    │
│       │            │            │            │            │           │
│       ▼            ▼            ▼            ▼            ▼           │
│  Layer 2: Validation Core                                              │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  • Per-device energy balance ledger                            │    │
│  │  • Grid topology constraint enforcement                       │    │
│  │  • Microgrid PCC reconciliation                                │    │
│  │  • Staleness enforcement                                      │    │
│  │  • Anomaly detection (rate-of-change, physical ceiling)        │    │
│  └───────────────────────────┬────────────────────────────────────┘    │
│                              │                                        │
│                              ▼                                        │
│  Layer 3: On-Chain Committer                                           │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  • submit_reading + mint_grid (Oracle Program PDA authority)   │    │
│  │  • Batch per epoch (15 min default)                            │    │
│  │  • SHA-256 commitment hash                                    │    │
│  │  • SOLE minting authority in the system                        │    │
│  └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Cross-Domain Energy Balance Reconciliation

The most critical function of the validation core is preventing double-counting across domains. The reconciliation engine maintains a real-time energy balance for each grid connection point:

**Balance equation per prosumer per interval:**

```
Net export (grid meter) = Solar generation − Self-consumption − Battery charge + Battery discharge − EV charge + V2G discharge
```

The grid meter (Tier 1) measures the left side directly. The right side is reconstructed from Tier 2 sources (ESS SoC, V2G sessions) and Tier 3 sources (HEMS appliance data, inverter telemetry).

**Reconciliation rules:**

1. If the right side is fully observable and matches the left side within 5% → high-confidence validation, proceed to mint.
2. If the right side is partially observable (e.g., ESS data available but HEMS data missing) → validate using available data, flag gaps, proceed to mint based on grid meter only.
3. If the right side contradicts the left side by >10% → flag the reading for manual review. Do not reject minting outright (the grid meter is authoritative) but log the discrepancy for audit.
4. If grid meter data is unavailable → no minting regardless of Tier 2/3 data availability. The grid meter is the single source of truth for settlement.

> **Important principle:** Tier 2 and Tier 3 data can increase confidence in a Tier 1 reading, and can flag anomalies for review, but can never block minting of a valid Tier 1 reading. The grid meter is the legally recognized measurement point under PEA's metering regulations.

---

## 9. Protocol Integration Risks

| Risk | Domain | Impact | Mitigation |
|---|---|---|---|
| OBIS code mapping error | AMI | Incorrect kWh → wrong mint amount | Conformance test suite per firmware version |
| VEE disagreement >5% | AMI | Meter fault or estimation failure | Auto-pause + operator alert |
| PCC < sum of prosumer exports | Microgrid | Over-minting within microgrid | Proportional scaling to PCC value |
| Islanded microgrid minting | Microgrid | Mint for energy not on main grid | GOOSE breaker status check |
| V2G split attribution failure | V2G | Wrong wallet receives tokens | ISO 15118 certificate → wallet mapping |
| Unregistered EV discharge | V2G | Tokens have no destination wallet | Escrow in Trading Program + timeout |
| Phantom DR compliance | DR | Inflated DR incentives | Price-only incentive, no bonus minting |
| Stale breaker status | Substation | Validate on de-energized feeder | 30-second staleness threshold |
| Battery SoC drift | ESS | Incorrect energy balance | 7-day cumulative drift detection |
| Double-counting solar + battery | ESS | Same kWh minted twice | Per-device energy balance ledger |
| HEMS spoofing | HEMS | Phantom export claims | HEMS data excluded from minting path |
| Neuron version drift | All Tier 1 | Inconsistent translation across edges | Centralized OTA via EMQX management |

---

## 10. Implementation Priority

**Phase 1 (Competition / Hackathon):**
AMI integration only. Single adapter (`adapter-ami`), basic validation core, on-chain committer. Pandapower simulator generates synthetic DLMS readings. This is the minimum viable oracle-bridge.

**Phase 2 (Pilot):**
Add ESS adapter for behind-the-meter visibility and energy balance reconciliation. Add substation adapter for feeder topology constraints. Deploy with real PEA meters in sandbox.

**Phase 3 (Production):**
Add V2G adapter aligned with Thailand's 30@30 EV rollout. Add demand response adapter for PEA DR programs. Microgrid PCC adapter for community energy pilots.

**Phase 4 (Scale):**
HEMS integration for prosumer dashboards. Weather-adjusted validation and forecasting. Full cross-domain energy balance reconciliation engine. ASEAN cross-border settlement considerations.

---

## Related Documentation

- [Oracle Bridge Architecture](./ORACLE_BRIDGE_ARCHITECTURE.md) - Core service design and telemetry pipeline
- [Oracle Bridge Summary](./ORACLE_BRIDGE_SUMMARY.md) - Overview and key decisions
- [Smart Contract Architecture](../specs/smart-contract-architecture.md#oracle-program) - Oracle Program on-chain specification
- [Blockchain Architecture](../specs/blockchain-architecture.md) - Solana settlement layer
- [Platform Algorithms](../../academic/ALGORITHMS.md#2-oracle-algorithms) - Oracle validation algorithms
- [Security Analysis](../../academic/07-security-analysis.md) - Threat model and oracle security
- [Grid Integration Tokenomics](../economic-models/grid-integration-tokenomics.md) - Provenance loop and prosumer boost

---

*Last Updated: April 10, 2026*  
*Document Version: 1.0*  
*Maintainer: GridTokenX Engineering Architecture Team*
