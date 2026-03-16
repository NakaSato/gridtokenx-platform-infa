#!/bin/bash
# GridTokenX Application Manager
# Unified script for starting, stopping, and managing the GridTokenX platform
#
# Usage: ./app.sh [command] [options]
#
# Commands:
#   start     - Start all services (Docker, Solana, API, Frontend)
#   stop      - Stop all services
#   restart   - Restart all services
#   doctor    - Check system dependencies and health
#   status    - Check service status
#   init      - Initialize blockchain and deploy programs
#   register  - Register admin user
#   seed      - Seed database with test users
#   logs      - View service logs
#
# Examples:
#   ./app.sh start              # Start everything
#   ./app.sh start --skip-ui    # Start without frontend UIs
#   ./app.sh stop               # Stop all services
#   ./app.sh restart            # Restart everything
#   ./app.sh status             # Check what's running
#   ./app.sh init               # Just init blockchain
#   ./app.sh register           # Register admin user

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project directories
# Resolve PROJECT_ROOT dynamically based on script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANCHOR_DIR="$PROJECT_ROOT/gridtokenx-anchor"
GATEWAY_DIR="$PROJECT_ROOT/gridtokenx-apigateway"
DEV_WALLET="$GATEWAY_DIR/dev-wallet.json"
PID_FILE="$PROJECT_ROOT/.gridtokenx.pid"

# Service ports
API_URL="http://localhost:4000"
RPC_URL="http://localhost:8899"
WS_URL="ws://localhost:8900"

# ============================================================================
# Helper Functions
# ============================================================================

check_dependencies() {
    local missing=()
    local deps=("docker" "solana" "anchor" "bun" "cargo" "uv" "jq" "curl")
    
    log_info "Checking system dependencies..."
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_warn "Missing dependencies: ${missing[*]}"
        return 1
    fi
    log_success "All core dependencies found."
    return 0
}

