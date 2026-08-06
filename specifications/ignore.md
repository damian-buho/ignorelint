<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# ignore

- **File**: `.ignore`
- **Syntax**: gitignore
- **Source**: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- Generic `.ignore` file used by multiple tools (ripggrep, fd, ag, etc.) as a common ignore file.
- For ripgrep: `.ignore` takes precedence over `.rgignore`.
- For fd: `.ignore` is read in addition to `.fdignore` and `.gitignore`.
- Acts as a tool-agnostic alternative to tool-specific ignore files.
