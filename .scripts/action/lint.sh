#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Run ignorelint in the container: JSON for gating, human for display, SARIF on request.
set -euo pipefail
report_human="${RUNNER_TEMP}/ignorelint-report.txt"
report_json="${RUNNER_TEMP}/ignorelint-report.json"
report_sarif="${RUNNER_TEMP}/ignorelint-report.sarif"
{
  echo "report_path=$report_human"
  echo "report_json=$report_json"
} >> "$GITHUB_OUTPUT"
if [ "$EMIT_SARIF" = "true" ]; then
  echo "sarif_path=$report_sarif" >> "$GITHUB_OUTPUT"
else
  echo "sarif_path=" >> "$GITHUB_OUTPUT"
fi
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
echo "::group::Ignorelint (human report)"
docker "${docker_base[@]}" --format human "${base_args[@]}" \
  | tee "$report_human" || true
echo "::endgroup::"
if [ "$EMIT_SARIF" = "true" ]; then
  echo "::group::Ignorelint (SARIF report)"
  docker "${docker_base[@]}" --format sarif "${base_args[@]}" \
    > "$report_sarif" || true
  echo "::endgroup::"
fi
