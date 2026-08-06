<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# slugignore

- **File**: `.slugignore`
- **Syntax**: slugignore (plain path list)
- **Source**: https://devcenter.heroku.com/articles/slug-compiler
- **Reference**: N/A

## Syntax

- One file or directory path per line.
- `#` comments are supported.
- Each line is treated as a literal path or simple pattern to exclude from the build slug.
- No glob syntax in the original specification (some implementations may accept simple globs).
- No `!` negation.
- No blank-line significance beyond being skipped.

## Deviations from gitignore

- **No `!` negation support.**
- **No glob support** in the original spec (no `*`, `?`, `**`, `[a-z]`).
- **No concept of rooted vs. unrooted patterns.**
- Lines are plain file/directory paths, not patterns.

## Notes

- This format is fundamentally different from gitignore and cannot be linted with the same rule set.
- A linter should flag glob characters in `.slugignore` as potentially unsupported.
