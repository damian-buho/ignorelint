<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# cursorignore

- **File**: `.cursorignore`
- **Syntax**: gitignore
- **Source**: https://docs.cursor.com/context/ignore-files
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- Excludes files from Cursor’s AI indexing and context retrieval.
- Cursor also reads `.gitignore` in addition to `.cursorignore`.
- A companion file `.cursorindexingignore` controls indexing separately from chat context.
