#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Run ignorelint in the container: JSON for gating, human for display, plus any requested format.
set -euo pipefail
report_human="${RUNNER_TEMP}/ignorelint-report.txt"
report_json="${RUNNER_TEMP}/ignorelint-report.json"
report_sarif="${RUNNER_TEMP}/ignorelint-report.sarif"
format_lower=$(tr '[:upper:]' '[:lower:]' <<< "$FORMAT")
case "$format_lower" in
  ''|human|tty|gnu|json|checkstyle|junit|gitlab_codeclimate|codacy|sonarqube|sarif) ;;
  *) echo "::error::Invalid format='$FORMAT' (expected: human|tty|gnu|json|checkstyle|junit|gitlab_codeclimate|codacy|sonarqube|sarif)"; exit 2 ;;
esac
if [ "$FIX" = "true" ] && [ "$DIFF" = "true" ]; then
  echo "::error::--fix and --diff: use one, not both"
  exit 2
fi
if [ "$QUIET" = "true" ] && [ "$VERBOSE" = "true" ]; then
  echo "::error::quiet and verbose: use one, not both"
  exit 2
fi
{
  echo "report_path=$report_human"
  echo "report_json=$report_json"
} >> "$GITHUB_OUTPUT"
if [ "$format_lower" = "sarif" ]; then
  EMIT_SARIF="true"
fi
if [ "$EMIT_SARIF" = "true" ]; then
  echo "sarif_path=$report_sarif" >> "$GITHUB_OUTPUT"
else
  echo "sarif_path=" >> "$GITHUB_OUTPUT"
fi
format_path=""
if [ -n "$format_lower" ]; then
  case "$format_lower" in
    human|tty) format_path="$report_human" ;;
    json) format_path="$report_json" ;;
    sarif) format_path="$report_sarif" ;;
    junit|checkstyle) format_path="${RUNNER_TEMP}/ignorelint-report-${format_lower}.xml" ;;
    gnu) format_path="${RUNNER_TEMP}/ignorelint-report-gnu.txt" ;;
    *) format_path="${RUNNER_TEMP}/ignorelint-report-${format_lower}.json" ;;
  esac
fi
echo "format_path=$format_path" >> "$GITHUB_OUTPUT"
base_args=()
while IFS= read -r p; do
  if [ -n "$p" ]; then
    base_args+=("$p")
  fi
done <<< "$PATHS"
if [ "$RECURSIVE" = "true" ]; then
  base_args+=(--recursive)
fi
if [ -n "$CONFIG_FILE" ]; then
  base_args+=(--config "$CONFIG_FILE")
fi
if [ -n "$DISABLED_RULES" ]; then
  base_args+=(--disabled-rules "$DISABLED_RULES")
fi
if [ -n "$OVERRIDE_ERROR" ]; then
  base_args+=(--error "$OVERRIDE_ERROR")
fi
if [ -n "$OVERRIDE_WARNING" ]; then
  base_args+=(--warning "$OVERRIDE_WARNING")
fi
if [ -n "$OVERRIDE_INFO" ]; then
  base_args+=(--info "$OVERRIDE_INFO")
fi
if [ "$NO_FAIL" = "true" ]; then
  base_args+=(--no-fail)
fi
if [ -n "$FILE_PATH_IN_REPORT" ]; then
  base_args+=(--file-path-in-report "$FILE_PATH_IN_REPORT")
fi
if [ "$DISABLE_IGNORE_PRAGMA" = "true" ]; then
  base_args+=(--disable-ignore-pragma)
fi
if [ "$VERBOSE" = "true" ]; then
  base_args+=(-v)
fi
if [ "$QUIET" = "true" ]; then
  base_args+=(-q)
fi
docker_base=(run --rm
  -v "${GITHUB_WORKSPACE}:/src"
  -w /src
  "$IMAGE" ignorelint)
json_args=(--format json)
if [ "$FIX" = "true" ]; then
  json_args+=(--fix)
fi
json_rc=0
echo "::group::Ignorelint (JSON for gating)"
docker "${docker_base[@]}" "${json_args[@]}" "${base_args[@]}" \
  > "$report_json" || json_rc=$?
echo "::endgroup::"
if [ "$json_rc" -gt 1 ]; then
  echo "::error::Ignorelint container failed (exit $json_rc); check image and args"
  exit "$json_rc"
fi
if [ ! -s "$report_json" ]; then
  echo "::error::JSON report file is empty; container may have failed silently"
  exit 1
fi
human_args=(--format human)
if [ "$PLAIN" = "true" ]; then
  human_args+=(--plain)
fi
# --diff previews instead of writing, so it only joins the human run and never the JSON gate.
if [ "$DIFF" = "true" ]; then
  human_args+=(--diff)
fi
echo "::group::Ignorelint (human report)"
docker "${docker_base[@]}" "${human_args[@]}" "${base_args[@]}" \
  | tee "$report_human" || true
echo "::endgroup::"
if [ "$EMIT_SARIF" = "true" ]; then
  echo "::group::Ignorelint (SARIF report)"
  docker "${docker_base[@]}" --format sarif "${base_args[@]}" \
    > "$report_sarif" || true
  echo "::endgroup::"
fi
# A requested machine format gets its own run; human, json and sarif already ran above.
if [ -n "$format_lower" ]; then
  case "$format_lower" in
    human|tty|json|sarif) ;;
    *)
      echo "::group::Ignorelint ($format_lower report)"
      docker "${docker_base[@]}" --format "$format_lower" "${base_args[@]}" \
        > "$format_path" || true
      echo "::endgroup::"
      ;;
  esac
fi
