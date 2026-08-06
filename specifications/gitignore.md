<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# gitignore

- **File**: `.gitignore`
- **Syntax**: gitignore
- **Source**: https://git-scm.com/docs/gitignore
- **Reference**: THE reference format

## Syntax

- Empty lines are ignored.
- Lines starting with `#` are comments.
- Trailing whitespace is ignored unless quoted with backslash.
- `!` prefix negates a pattern (re-includes previously excluded paths).
- Trailing `/` matches directories only.
- Leading `/` anchors the pattern to the location of the ignore file (rooted match).
- Without a leading `/`, the pattern may match at any depth (unrooted).
- `*` matches anything except `/`.
- `?` matches exactly one character except `/`.
- `[a-z]` matches one character in the given range or set.
- `**` glob extensions:
    - Leading `**/` — match in all directories (zero or more depth).
    - Trailing `/**` — match everything inside.
    - Mid-path `/**/` — match zero or more intermediate directories.
- A trailing `!` in a directory pattern is ignored (you cannot re-include a file if its parent directory is excluded).
- `\` escapes special characters (`#`, `!`, `*`, `?`, `[`, leading/trailing whitespace).
- Multiple `.gitignore` files: a pattern in a subdirectory overrides parent patterns for that subtree.

## Deviations from gitignore

None.

## Notes

- The canonical semantics for all other formats in this project are defined relative to this document.
- Patterns are matched against the path relative to the `.gitignore` file location.
- A negated pattern cannot re-include a file if its parent directory is excluded by an earlier pattern.
