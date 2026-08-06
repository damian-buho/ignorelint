<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# fdignore

- **File**: `.fdignore`
- **Syntax**: gitignore
- **Source**: https://github.com/sharkdp/fd#fdignore
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- fd reads `.fdignore` in addition to `.gitignore` and `.ignore`.
- Global ignore file at `~/.config/fd/ignore` uses the same syntax.
- Patterns are resolved relative to the `.fdignore` file location.
