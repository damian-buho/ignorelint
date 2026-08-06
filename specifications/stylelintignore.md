<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# stylelintignore

- **File**: `.stylelintignore`
- **Syntax**: gitignore
- **Source**: https://stylelint.io/user-guide/ignore-code
- **Reference**: gitignore (via `node-ignore` library)

## Syntax

Uses gitignore syntax as implemented by the `node-ignore` library. Supports all standard gitignore patterns including `!` negation, `**` globs, and `#` comments.

## Deviations from gitignore

None (delegates to `node-ignore`).

## Notes

- Patterns are resolved relative to `process.cwd()`, not relative to the `.stylelintignore` file location.
- The `node-ignore` library aims for gitignore compatibility but may have subtle edge-case differences.
