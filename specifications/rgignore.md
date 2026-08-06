<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# rgignore

- **File**: `.rgignore`
- **Syntax**: gitignore
- **Source**: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- Second priority for ripgrep after `.ignore`.
- ripgrep reads `.gitignore`, `.ignore`, and `.rgignore` — all with gitignore semantics.
- Priority order: `.ignore` > `.rgignore` > `.gitignore` for ripgrep-specific overrides.
