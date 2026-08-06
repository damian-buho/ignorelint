<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# eleventyignore

- **File**: `.eleventyignore`
- **Syntax**: gitignore
- **Source**: https://www.11ty.dev/docs/ignores/
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- Excludes files from Eleventy’s build and file-watching.
- Eleventy also reads `.gitignore` by default (can be disabled).
- `.eleventyignore` patterns take precedence over `.gitignore`.
