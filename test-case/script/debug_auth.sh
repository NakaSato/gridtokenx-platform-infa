#!/bin/bash
API_URL="http://localhost:8080"
EMAIL="debug_auth_$(date +%s)@example.com"
PASSWORD="Password123!"

echo "Registering..."
USERNAME="debug_user_$(date +%s)"
curl -v -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{ \"username\": \"$USERNAME\", \"email\": \"$EMAIL\", \"password\": \"$PASSWORD\", \"first_name\": \"Debug\", \"last_name\": \"Auth\", \"role\": \"prosumer\" }" 2>&1

echo -e "\n\nLogging in..."
curl -v -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{ \"username\": \"$USERNAME\", \"password\": \"$PASSWORD\" }" 2>&1
