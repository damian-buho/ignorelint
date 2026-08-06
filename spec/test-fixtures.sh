#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Integration test: runs ignorelint against fixture files (valid + broken)
# Usage: test-fixtures.sh [ignorelint-binary]
#
# Exit codes:
#   0 — all assertions passed
#   1 — one or more assertions failed

set -eou pipefail

binary="${1:-ignorelint}"
fixtures_dir="$(cd "$(dirname "$0")" && pwd)/fixtures"
pass=0
fail=0
total=0

# Broken fixtures are named like "issue.gitignore" but from_path only matches
# ".gitignore" or "gitignore". We create a temp dir with properly named copies.
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

# staged_file <fixture_path> — copies fixture to tmpdir with correct name
# e.g. broken/negated-rooted.gitignore → tmpdir/.gitignore
staged_file() {
  local fixture="$1"
  local ext
  ext="$(basename "${fixture}")"
  ext="${ext##*.}"
  local target="${tmpdir}/.${ext}"
  cp "${fixture}" "${target}"
  printf '%s' "${target}"
}

log_pass() {
  pass=$((pass + 1))
  total=$((total + 1))
  printf '  \033[32mPASS\033[0m %s\n' "$1"
}

log_fail() {
  fail=$((fail + 1))
  total=$((total + 1))
  printf '  \033[31mFAIL\033[0m %s\n' "$1"
}

assert_clean() {
  local fixture="$1"
  local label="${2:-$(basename "$fixture")}"
  local output

  output=$("${binary}" "${fixture}" 2>&1) || true

  if [ -z "${output}" ]; then
    log_pass "${label} — clean"
  else
    log_fail "${label} — expected clean, got:"
    printf '    %s\n' "${output}"
  fi
}

assert_issues() {
  local fixture="$1"
  local label="${2:-$(basename "$fixture")}"
  local min_issues="${3:-1}"
  local output
  local issue_count

  output=$("${binary}" "${fixture}" 2>&1) || true

  if [ -z "${output}" ]; then
    log_fail "${label} — expected >= ${min_issues} issues, got 0"
    return
  fi

  issue_count=$(printf '%s\n' "${output}" | wc -l)

  if [ "${issue_count}" -ge "${min_issues}" ]; then
    log_pass "${label} — ${issue_count} issue(s) detected"
  else
    log_fail "${label} — expected >= ${min_issues} issues, got ${issue_count}:"
    printf '    %s\n' "${output}"
  fi
}

assert_issue_contains() {
  local fixture="$1"
  local needle="$2"
  local label="${3:-$(basename "$fixture")}"
  local output

  output=$("${binary}" "${fixture}" 2>&1) || true

  if printf '%s\n' "${output}" | grep -q "${needle}"; then
    log_pass "${label} — contains '${needle}'"
  else
    log_fail "${label} — missing expected '${needle}', output:"
    printf '    %s\n' "${output}"
  fi
}

# -- Valid fixtures (must produce 0 issues) ---------------------------------

printf '\n\033[1m=== Valid fixtures (expect clean) ===\033[0m\n\n'

for f in "${fixtures_dir}"/valid/*; do
  [ -f "${f}" ] || continue
  # REUSE .license sidecars sit beside each fixture; they are metadata, not input.
  case "${f}" in *.license) continue ;; esac
  assert_clean "${f}"
done

# -- Broken fixtures (must produce >= 1 issue) -----------------------------

printf '\n\033[1m=== Broken fixtures (expect issues) ===\033[0m\n\n'

# Universal issues — use .gitignore name so gitignore-style rules also apply
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/trailing-whitespace.gitignore")" "trailing whitespace"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/duplicate-patterns.gitignore")" "duplicate"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/double-negation.gitignore")" "double negation"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/empty-pattern.gitignore")" "empty pattern"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/malformed-brackets.gitignore")" "bracket"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/unescaped-hash.gitignore")" "unescaped"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/consecutive-asterisks.gitignore")" "consecutive"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/space-in-pattern.gitignore")" "space in pattern"

# Gitignore-style issues
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/negated-rooted.gitignore")" "anchoring has no effect"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/invalid-doublestar.gitignore")" "invalid **"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/rooted-shallow.gitignore")" "rooted pattern"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/redundant-pair.gitignore")" "redundant pair"
assert_issues "$(staged_file "${fixtures_dir}/broken/kitchen-sink.gitignore")" "kitchen-sink.gitignore" 6

# Dockerignore-style issues
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/path-traversal.dockerignore")" "path traversal"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/path-traversal.containerignore")" "path traversal"
assert_issues "$(staged_file "${fixtures_dir}/broken/dockerignore-mixed.containerignore")" "dockerignore-mixed" 2

# Slugignore-specific issues
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/negation-slugignore.slugignore")" "negation is not supported"
assert_issue_contains "$(staged_file "${fixtures_dir}/broken/slugignore-mixed.slugignore")" "negation is not supported"

# Multi-format smoke — eslintignore, prettierignore, helmignore
assert_issues "$(staged_file "${fixtures_dir}/broken/all-broken.eslintignore")" "eslintignore-smoke" 1
assert_issues "$(staged_file "${fixtures_dir}/broken/all-broken.prettierignore")" "prettierignore-smoke" 1
assert_issues "$(staged_file "${fixtures_dir}/broken/all-broken.helmignore")" "helmignore-smoke" 1

# -- Summary ---------------------------------------------------------------

printf '\n\033[1m=== Summary ===\033[0m\n'
printf '  Total: %d  |  Passed: %d  |  Failed: %d\n\n' "${total}" "${pass}" "${fail}"

[ "${fail}" -eq 0 ]
