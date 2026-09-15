#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Resolve the container image reference: explicit override wins, else tag from version.
set -euo pipefail
if [ -n "$IMAGE_OVERRIDE" ]; then
  ref="$IMAGE_OVERRIDE"
else
  ref="ghcr.io/damian-buho/ignorelint:${VERSION}"
fi
echo "ref=$ref" >> "$GITHUB_OUTPUT"
