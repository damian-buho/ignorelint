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

b19-run "CRYSTAL" "$(_p "Build %s" "ignorelint")" --      \
  crystal build src/ignorelint.cr                         \
    -o "${export_dir}/ignorelint"                         \
    --release                                             \
    --no-debug

b19-log good "IGNORELINT" "$(_p "Built %s → %s" "ignorelint" "${export_dir}/ignorelint")"
