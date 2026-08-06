<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# eslintignore

- **File**: `.eslintignore`
- **Syntax**: gitignore
- **Source**: https://eslint.org/docs/latest/use/configure/ignore
- **Reference**: gitignore (via `node-ignore` library)

## Syntax

Uses gitignore syntax as implemented by the `node-ignore` library. Supports all standard gitignore patterns including `!` negation, `**` globs, and `#` comments.

## Deviations from gitignore

- A pattern like `.config` only matches at the same directory level (non-recursive), unlike gitignore where an unrooted pattern matches at any depth. To match recursively, use `**/.config/`.
- In flat config (`eslint.config.js`), ignore patterns are defined inline via `globalIgnores()` and `ignores` key, not in a `.eslintignore` file.

## Notes

- `.eslintignore` is **deprecated** in ESLint flat config. The replacement is `ignores` in `eslint.config.js`.
- Patterns are resolved relative to the `.eslintignore` file location.
- The `node-ignore` library aims for gitignore compatibility but may have subtle edge-case differences.
