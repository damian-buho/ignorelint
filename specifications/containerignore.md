<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# containerignore

- **File**: `.containerignore`
- **Syntax**: dockerignore
- **Source**: https://docs.podman.io/en/latest/markdown/podman-build.1.html
- **Reference**: dockerignore (identical)

## Syntax

Identical to dockerignore. See [dockerignore](dockerignore.md).

## Deviations from gitignore

Same as dockerignore:

- **Leading and trailing slashes are stripped** before matching.
- `filepath.Clean` is applied to all patterns.
- The pattern `.` is silently ignored.

## Notes

- Podman uses `.containerignore` as the primary name but also reads `.dockerignore`.
- Buildah similarly reads `.containerignore` and `.dockerignore`.
- The semantics are identical to dockerignore; see [dockerignore](dockerignore.md) for full details.
