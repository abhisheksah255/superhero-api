#!/usr/bin/env bash
set -e

BASE_URL="https://superhero-api-b6u9.onrender.com"

echo "🚀 Running curl-based smoke tests..."

test_endpoint() {
  local endpoint=$1
  local expected_status=$2
  local status

  status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")

  if [ "$status" -eq "$expected_status" ]; then
    echo "✅ $endpoint returned $status as expected"
  else
    echo "❌ $endpoint returned $status (expected $expected_status)"
  fi
}

# Run tests
test_endpoint "/" 200
test_endpoint "/superheros" 200
test_endpoint "/superheros/refresh" 200
test_endpoint "/superheros/search?id=1" 200
test_endpoint "/superheros/delete_all" 200
