#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Pull the image explicitly so registry errors surface in their own step.
set -euo pipefail
if docker pull --quiet "$IMAGE"; then
  echo "Pulled $IMAGE"
elif docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Pull failed but local image present, continuing: $IMAGE"
else
  echo "::error::Image not available locally or remotely: $IMAGE"
  exit 1
fi