cmd_doctor() {
    show_banner
    log_info "Running GridTokenX System Doctor..."
    echo ""
    
    # Check dependencies
    check_dependencies || log_warn "Please install missing dependencies to ensure all services can start."
    
    # Check Docker health
    if docker info &>/dev/null; then
        log_success "Docker daemon is running."
    else
        log_error "Docker daemon is not running. Please start Docker."
    fi
    
    # Check Solana tools
    if command -v solana &>/dev/null; then
        local solana_ver=$(solana --version | head -n 1)
        log_success "Solana CLI found: $solana_ver"
    fi
    
    # Check Node.js/Bun
    if command -v bun &>/dev/null; then
        log_success "Bun found: $(bun --version)"
    fi
    
    echo ""
    log_info "Diagnostic complete!"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_banner() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        GridTokenX Application Manager              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_help() {
    show_banner
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  start     Start all services (Docker, Solana, API, Frontend)"
    echo "  stop      Stop all services"
    echo "  restart   Restart all services"
    echo "  status    Check service status"
    echo "  init      Initialize blockchain and deploy programs"
    echo "  register  Register admin user"
    echo "  seed      Seed database with test users (SQL)"
    echo "  logs      View service logs"
    echo "  doctor    Check system dependencies"
    echo ""
    echo "Options for 'start':"
    echo "  --skip-ui      Skip starting frontend UIs"
    echo "  --skip-solana  Skip starting Solana validator"
    echo "  --docker-only  Only start Docker services"
    echo ""
    echo "Examples:"
    echo "  $0 start              Start everything"
    echo "  $0 start --skip-ui    Start backend only"
    echo "  $0 stop               Stop all services"
    echo "  $0 status             Check what's running"
    echo ""
}

# Wait for service to be ready
wait_for_service() {
    local name=$1
    local url=$2
    local max_attempts=${3:-30}
    local interval=${4:-2}
    
    log_info "Waiting for $name to be ready..."
    for i in $(seq 1 $max_attempts); do
        if curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -q "200"; then
            log_success "$name is ready!"
            return 0
        fi
        echo -ne "."
        sleep $interval
    done
    echo ""
    log_warn "$name did not respond within $(($max_attempts * $interval))s"
    return 1
}

wait_for_port() {
    local name=$1
    local port=$2
    local max_attempts=${3:-30}
    
    log_info "Waiting for $name (Port $port) to be open..."
    for i in $(seq 1 $max_attempts); do
        if nc -z localhost "$port" 2>/dev/null; then
            log_success "$name (Port $port) is open!"
            return 0
        fi
        echo -ne "."
        sleep 1
    done
    echo ""
    log_warn "$name did not respond on port $port"
    return 1
}

wait_for_postgres() {
    log_info "Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        if docker exec gridtokenx-postgres pg_isready -U gridtokenx_user -d gridtokenx >/dev/null 2>&1; then
            log_success "PostgreSQL is ready!"
            return 0
        fi
        echo -ne "."
        sleep 1
    done
    echo ""
    log_error "PostgreSQL failed to start within 30 seconds"
    return 1
}

wait_for_solana() {
    log_info "Waiting for Solana validator to be ready..."
    for i in {1..30}; do
        if solana cluster-version --url $RPC_URL &>/dev/null; then
            log_success "Solana validator is ready!"
            return 0
        fi
        sleep 1
    done
    log_error "Solana validator failed to start"
    return 1
}

# Update environment file
update_env_file() {
    local file=$1
    local var=$2
    local value=$3
    
    if [ ! -f "$file" ]; then
        # Create file if it doesn't exist
        touch "$file"
    fi

    if grep -q "^${var}=" "$file"; then
        # Platform-agnostic sed in-place update
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^${var}=.*|${var}=${value}|" "$file"
        else
            sed -i "s|^${var}=.*|${var}=${value}|" "$file"
        fi
    else
        echo "${var}=${value}" >> "$file"
    fi
}

# Propagate program IDs and metadata to all services
propagate_program_ids() {
    local registry_id=$1
    local energy_token_id=$2
    local trading_id=$3
    local oracle_id=$4
    local governance_id=$5
    local energy_mint=$6
    local currency_mint=$7
    local registry_pda=$8
    local trading_market_pda=$9

    log_info "Propagating program IDs to services..."

    # API Gateway
    local gateway_env="$GATEWAY_DIR/.env"
    update_env_file "$gateway_env" "SOLANA_REGISTRY_PROGRAM_ID" "$registry_id"
    update_env_file "$gateway_env" "SOLANA_ENERGY_TOKEN_PROGRAM_ID" "$energy_token_id"
    update_env_file "$gateway_env" "SOLANA_TRADING_PROGRAM_ID" "$trading_id"
    update_env_file "$gateway_env" "SOLANA_ORACLE_PROGRAM_ID" "$oracle_id"
    update_env_file "$gateway_env" "SOLANA_GOVERNANCE_PROGRAM_ID" "$governance_id"
    update_env_file "$gateway_env" "ENERGY_TOKEN_MINT" "$energy_mint"
    [ -n "$currency_mint" ] && update_env_file "$gateway_env" "CURRENCY_TOKEN_MINT" "$currency_mint"
    [ -n "$registry_pda" ] && update_env_file "$gateway_env" "REGISTRY_PDA" "$registry_pda"
    [ -n "$trading_market_pda" ] && update_env_file "$gateway_env" "TRADING_MARKET_PDA" "$trading_market_pda"
    update_env_file "$gateway_env" "SOLANA_RPC_URL" "$RPC_URL"

    # Explorer
    local explorer_env="$PROJECT_ROOT/gridtokenx-explorer/.env"
    update_env_file "$explorer_env" "NEXT_PUBLIC_REGISTRY_PROGRAM_ID" "$registry_id"
    update_env_file "$explorer_env" "NEXT_PUBLIC_TOKEN_PROGRAM_ID" "$energy_token_id"
    update_env_file "$explorer_env" "NEXT_PUBLIC_TRADING_PROGRAM_ID" "$trading_id"
    update_env_file "$explorer_env" "NEXT_PUBLIC_ORACLE_PROGRAM_ID" "$oracle_id"
    update_env_file "$explorer_env" "NEXT_PUBLIC_GOVERNANCE_PROGRAM_ID" "$governance_id"
    update_env_file "$explorer_env" "NEXT_PUBLIC_SOLANA_RPC_HTTP" "$RPC_URL"
    update_env_file "$explorer_env" "NEXT_PUBLIC_SOLANA_RPC_WS" "$WS_URL"

    # Portal
    local portal_env="$PROJECT_ROOT/gridtokenx-portal/.env"
    update_env_file "$portal_env" "NEXT_PUBLIC_TRADING_PROGRAM_ID" "$trading_id"
    update_env_file "$portal_env" "NEXT_PUBLIC_ENERGY_TOKEN_MINT" "$energy_mint"
    update_env_file "$portal_env" "NEXT_PUBLIC_SOLANA_RPC_URL" "$RPC_URL"

    # Trading
    local trading_env="$PROJECT_ROOT/gridtokenx-trading/.env"
    update_env_file "$trading_env" "NEXT_PUBLIC_REGISTRY_PROGRAM_ID" "$registry_id"
    update_env_file "$trading_env" "NEXT_PUBLIC_ENERGY_TOKEN_PROGRAM_ID" "$energy_token_id"
    update_env_file "$trading_env" "NEXT_PUBLIC_TRADING_PROGRAM_ID" "$trading_id"
    update_env_file "$trading_env" "NEXT_PUBLIC_ORACLE_PROGRAM_ID" "$oracle_id"
    update_env_file "$trading_env" "NEXT_PUBLIC_GOVERNANCE_PROGRAM_ID" "$governance_id"
    update_env_file "$trading_env" "NEXT_PUBLIC_ENERGY_TOKEN_MINT" "$energy_mint"
    update_env_file "$trading_env" "NEXT_PUBLIC_SOLANA_RPC_URL" "$RPC_URL"
    update_env_file "$trading_env" "NEXT_PUBLIC_SOLANA_WS_URL" "$WS_URL"

    log_success "Program IDs propagated to all services."
}

# Run command in new Terminal window (macOS)
run_in_terminal() {
    local title="$1"
    local command="$2"
    local dir="$3"
    
    log_info "Starting $title..."
    (cd "$dir" && nohup bash -c "$command" > /dev/null 2>&1 &)
}

# ============================================================================
# Command: STOP
# ============================================================================

cmd_stop() {
    show_banner
    echo -e "${YELLOW}Stopping GridTokenX services...${NC}"
    echo ""
    
    # Stop API Gateway
    pkill -f "api-gateway" 2>/dev/null && log_success "API Gateway stopped" || log_warn "API Gateway was not running"
    
    # Stop Frontend UIs
    pkill -f "bun run dev" 2>/dev/null || true
    pkill -f "vite" 2>/dev/null || true
    
    # Stop Simulator
    pkill -f "uvicorn" 2>/dev/null || true
    pkill -f "uv run start" 2>/dev/null && log_success "Simulator stopped" || true
    
    # Stop Solana
    pkill -f "solana-test-validator" 2>/dev/null && log_success "Solana validator stopped" || log_warn "Solana validator was not running"
    
    # Full stop including Docker
    if [ "$1" == "--all" ]; then
        echo ""
        log_info "Stopping Docker services..."
        cd "$PROJECT_ROOT"
        docker-compose down 2>/dev/null && log_success "Docker services stopped" || log_warn "Docker services were not running"
    fi
    
    # Remove PID file
    rm -f "$PID_FILE"
    
    echo ""
    log_success "All services stopped!"
    
    if [ "$1" != "--all" ]; then
        echo ""
        log_warn "Note: Docker services (PostgreSQL, Redis) are still running."
        echo "Use '$0 stop --all' to stop everything including Docker."
    fi
}

# ============================================================================
# Command: STATUS
# ============================================================================

cmd_status() {
    show_banner
    echo "Service Status:"
    echo "==============="
    echo ""
    
    local services=(
        "PostgreSQL:docker:gridtokenx-postgres"
        "Redis:docker:gridtokenx-redis"
        "API Gateway:process:api-gateway"
        "Solana Validator:process:solana-test-validator"
        "Simulator API:process:uvicorn"
        "Trading UI:process:bun.*dev.*3000"
        "Explorer UI:process:bun.*dev.*3001"
        "App Portal:process:bun.*dev.*3002"
        "Simulator UI:process:bun.*dev.*8080"
    )
    
    printf "%-25s %-15s %-10s\n" "Service" "Type" "Status"
    printf "%-25s %-15s %-10s\n" "-------" "----" "------"
    
    for service in "${services[@]}"; do
        IFS=':' read -r name type pattern <<< "$service"
        
        local status_icon="${RED}✗${NC}"
        local status_text="${RED}Stopped${NC}"
        
        if [ "$type" == "docker" ]; then
            if docker ps --format '{{.Names}}' | grep -q "^${pattern}$"; then
                status_icon="${GREEN}✓${NC}"
                status_text="${GREEN}Running${NC}"
            fi
        else
            if pgrep -f "$pattern" > /dev/null 2>&1; then
                status_icon="${GREEN}✓${NC}"
                status_text="${GREEN}Running${NC}"
            fi
        fi
        
        printf "%b %-23s %-15s %b\n" "$status_icon" "$name" "$type" "$status_text"
    done
    
    echo ""
    
    # Check endpoints
    echo "Endpoint Status:"
    echo "================"
    
    if curl -s "$RPC_URL/health" > /dev/null 2>&1; then
        echo -e "Solana RPC ($RPC_URL): ${GREEN}✓ Ready${NC}"
    else
        echo -e "Solana RPC ($RPC_URL): ${RED}✗ Unreachable${NC}"
    fi
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/health" 2>/dev/null || echo "000")
    if [ "$http_code" == "200" ]; then
        echo -e "API Gateway ($API_URL): ${GREEN}✓ Ready${NC}"
    else
        echo -e "API Gateway ($API_URL): ${RED}✗ Unreachable${NC} (HTTP $http_code)"
    fi
    
    echo ""
}

# ============================================================================
# Command: INIT (Blockchain)
# ============================================================================

cmd_init() {
    show_banner
    log_info "Initializing Blockchain..."
    echo ""
    
    # Check dependencies
    if ! command -v anchor &> /dev/null; then
        log_error "anchor CLI is not installed. See https://www.anchor-lang.com/docs/installation"
    fi
    
    if ! command -v solana &> /dev/null; then
        log_error "solana CLI is not installed"
    fi
    
    # Build programs
    log_info "Building Anchor Programs..."
    cd "$ANCHOR_DIR"
    anchor build
    
    # Check validator
    if ! curl -s "$RPC_URL/health" > /dev/null 2>&1; then
        log_warn "Solana validator not running. Starting it..."
        solana-test-validator --reset --ledger "$PROJECT_ROOT/test-ledger" > "$PROJECT_ROOT/solana.log" 2>&1 &
        wait_for_solana
    fi
    
    # Deploy programs
    log_info "Deploying Programs (Using existing keypairs for consistent IDs)..."
    
    deploy_program() {
        local NAME=$1
        local ID=$2
        
        log_info "Deploying $NAME ($ID)..."
        # Use existing keypair if available to keep Program ID
        local KEYPAIR="$ANCHOR_DIR/target/deploy/${NAME}-keypair.json"
        
        solana program deploy \
            --program-id "$KEYPAIR" \
            "$ANCHOR_DIR/target/deploy/${NAME}.so" \
            --url "$RPC_URL" 2>/dev/null || log_warn "Deployment may have failed or already exists (ID: $ID)"
    }
    
    # Program IDs from Anchor.toml
    local REGISTRY_ID="DVoD5K5YRuXXF54a3b6r282jRD8RmtVHGfpw55DHFVDe"
    local ENERGY_TOKEN_ID="ExZKhghptUk675rjxgHPjJZjczgWWRRwzUTQnqjPTLno"
    local TRADING_ID="3iFReh5tvdWkLt7eJcvGKsST7wcwZsSHk3z3xCfUwHLw"
    local ORACLE_ID="Ad5crRxCcvKFAShAMYtRAD9XKak1cwH1FCE6TrpUA9i2"
    local GOVERNANCE_ID="DksRNiZsEZ3zN8n8ZWfukFqi3z74e5865oZ8wFk38p4X"

    deploy_program "registry" "$REGISTRY_ID"
    deploy_program "energy_token" "$ENERGY_TOKEN_ID"
    deploy_program "trading" "$TRADING_ID"
    deploy_program "oracle" "$ORACLE_ID"
    deploy_program "governance" "$GOVERNANCE_ID"
    
    # Extract metadata for propagation
    log_info "Extracting PDAs and Mint addresses..."
    cd "$ANCHOR_DIR"
    local pda_config=$(npx ts-node scripts/get_pdas.ts 2>/dev/null || echo "")
    local energy_mint=$(echo "$pda_config" | grep "ENERGY_TOKEN_MINT=" | cut -d'=' -f2)
    local currency_mint=$(echo "$pda_config" | grep "CURRENCY_TOKEN_MINT=" | cut -d'=' -f2)
    local registry_pda=$(echo "$pda_config" | grep "REGISTRY_PDA=" | cut -d'=' -f2)
    local trading_market_pda=$(echo "$pda_config" | grep "TRADING_MARKET_PDA=" | cut -d'=' -f2)

    # Propagate
    propagate_program_ids \
        "$REGISTRY_ID" \
        "$ENERGY_TOKEN_ID" \
        "$TRADING_ID" \
        "$ORACLE_ID" \
        "$GOVERNANCE_ID" \
        "${energy_mint:-ExZKhghptUk675rjxgHPjJZjczgWWRRwzUTQnqjPTLno}" \
        "$currency_mint" \
        "$registry_pda" \
        "$trading_market_pda"

    log_success "Blockchain initialization complete!"
}

# ============================================================================
# Command: REGISTER (Admin)
# ============================================================================

cmd_register() {
    show_banner
    
    local email="${1:-admin_$(date +%s)@example.com}"
    local username="${2:-admin_$(date +%s)}"
    local password="${3:-P@ssw0rd123!}"
    local first_name="${4:-Admin}"
    local last_name="${5:-User}"
    
    log_info "Registering admin user..."
    echo "  Email: $email"
    echo "  Username: $username"
    
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
    fi
    
    local resp=$(curl -s -X POST "$API_URL/api/v1/users" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$email\",
            \"password\": \"$password\",
            \"username\": \"$username\",
            \"first_name\": \"$first_name\",
            \"last_name\": \"$last_name\"
        }")
    
    local token=$(echo "$resp" | jq -r '.data.auth.access_token // .auth.access_token // empty')
    
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        log_success "Admin registered successfully!"
        echo "  Token: ${token:0:20}..."
        
        # Save token to file for later use
        echo "$token" > "$PROJECT_ROOT/.admin_token"
        echo "  Token saved to .admin_token"
    else
        log_error "Failed to register admin. Response: $resp"
    fi
}

# ============================================================================
# Command: SEED (Database)
# ============================================================================

cmd_seed() {
    show_banner
    log_info "Seeding database with test users..."
    
    if [ -f "$PROJECT_ROOT/scripts/seed_1000_users.sql" ]; then
        docker exec -i gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx < "$PROJECT_ROOT/scripts/seed_1000_users.sql"
        log_success "Database seeded with test users!"
    else
        log_warn "seed_1000_users.sql not found, skipping"
    fi
}

# ============================================================================
# Command: LOGS
# ============================================================================

cmd_logs() {
    local service="$1"
    
    case "$service" in
        api|gateway)
            log_info "API Gateway logs:"
            ;;
        solana|validator)
            tail -f "$PROJECT_ROOT/solana.log" 2>/dev/null || log_error "No solana.log found"
            ;;
        postgres|db)
            docker logs -f gridtokenx-postgres
            ;;
        redis)
            docker logs -f gridtokenx-redis
            ;;
        *)
            show_banner
            echo "View logs for a service"
            echo ""
            echo "Usage: $0 logs [service]"
            echo ""
            echo "Services: api, solana, postgres, redis"
            echo ""
            ;;
    esac
}

