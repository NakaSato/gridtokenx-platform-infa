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
PROJECT_ROOT="/Users/chanthawat/Developments/gridtokenx-platform-infa"
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
    
    if [ -f "$file" ]; then
        if grep -q "^${var}=" "$file"; then
            sed -i '' "s|^${var}=.*|${var}=${value}|" "$file" 2>/dev/null || \
            sed -i "s|^${var}=.*|${var}=${value}|" "$file"
        else
            echo "${var}=${value}" >> "$file"
        fi
    fi
}

# Run command in new Terminal window (macOS)
run_in_terminal() {
    local title="$1"
    local command="$2"
    local dir="$3"
    
    log_info "Starting $title..."
    if command -v osascript &> /dev/null; then
        osascript -e "tell application \"Terminal\" to do script \"cd $dir && $command\"" >/dev/null 2>&1
    else
        # Linux fallback - use nohup
        (cd "$dir" && nohup bash -c "$command" > /dev/null 2>&1 &)
    fi
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
    pkill -f "start-simulator" 2>/dev/null && log_success "Simulator stopped" || true
    
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
        "PostgreSQL:gridtokenx-postgres:docker"
        "Redis:gridtokenx-redis:docker"
        "API Gateway::process:api-gateway"
        "Solana Validator::process:solana-test-validator"
        "Simulator API::process:uvicorn"
        "Trading UI::process:bun.*dev.*3000"
        "Simulator UI::process:bun.*dev.*8080"
    )
    
    for service in "${services[@]}"; do
        IFS=':' read -r name container_type pattern <<< "$service"
        
        if [ "$container_type" == "docker" ]; then
            if docker ps --format '{{.Names}}' | grep -q "^${pattern}$"; then
                echo -e "${GREEN}✓${NC} $name: ${GREEN}Running${NC}"
            else
                echo -e "${RED}✗${NC} $name: ${RED}Stopped${NC}"
            fi
        else
            if pgrep -f "$pattern" > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} $name: ${GREEN}Running${NC}"
            else
                echo -e "${RED}✗${NC} $name: ${RED}Stopped${NC}"
            fi
        fi
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
    log_info "Deploying Programs..."
    
    deploy_program() {
        local NAME=$1
        local ID=$2
        
        log_info "Deploying $NAME ($ID)..."
        solana program deploy \
            --program-id "$ANCHOR_DIR/target/deploy/${NAME}-keypair.json" \
            "$ANCHOR_DIR/target/deploy/${NAME}.so" \
            --url "$RPC_URL" 2>/dev/null || log_warn "Deployment may have failed or already exists"
    }
    
    deploy_program "registry" "CXXRVpEwyd2ch7eo425mtaBfr2Yi1825Nm6yik2NEWqR"
    deploy_program "energy_token" "5DJCWKo5cXt3PXRsrpH1xixra4wXWbNzxZ1p4FHqSxvi"
    deploy_program "trading" "8S2e2p4ghqMJuzTz5AkAKSka7jqsjgBH7eWDcCHzXPND"
    deploy_program "oracle" "EkcPD2YEXhpo1J73UX9EJNnjV2uuFS8KXMVLx9ybqnhU"
    deploy_program "governance" "8bNpJqZoqqUWKu55VWhR8LWS66BX7NPpwgYBAKhBzu2L"
    
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
# Command: START
# ============================================================================

