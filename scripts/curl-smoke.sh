#!/usr/bin/env bash
set -e

BASE_URL="https://superhero-api-b6u9.onrender.com"
SUMMARY="curl-report.txt"
POSTMAN_COLLECTION="superhero-api.postman_collection.json"

echo "🚀 Running curl-based smoke tests..." > "$SUMMARY"

test_endpoint() {
  local endpoint=$1
  local expected_status=$2
  local method=${3:-GET}
  local body=${4:-""}
  local status

  if [ "$method" == "GET" ]; then
    status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")
  else
    status=$(curl -s -o /dev/null -w "%{http_code}" \
      -X "$method" \
      -H "Content-Type: application/json" \
      -d "$body" \
      "$BASE_URL$endpoint")
  fi

  if [ "$status" -eq "$expected_status" ]; then
    echo "✅ $method $endpoint -> $status" | tee -a "$SUMMARY"
  else
    echo "❌ $method $endpoint -> $status (expected $expected_status)" | tee -a "$SUMMARY"
  fi
}

# Lightweight curl checks
test_endpoint "/" 200
test_endpoint "/superheros" 200
test_endpoint "/superheros/refresh" 200
test_endpoint "/superheros/search?id=1" 200
test_endpoint "/superheros/search?name=Superman" 200

# POST/PUT with body (minimal check, actual body tests handled by Postman)
test_endpoint "/superheros/add_hero" 400 POST '{"name":"Ironman","power":"Tech","universe":"Marvel"}'
test_endpoint "/superheros/update_hero/1" 400 PUT '{"name":"Batman","power":"Stealth"}'
test_endpoint "/superheros/delete?id=1" 200 DELETE
test_endpoint "/superheros/delete_all" 200 DELETE

echo "📄 Curl smoke report generated at $SUMMARY"

echo ""
echo "🚀 Running full Postman tests with Newman..."
# Run full Postman collection
newman run "$POSTMAN_COLLECTION" \
  --reporters cli,junit,html \
  --reporter-junit-export postman-junit-report.xml \
  --reporter-html-export postman-html-report.html || true

echo "✅ Postman reports generated:"
echo "   - postman-junit-report.xml"
echo "   - postman-html-report.html"
