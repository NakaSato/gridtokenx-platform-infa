---
name: Agent Management
description: Comprehensive guide for the Agent to manage itself, the project context, and high-level workflows.
---

# Agent Management Skill

This skill provides instructions and "meta-procedures" for the Agent to effectively manage the GridTokenX project lifecycle, verify its own work, and maintain the knowledge base.

## 1. Project Context

**Root Path:** `/Users/chanthawat/Developments/gridtokenx-platform-infa`
**Tech Stack:**
- **Backend:** Python (FastAPI), Rust (Solana/Anchor)
- **Infrastructure:** Docker, Kafka, PostgreSQL, InfluxDB
- **Blockchain:** Solana (Local Validator / University PoA)

## 2. Core Capabilities

### A. Environment Management
Use these commands to verify the state of the development environment.

**Check All Services:**
```bash
docker compose ps
```

**Validate Python Environment:**
```bash
source .venv/bin/activate
pip list
```

**Validate Rust/Anchor Environment:**
```bash
anchor --version
solana --version
```

### B. Knowledge Base Maintenance
The Agent must maintain the `.agent` directory as the source of truth.

- **Workflows:** Stored in `.agent/workflows/`. Use `ls .agent/workflows` to find standard procedures.
- **Skills:** Stored in `.agent/skills/`. Read `SKILL.md` in each subdirectory before attempting complex tasks (e.g., Kafka, Database).

### C. Self-Verification
Before marking a task as complete, perform these checks:

1.  **Code Consistency:** Ensure no broken imports or syntax errors.
    ```bash
    # Python
    flake8 src/
    # Rust
    cargo check
    ```
2.  **Test Execution:** Run relevant tests.
    ```bash
    pytest tests/
    anchor test
    ```
3.  **Documentation:** Update `README.md` or `task.md` if the scope logic changed.

## 3. Advanced Operations

### Generating New Skills
To add a new capability to the agent's repertoire:
1. Create directory `.agent/skills/<new_skill_name>`
2. Create `SKILL.md` with:
   - YAML frontmatter (name, description)
   - Detailed "How-To" instructions
   - Relevant code snippets and command lines

### Managing Workflows
To standardise a complex multi-step process:
1. Create `.agent/workflows/<workflow_name>.md`
2. Describe step-by-step instructions.
3. Add `// turbo` annotation for auto-runnable commands.

## 4. Troubleshooting

**Issue:** "Agent seems lost or hallucinates paths."
**Solution:**
1. Run `ls -R` or `find . -maxdepth 2` to re-orient.
2. Read `.agent/skills/agent/SKILL.md` (this file) to ground truth.

**Issue:** "Services not talking to each other."
**Solution:**
1. Check Docker networking: `docker network ls`
2. Check logs: `docker compose logs --tail 20 <service_name>`

---
*This skill is self-referential. Use it to maintain high agentic performance.*
