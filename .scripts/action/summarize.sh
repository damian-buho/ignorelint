#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Count severities from the JSON report, annotate violations, render the run summary.
set -euo pipefail
errors=$(jq '[.issues[] | select(.severity == "error")] | length' "$REPORT_JSON")
warnings=$(jq '[.issues[] | select(.severity == "warning")] | length' "$REPORT_JSON")
infos=$(jq '[.issues[] | select(.severity == "info")] | length' "$REPORT_JSON")
fixed=$(jq '[.issues[] | select(.severity == "fixed")] | length' "$REPORT_JSON")
total=$(jq -r '.total // 0' "$REPORT_JSON")
{
  echo "errors=$errors"
  echo "warnings=$warnings"
  echo "infos=$infos"
  echo "fixed=$fixed"
  echo "total=$total"
} >> "$GITHUB_OUTPUT"
jq -r '.issues[] | select(.severity != "fixed") | (if .severity == "error" then "error" elif .severity == "warning" then "warning" else "notice" end) as $lvl | "::\($lvl) file=\(.file),line=\(.line),title=ignorelint \(.code)::\(.message | gsub("\r"; "") | gsub("\n"; " "))"' "$REPORT_JSON" || true
case "$FAIL_ON" in
  none)
    fail=0
    ;;
  error)
    if [ "$errors" -gt 0 ]; then fail=1; else fail=0; fi
    ;;
  warn)
    if [ "$errors" -gt 0 ] || [ "$warnings" -gt 0 ]; then fail=1; else fail=0; fi
    ;;
  info)
    if [ "$errors" -gt 0 ] || [ "$warnings" -gt 0 ] || [ "$infos" -gt 0 ]; then fail=1; else fail=0; fi
    ;;
  *)
    echo "::error::Invalid fail_on='$FAIL_ON' (expected: none | error | warn | info)"
    exit 2
    ;;
esac
if [ "$fail" -eq 1 ]; then result=fail; else result=pass; fi
echo "result=$result" >> "$GITHUB_OUTPUT"
echo "fail=$fail" >> "$GITHUB_OUTPUT"
{
  echo "## Ignorelint — $result"
  echo
  echo "errors: $errors · warnings: $warnings · infos: $infos · fixed: $fixed · total: $total"
  echo
  cat "$REPORT_HUMAN"
} >> "$GITHUB_STEP_SUMMARY"
