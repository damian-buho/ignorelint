<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# yarnignore

- **File**: `.yarnignore`
- **Syntax**: gitignore
- **Source**: https://classic.yarnpkg.com/en/docs/package-json/#toc-yarnignore
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- Falls back to `.gitignore` if `.yarnignore` is absent.
- Falls back to `.npmignore` if neither `.yarnignore` nor `.gitignore` exist.
- Resolution order: `.yarnignore` → `.gitignore` → `.npmignore`.
