#!/usr/bin/env bash
set -u

BASE_URL="${BASE_URL:-https://superhero-api-b6u9.onrender.com}"
ENDPOINTS_FILE="${ENDPOINTS_FILE:-endpoints.csv}"
OUT_JUNIT="${OUT_JUNIT:-smoke-report.xml}"
OUT_SUMMARY="${OUT_SUMMARY:-smoke-summary.md}"
TIMEOUT=15

PASS=0
FAIL=0
TOTAL=0
NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

RESULTS_FILE="$(mktemp)"

printf "%-25s %-6s %-40s %-10s %-10s %-8s\n" "NAME" "METHOD" "PATH" "EXPECTED" "ACTUAL" "RESULT"
echo "---------------------------------------------------------------------------------------------------------"

while IFS=, read -r method path expected name; do
  [[ -z "${method// /}" ]] && continue
  [[ "$method" =~ ^# ]] && continue

  ((TOTAL++))
  url="$BASE_URL$path"

  # Default curl args
  CURL_OPTS=(-s -o /dev/null -w "%{http_code}" -X "$method" --max-time "$TIMEOUT")

  # Add JSON payloads for POST/PUT
  if [[ "$method" == "POST" ]]; then
    CURL_OPTS+=(-H "Content-Type: application/json" \
                -d '{"name":"DummyHero","realName":"Test User","franchise":"Marvel"}')
  elif [[ "$method" == "PUT" ]]; then
    CURL_OPTS+=(-H "Content-Type: application/json" \
                -d '{"name":"UpdatedHero","realName":"Updated User","franchise":"DC"}')
  fi

  code=$(curl "${CURL_OPTS[@]}" "$url" || echo "000")

  # check if code is acceptable
  ok=false
  IFS='|' read -ra expcodes <<< "$expected"
  for e in "${expcodes[@]}"; do
    [[ "$code" == "$e" ]] && ok=true && break
  done

  if $ok; then
    result="PASS"
    ((PASS++))
  else
    result="FAIL"
    ((FAIL++))
  fi

  printf "%-25s %-6s %-40s %-10s %-10s %-8s\n" "$name" "$method" "$path" "$expected" "$code" "$result"
  printf "%s|%s|%s|%s|%s|%s\n" "$name" "$method" "$path" "$expected" "$code" "$result" >> "$RESULTS_FILE"
done < "$ENDPOINTS_FILE"

# Generate JUnit XML
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo "<testsuite name=\"API Smoke\" tests=\"$TOTAL\" failures=\"$FAIL\" timestamp=\"$NOW_ISO\">"
  while IFS='|' read -r name method path expected code result; do
    echo "  <testcase name=\"$method $path\">"
    if [[ "$result" != "PASS" ]]; then
      msg="Expected $expected but got $code"
      echo "    <failure message=\"$msg\"><![CDATA[$msg]]></failure>"
    fi
    echo "  </testcase>"
  done < "$RESULTS_FILE"
  echo "</testsuite>"
} > "$OUT_JUNIT"

# Generate Markdown summary
{
  echo "# API Smoke Test Report"
  echo ""
  echo "- **Base URL**: $BASE_URL"
  echo "- **Total**: $TOTAL"
  echo "- ✅ Passed: $PASS"
  echo "- ❌ Failed: $FAIL"
  echo ""
  echo "| Endpoint | Method | Expected | Actual | Result |"
  echo "|---|---|---|---|---|"
  while IFS='|' read -r name method path expected code result; do
    echo "| \`$path\` | $method | $expected | $code | $result |"
  done < "$RESULTS_FILE"
} > "$OUT_SUMMARY"

cat "$OUT_SUMMARY" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

# ✅ Do not exit 1, always exit 0 (workflow continues)
# If you want to fail workflow but after running all, uncomment:
# exit $([ $FAIL -gt 0 ] && echo 1 || echo 0)
exit 0
