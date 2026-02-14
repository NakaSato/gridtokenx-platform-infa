---
name: Smart Meter Simulator Management
description: Manage, run, and debug the Smart Meter Simulator (Phase 2+)
---

# Smart Meter Simulator Management Skill

This skill provides instructions for operating the Smart Meter Simulator, including the Phase 2 Pandapower integration.

## 1. Quick Start

**Start the Simulator (API + WebSocket):**
```bash
cd gridtokenx-smartmeter-simulator
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

**Run Headless Simulation Script:**
```bash
python scripts/run.py
```

## 2. Configuration (Phase 2 Features)

### Meter Accuracy & Topology
Phase 2 introduces realistic accuracy modeling and dynamic topology.

**Environment Variables (.env):**
- `NUM_METERS`: Number of meters to simulate (e.g., `50`).
  - *Note:* The system now automatically builds a multi-feeder network based on this count.
- `METER_TYPE_DISTRIBUTION`: JSON string for custom mix (optional).

### Accuracy Classes
Meters are automatically assigned accuracy classes based on type:
- **Residential/Grid Consumer**: Class 2.0 (±2.0%)
- **Commercial/Solar**: Class 1.0 (±1.0%)
- **Feeder/Battery**: Class 0.5 (±0.5%)
- **Substation**: Class 0.2 (±0.2%)

## 3. Verification & Testing

### Run All Tests
```bash
cd gridtokenx-smartmeter-simulator
pytest tests/
```

### Verify Topology Integration (Phase 2)
Use the standalone verification script to confirm the multi-feeder network generation logic:
```bash
python tests/test_topology_integration.py
```
*Expected Output:* "Topology verification PASSED" with bus count > meter count.

### Check Grid Status (API)
Once running, check the grid topology status:
```bash
curl http://localhost:8000/api/grid/status
```

## 4. Debugging

**Issue:** "Pandapower not installed"
**Solution:**
```bash
pip install "pandapower>=2.14.0"
# Or install optional dependencies
pip install -e ".[dev]"
```

**Issue:** "No module named 'app'"
**Solution:**
Ensure you are in the `gridtokenx-smartmeter-simulator/src` directory or set PYTHONPATH:
```bash
export PYTHONPATH=$PYTHONPATH:$(pwd)/src
```

## 5. Key Components
- **Engine (`src/app/core/engine.py`)**: Main simulation loop.
- **Adapter (`src/app/adapters/pandapower_adapter.py`)**: Connects simulator to Pandapower grid model.
- **Topology (`src/app/adapters/pandapower_adapter.py`)**: `build_network_from_meters` logic.
