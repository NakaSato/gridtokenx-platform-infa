# GridTokenX System Container Diagram (Mermaid C4)

The PlantUML preview failed because it requires **Graphviz** to be installed on your system. Since I cannot install system dependencies, I have converted the C4 model to **Mermaid**, which renders natively in VS Code without extra setup.

```mermaid
C4Context
    title System Container Diagram for GridTokenX Platform
    
    Person(user, "User/Prosumer", "A user who trades energy credits or manages their smart meter.")
    System_Ext(pyth, "Pyth Network", "Provides real-time market data and oracle services.")

    Boundary(b1, "GridTokenX Platform", "Container Boundary") {
        Container(frontend, "Trading Frontend", "Next.js, React", "Provides the web interface for trading and dashboard.")
        Container(gateway, "API Gateway", "Rust, Axum", "Handles API requests, authentication, and business logic.")
        Container(simulator, "Smart Meter Simulator", "Python", "Simulates smart meter energy readings.")
        
        ContainerDb(db, "Database", "PostgreSQL", "Stores user data, meter readings, and transaction history.")
        ContainerDb(cache, "Cache", "Redis", "Caches frequent data and handles event queues.")
        
        Container(blockchain, "Solana Blockchain", "Anchor Framework", "Executes smart contracts for Energy Token, Governance, Oracle, Registry, and Trading.")
    }

    Rel(user, frontend, "Views dashboard, trades energy", "HTTPS")
    Rel(frontend, gateway, "Fetches data, performs auth", "JSON/HTTPS")
    Rel(frontend, blockchain, "Signs transactions, queries state", "RPC/WSS")
    Rel(frontend, pyth, "Fetches market prices", "HTTPS")

    Rel(simulator, gateway, "Submits energy readings", "JSON/HTTPS")

    Rel(gateway, db, "Reads/Writes data", "SQL/TCP")
    Rel(gateway, cache, "Reads/Writes cache", "RESP/TCP")
    Rel(gateway, blockchain, "Submits oracle data, monitors events", "RPC/WSS")
```
