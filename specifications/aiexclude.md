<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# aiexclude

- **File**: `.aiexclude`
- **Syntax**: gitignore
- **Source**: https://developer.android.com/studio/preview/features#ai-exclude-files
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- Used by Android Studio’s AI features (e.g., code completion, chat) to exclude files from AI context.
- Patterns are resolved relative to the `.aiexclude` file location.
- Multiple `.aiexclude` files can exist in different directories, each governing its subtree.
