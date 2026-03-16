#!/bin/bash
export $(grep -v '^#' gridtokenx-apigateway/.env | xargs)
export PORT=4001
export RUST_LOG=info
./gridtokenx-apigateway/target/release/api-gateway
