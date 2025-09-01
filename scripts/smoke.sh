#!/usr/bin/env bash
set -euo pipefail

# Inputs from env
BASE_URL="${BASE_URL:-http://localhost:8080}"
ENDPOINTS_FILE="${ENDPOINTS_FILE:-endpoints.csv}"
OUT_JUNIT="${OUT_JUNIT:-smoke-report.xml}"
OUT_SUMMARY="${OUT_SUMMARY:-smoke-summary.md}"

# Initialize outputs
echo "Running API Smoke Tests against: $BASE_URL"
echo "| NAME | METHOD | PATH | EXPECTED | ACTUAL | RESULT |" > "$OUT_SUMMARY"
echo "|------|--------|------|----------|--------|--------|" >> "$OUT_SUMMARY"

# Counters
total=0
failures=0
passes=0

# Start XML
echo '<?xml version="1.0" encoding="UTF-8"?>' > "$OUT_JUNIT"
echo "<testsuites>" >> "$OUT_JUNIT"
echo "  <testsuite name=\"API Smoke Tests\">" >> "$OUT_JUNIT"

# Read CSV and run tests
tail -n +2 "$ENDPOINTS_FILE" | while IFS=, read -r NAME METHOD PATH DATA EXPECTED; do
  total=$((total+1))

  # Run request
  if [ -n "$DATA" ] && [ "$DATA" != "null" ]; then
    ACTUAL=$(curl -s -o /dev/null -w "%{http_code}" -X "$METHOD" "$BASE_URL$PATH" \
      -H "Content-Type: application/json" \
      -d "$DATA")
  else
    ACTUAL=$(curl -s -o /dev/null -w "%{http_code}" -X "$METHOD" "$BASE_URL$PATH")
  fi

  # Check result
  if [[ "$EXPECTED" =~ (^|[|])"$ACTUAL"($|[|]) ]]; then
    RESULT="PASS"
    passes=$((passes+1))
    echo "    <testcase name=\"$NAME\" classname=\"API\"/>" >> "$OUT_JUNIT"
  else
    RESULT="FAIL"
    failures=$((failures+1))
    echo "    <testcase name=\"$NAME\" classname=\"API\">" >> "$OUT_JUNIT"
    echo "      <failure message=\"Expected $EXPECTED but got $ACTUAL\">Response code mismatch</failure>" >> "$OUT_JUNIT"
    echo "    </testcase>" >> "$OUT_JUNIT"
  fi

  # Write Markdown row
  echo "| $NAME | $METHOD | $PATH | $EXPECTED | $ACTUAL | $RESULT |" >> "$OUT_SUMMARY"
done

# Close XML
echo "  </testsuite>" >> "$OUT_JUNIT"
echo "</testsuites>" >> "$OUT_JUNIT"

echo "✅ Tests completed: $passes passed, $failures failed, $total total."
