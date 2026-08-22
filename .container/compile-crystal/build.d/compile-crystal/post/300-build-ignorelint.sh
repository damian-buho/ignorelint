#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Build the ignorelint Crystal binary and export it.

# shellcheck source=/dev/null
. b19-i18n

export_dir="/export/usr/local/bin"
mkdir -p "${export_dir}"

cd "${B19_HOME}" || exit

if [ ! -f "shard.yml" ]; then
  b19-log fatal "IGNORELINT" "shard.yml not found in ${B19_HOME}"
  exit 1
fi

b19-run "SHARDS" "$(_ "Install dependencies")" --     \
  shards install

# Crystal has no -X linker flag, so the version reaches the binary as a
# compile-time macro env (src/version.cr). M6E_VERSION is the build ARG the OCI
# `version` label already carries, so the label and `ignorelint --version` agree.
export M6E_VERSION="${M6E_VERSION:-dev}"
b19-log info "IGNORELINT" "$(_p "Stamping version %s" "${M6E_VERSION}")"

b19-run "CRYSTAL" "$(_p "Build %s" "ignorelint")" --      \
  crystal build src/ignorelint.cr                         \
    -o "${export_dir}/ignorelint"                         \
    --release                                             \
    --no-debug

b19-log good "IGNORELINT" "$(_p "Built %s → %s" "ignorelint" "${export_dir}/ignorelint")"
