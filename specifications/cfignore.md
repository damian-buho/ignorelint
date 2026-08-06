<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# cfignore

- **File**: `.cfignore`
- **Syntax**: gitignore
- **Source**: https://docs.cloudfoundry.org/devguide/deploy-apps/prepare-to-deploy.html#exclude
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Built-in excludes

These are always excluded regardless of `.cfignore` contents:

- `.cfignore`
- `_darcs`
- `.DS_Store`
- `.git`
- `.gitignore`
- `.hg`
- `manifest.yml`

## Notes

- Default excludes are applied by the Cloud Foundry CLI before reading `.cfignore`.
- Built-in excludes cannot be overridden by `.cfignore` patterns.