cmd_start() {
    local skip_ui=false
    local skip_solana=false
    local docker_only=false
    
    # Parse options
    for arg in "$@"; do
        case "$arg" in
            --skip-ui) skip_ui=true ;;
            --skip-solana) skip_solana=true ;;
            --docker-only) docker_only=true ;;
        esac
    done
    
    show_banner
    
    # Step 1: Cleanup
    log_info "Cleaning up existing processes..."
    pkill -f "solana-test-validator" 2>/dev/null || true
    pkill -f "api-gateway" 2>/dev/null || true
    pkill -f "uvicorn" 2>/dev/null || true
    pkill -f "bun run dev" 2>/dev/null || true
    sleep 2
    
    # Step 2: Docker Services
    log_info "Starting Docker services..."
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running. Please start Docker and try again."
    fi
    
    cd "$PROJECT_ROOT"
    docker-compose up -d postgres redis mailpit 2>/dev/null || docker-compose up -d postgres redis
    wait_for_postgres
    log_success "Docker services ready"
    
    if [ "$docker_only" = true ]; then
        echo ""
        log_success "Docker services started!"
        echo ""
        echo "Run '$0 init' to initialize blockchain"
        echo "Run '$0 start' without --docker-only to start full stack"
        return 0
    fi
    
    # Step 3: Solana Validator
    if [ "$skip_solana" = false ]; then
        echo ""
        log_info "Starting Solana test validator..."
        mkdir -p "$PROJECT_ROOT/scripts/logs"
        solana-test-validator --reset --ledger "$PROJECT_ROOT/test-ledger" > "$PROJECT_ROOT/scripts/logs/validator.log" 2>&1 &
        local validator_pid=$!
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
        echo ""
        cmd_init
    fi
    
    # Step 4: Anchor Bootstrap (if Solana is running)
    if [ "$skip_solana" = false ]; then
        echo ""
        log_info "Running Anchor Bootstrap..."
        cd "$ANCHOR_DIR"
        export ANCHOR_PROVIDER_URL="$RPC_URL"
        export ANCHOR_WALLET="$DEV_WALLET"
        
        if command -v pnpm &> /dev/null; then
            pnpm ts-node scripts/bootstrap.ts 2>/dev/null || log_warn "Bootstrap may have failed"
            
            # Get PDA config
            local pda_config=$(pnpm ts-node scripts/get_pdas.ts 2>/dev/null || echo "")
            local energy_mint=$(echo "$pda_config" | grep "ENERGY_TOKEN_MINT=" | cut -d'=' -f2)
            
            if [ -n "$energy_mint" ]; then
                update_env_file "$GATEWAY_DIR/.env" "ENERGY_TOKEN_MINT" "$energy_mint"
                update_env_file "$GATEWAY_DIR/.env" "SOLANA_RPC_URL" "$RPC_URL"
                update_env_file "$PROJECT_ROOT/.env" "ENERGY_TOKEN_MINT" "$energy_mint"
                log_success "Environment configured"
            fi
        fi
    fi
    
    # Step 5: Start Services
    echo ""
    log_info "Starting application services..."
    
    # API Gateway
    run_in_terminal "API Gateway" "cargo run --bin api-gateway" "$GATEWAY_DIR"
    wait_for_service "API Gateway" "$API_URL/health" 60 2
    
    if [ "$skip_ui" = false ]; then
        # Simulator
        if [ -d "$PROJECT_ROOT/gridtokenx-smartmeter-simulator/ui/node_modules" ]; then
            run_in_terminal "Simulator UI" "bun run dev --port 8080" "$PROJECT_ROOT/gridtokenx-smartmeter-simulator/ui"
        fi
        
        if [ -f "$PROJECT_ROOT/gridtokenx-smartmeter-simulator/pyproject.toml" ]; then
            run_in_terminal "Simulator API" "PORT=8082 uv run start-simulator" "$PROJECT_ROOT/gridtokenx-smartmeter-simulator"
        fi
        
        # Trading UI
        if [ -d "$PROJECT_ROOT/gridtokenx-trading/node_modules" ]; then
            run_in_terminal "Trading UI" "bun run dev" "$PROJECT_ROOT/gridtokenx-trading"
        fi
        
        # Admin UI
        if [ -d "$PROJECT_ROOT/gridtokenx-admin/node_modules" ]; then
            run_in_terminal "Admin UI" "bun run dev" "$PROJECT_ROOT/gridtokenx-admin"
        fi
    fi
    
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
            cmd_stop
            sleep 2
            cmd_start "$@"
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
