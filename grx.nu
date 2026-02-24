#!/usr/bin/env nu
# GridTokenX Development Helper Script

def "grx check" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-apigateway
    cargo check
}

def "grx build" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-apigateway
    cargo build
}

def "grx test" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-apigateway
    cargo test
}

def "grx migrate" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-apigateway
    sqlx migrate run
}

def "grx db-up" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa
    docker-compose up -d postgres
}

def "grx db-down" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa
    docker-compose down postgres
}

def "grx prepare" [] {
    cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-apigateway
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
        "prepare" => { grx prepare }
        _ => {
            echo "Usage: grx <command>"
            echo ""
            echo "Commands:"
            echo "  check    - Run cargo check"
            echo "  build    - Run cargo build"
            echo "  test     - Run cargo test"
            echo "  migrate  - Run sqlx migrate"
            echo "  db-up    - Start PostgreSQL"
            echo "  db-down  - Stop PostgreSQL"
            echo "  prepare  - Prepare sqlx offline queries"
        }
    }
}