# ============================================================================
# Modular Start Functions
# ============================================================================

start_core_services() {
    log_info "Starting Core Docker services..."
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running."
    fi
    
    cd "$PROJECT_ROOT"
    docker-compose up -d postgres redis mailpit nginx 2>/dev/null || docker-compose up -d postgres redis nginx
    wait_for_postgres
    log_success "Core services ready"
}

start_blockchain_services() {
    echo ""
    log_info "Starting Solana test validator..."
    mkdir -p "$PROJECT_ROOT/scripts/logs"
    solana-test-validator --reset --ledger "$PROJECT_ROOT/test-ledger" > "$PROJECT_ROOT/scripts/logs/validator.log" 2>&1 &
    wait_for_solana
    
    # Fund wallets
    log_info "Funding wallets..."
    solana airdrop 10 $(solana address) --url "$RPC_URL" 2>/dev/null || true
    
    if [ ! -f "$DEV_WALLET" ]; then
        if [ -f "$PROJECT_ROOT/dev-wallet.json" ]; then
            cp "$PROJECT_ROOT/dev-wallet.json" "$DEV_WALLET"
        else
            solana-keygen new --no-bip39-passphrase --outfile "$DEV_WALLET" 2>/dev/null
        fi
    fi
    
    local dev_pubkey=$(solana-keygen pubkey "$DEV_WALLET")
    solana airdrop 100 "$dev_pubkey" --url "$RPC_URL" 2>/dev/null || true
    log_success "Wallets funded"
    
    # Initialize blockchain
    cmd_init
}

