#!/usr/bin/env nu
# GridTokenX Development Helper Script

def "grx check" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-api
    cargo check
}

def "grx build" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-api
    cargo build
}

def "grx test" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-api
    cargo test
}

def "grx migrate" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-api
    sqlx migrate run
}

def "grx db-up" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa
    docker compose up -d postgres
}

def "grx db-down" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa
    docker compose down postgres
}

def "grx orb-up" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa
    docker compose up -d
}

def "grx orb-down" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa
    docker compose down
}

def "grx prepare" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-api
    cargo sqlx prepare
}

# Main entry point
def main [cmd?: string] {
    match $cmd {
        "check" => { grx check }
        "build" => { grx build }
        "test" => { grx test }
        "migrate" => { grx migrate }
        "db-up" => { grx db-up }
        "db-down" => { grx db-down }
        "orb-up" => { grx orb-up }
        "orb-down" => { grx orb-down }
        "prepare" => { grx prepare }
        _ => {
            echo "Usage: grx <command>"
            echo ""
            echo "Commands:"
            echo "  check    - Run cargo check"
            echo "  build    - Run cargo build"
            echo "  test     - Run cargo test"
            echo "  migrate  - Run sqlx migrate"
            echo "  db-up    - Start PostgreSQL (OrbStack)"
            echo "  db-down  - Stop PostgreSQL"
            echo "  orb-up   - Start all OrbStack services"
            echo "  orb-down - Stop all OrbStack services"
            echo "  prepare  - Prepare sqlx offline queries"
        }
    }
}
