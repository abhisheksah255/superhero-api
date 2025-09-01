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

  code=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" --max-time "$TIMEOUT" "$url" || echo "000")

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

# Exit with failure if any failed
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
