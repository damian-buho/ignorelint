<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# npmignore

- **File**: `.npmignore`
- **Syntax**: gitignore
- **Source**: https://docs.npmjs.com/cli/v10/using-npm/developers#keeping-files-out-of-your-package
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Built-in excludes

These are always excluded regardless of `.npmignore` contents:

- `*.swp`
- `._*`
- `.DS_Store`
- `.git`
- `.hg`
- `.svn`
- `node_modules`

## Built-in includes

These are always included and cannot be excluded:

- `package.json`
- `README*`
- `CHANGELOG*`
- `LICENSE`
- `LICENCE`

## Notes

- If `.npmignore` is absent, npm falls back to `.gitignore`.
- If neither file exists, npm includes all files not covered by built-in excludes.
- Built-in includes cannot be overridden by `.npmignore` patterns.
