<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# prettierignore

- **File**: `.prettierignore`
- **Syntax**: gitignore
- **Source**: https://prettier.io/docs/en/ignore
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Built-in excludes

- `.git`
- `.svn`
- `.hg`
- `node_modules`

## Notes

- If `.prettierignore` is absent, Prettier falls back to `.gitignore`.
- Built-in excludes cannot be overridden.
