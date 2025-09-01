#!/usr/bin/env bash
set -e

# Variables
COLLECTION="superhero-api.postman_collection.json"
REPORT_XML="smoke-report.xml"
REPORT_HTML="smoke-report.html"

echo "🚀 Running Superhero API smoke tests..."

# Run Newman tests
newman run "$COLLECTION" \
  --reporters cli,junit,html \
  --reporter-junit-export "$REPORT_XML" \
  --reporter-html-export "$REPORT_HTML" || true

echo "✅ Tests completed. Reports generated:"
echo "   - $REPORT_XML"
echo "   - $REPORT_HTML"
