#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Resolve the container image reference: explicit override wins, else tag from version.
set -euo pipefail
version="${VERSION:-}"
# An empty version follows a release pin (1.6.0, 1.6, 1); a branch or SHA pin pulls latest
if [ -z "$version" ]; then
  case "${ACTION_REF:-}" in
    '' | *[!0-9.]*) version=latest ;;
    *) version="$ACTION_REF" ;;
  esac
  echo "resolve-image: version=${version} from action_ref=${ACTION_REF:-<none>}" >&2
fi
if [ -n "$IMAGE_OVERRIDE" ]; then
  ref="$IMAGE_OVERRIDE"
else
  ref="ghcr.io/damian-buho/ignorelint:${version}"
fi
echo "resolve-image: ref=${ref}" >&2
echo "ref=$ref" >> "$GITHUB_OUTPUT"
