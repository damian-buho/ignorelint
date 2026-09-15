#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Apply the gating decision last so the PR comment still posts on failure.
set -euo pipefail
if [ "$FAIL" = "1" ]; then
  echo "::error::Ignorelint found violations above fail_on='${FAIL_ON}'"
  exit 1
fi
echo "Ignorelint passed fail_on='${FAIL_ON}' threshold"