start_application_services() {
    local skip_ui=$1
    
    echo ""
    log_info "Starting application backend services..."
    mkdir -p "$PROJECT_ROOT/scripts/logs"
    
    # API Gateway Nodes
    run_in_terminal "API Gateway Node 1" "PORT=4001 cargo run --release --bin api-gateway > $PROJECT_ROOT/scripts/logs/api-node-1.log 2>&1" "$GATEWAY_DIR"
    run_in_terminal "API Gateway Node 2" "PORT=4002 cargo run --release --bin api-gateway > $PROJECT_ROOT/scripts/logs/api-node-2.log 2>&1" "$GATEWAY_DIR"
    
    # Wait for the Nginx proxy
    wait_for_service "API Gateway Load Balancer" "$API_URL/health" 60 2
    
    if [ "$skip_ui" = false ]; then
        echo ""
        log_info "Starting frontend UIs..."
        
        # Simulator
        if [ -d "$PROJECT_ROOT/gridtokenx-smartmeter-simulator/ui/node_modules" ]; then
            run_in_terminal "Simulator UI" "bun run dev --port 8080" "$PROJECT_ROOT/gridtokenx-smartmeter-simulator/ui"
        fi
        
        if [ -f "$PROJECT_ROOT/gridtokenx-smartmeter-simulator/pyproject.toml" ]; then
            run_in_terminal "Simulator API" "PORT=8082 uv run start" "$PROJECT_ROOT/gridtokenx-smartmeter-simulator"
        fi
        
        # Trading UI
        if [ -d "$PROJECT_ROOT/gridtokenx-trading/node_modules" ]; then
            run_in_terminal "Trading UI" "bun run dev" "$PROJECT_ROOT/gridtokenx-trading"
        fi
        
        # Explorer UI
        if [ -d "$PROJECT_ROOT/gridtokenx-explorer/node_modules" ]; then
            run_in_terminal "Explorer UI" "bun run dev --port 3001" "$PROJECT_ROOT/gridtokenx-explorer"
        fi
        
        # App Portal
        if [ -d "$PROJECT_ROOT/gridtokenx-portal/node_modules" ]; then
            run_in_terminal "App Portal" "bun run dev --port 3002" "$PROJECT_ROOT/gridtokenx-portal"
        fi
        
        # Admin UI
        if [ -d "$PROJECT_ROOT/gridtokenx-admin/node_modules" ]; then
            run_in_terminal "Admin UI" "bun run dev" "$PROJECT_ROOT/gridtokenx-admin"
        fi
    fi
}

