#!/bin/bash
export DATABASE_URL="postgres://gridtokenx_user:gridtokenx_password@127.0.0.1:5434/gridtokenx"
export REDIS_URL="redis://127.0.0.1:6379"
export SOLANA_RPC_URL="http://127.0.0.1:8899"
export SOLANA_WS_URL="ws://127.0.0.1:8900"
export IAM_SERVICE_URL="http://127.0.0.1:8080"
export IAM_REST_URL="http://127.0.0.1:8080"
export IAM_GRPC_URL="http://127.0.0.1:8090"
export API_GATEWAY_URL="http://127.0.0.1:4000"
export TRADING_SERVICE_URL="http://127.0.0.1:8092"
export TRADING_GRPC_URL="http://127.0.0.1:8092"
export JWT_SECRET="dev-jwt-secret-key-minimum-32-characters-long-for-development-2025"
export ENCRYPTION_SECRET="dev-encryption-secret-key-32-chars-minimum-for-wallet-encryption"
export API_KEY_SECRET="test-api-key-secret-for-development-and-testing"
export ENVIRONMENT="development"
export LOG_LEVEL="info"
export APIGATEWAY_PORT=4000
export MAX_CONNECTIONS=100
export REDIS_POOL_SIZE=20
export AUDIT_LOG_ENABLED=true
export ENGINEERING_API_KEY="engineering-department-api-key-2025"
export ENERGY_TOKEN_MINT="2Zx6bpmjFAwuagwQqcqWhHiMKeCPPtCQLF8kfGMDCtJj"

echo "Starting $1..."
exec "$@"