# ============================================================================
# Command: START
# ============================================================================

cmd_start() {
    show_banner
    
    # Pre-flight
    check_dependencies || true
    
    # Step 1: Cleanup
    log_info "Cleaning up existing processes..."
    pkill -f "solana-test-validator" 2>/dev/null || true
    pkill -f "api-gateway" 2>/dev/null || true
    pkill -f "uvicorn" 2>/dev/null || true
    pkill -f "bun run dev" 2>/dev/null || true
    sleep 2
    
    # Step 2: Core Docker Services
    start_core_services
    
    if [ "$docker_only" = true ]; then
        return 0
    fi
    
    # Step 3: Blockchain Services
    if [ "$skip_solana" = false ]; then
        start_blockchain_services
        
        # Step 4: Anchor Configuration
        echo ""
        log_info "Configuring environment..."
        cd "$ANCHOR_DIR"
        export ANCHOR_PROVIDER_URL="$RPC_URL"
        export ANCHOR_WALLET="$DEV_WALLET"
        
        local pda_config=$(npx ts-node scripts/get_pdas.ts 2>/dev/null || echo "")
        local energy_mint=$(echo "$pda_config" | grep "ENERGY_TOKEN_MINT=" | cut -d'=' -f2)
        local currency_mint=$(echo "$pda_config" | grep "CURRENCY_TOKEN_MINT=" | cut -d'=' -f2)
        local registry_pda=$(echo "$pda_config" | grep "REGISTRY_PDA=" | cut -d'=' -f2)
        local trading_market_pda=$(echo "$pda_config" | grep "TRADING_MARKET_PDA=" | cut -d'=' -f2)
        
        # Program IDs from Anchor.toml
        local REGISTRY_ID="DVoD5K5YRuXXF54a3b6r282jRD8RmtVHGfpw55DHFVDe"
        local ENERGY_TOKEN_ID="ExZKhghptUk675rjxgHPjJZjczgWWRRwzUTQnqjPTLno"
        local TRADING_ID="3iFReh5tvdWkLt7eJcvGKsST7wcwZsSHk3z3xCfUwHLw"
        local ORACLE_ID="Ad5crRxCcvKFAShAMYtRAD9XKak1cwH1FCE6TrpUA9i2"
        local GOVERNANCE_ID="DksRNiZsEZ3zN8n8ZWfukFqi3z74e5865oZ8wFk38p4X"

        propagate_program_ids \
            "$REGISTRY_ID" \
            "$ENERGY_TOKEN_ID" \
            "$TRADING_ID" \
            "$ORACLE_ID" \
            "$GOVERNANCE_ID" \
            "${energy_mint:-ExZKhghptUk675rjxgHPjJZjczgWWRRwzUTQnqjPTLno}" \
            "$currency_mint" \
            "$registry_pda" \
            "$trading_market_pda"
        
        log_success "Environment configured and propagated"
    fi
    
    # Step 5: Application Services
    start_application_services "$skip_ui"
    
    # Validator logs
    if [ "$skip_solana" = false ]; then
        run_in_terminal "Validator Logs" "tail -f $PROJECT_ROOT/scripts/logs/validator.log" "$PROJECT_ROOT"
    fi
    
    # Save PID
    echo $$ > "$PID_FILE"
    
    echo ""
    log_success "Development environment launched!"
    echo ""
    echo -e "${CYAN}Service Endpoints:${NC}"
    echo "  • Solana RPC:    $RPC_URL"
    echo "  • API Gateway:   $API_URL"
    echo "  • Explorer UI:   http://localhost:3001"
    echo "  • App Portal:    http://localhost:3002"
    echo "  • Simulator:     http://localhost:8080"
    echo "  • Trading UI:    http://localhost:3000"
    echo ""
    echo "Commands:"
    echo "  $0 stop         Stop all services"
    echo "  $0 status       Check service status"
    echo "  $0 register     Register admin user"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        start)
            cmd_start "$@"
            ;;
        stop)
            cmd_stop "$@"
            ;;
        restart)
            local fast_restart=false
            if [[ "$1" == "--fast" ]]; then
                fast_restart=true
                shift
            fi
            
            cmd_stop
            
            if [ "$fast_restart" = false ]; then
                echo ""
                log_info "Cleaning up database, solana ledger, and cache data..."
                cd "$PROJECT_ROOT"
                docker-compose down -v 2>/dev/null || true
                rm -rf "$PROJECT_ROOT/test-ledger"
                rm -rf "$PROJECT_ROOT/scripts/logs"
                rm -f "$PROJECT_ROOT/.admin_token"
                log_success "Cleanup complete"
            fi
            
            sleep 2
            cmd_start "$@"
            ;;
        doctor)
            cmd_doctor
            ;;
        status)
            cmd_status
            ;;
        init)
            cmd_init
            ;;
        register)
            cmd_register "$@"
            ;;
        seed)
            cmd_seed
            ;;
        logs)
            cmd_logs "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
