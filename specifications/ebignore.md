<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# ebignore

- **File**: `.ebignore`
- **Syntax**: gitignore
- **Source**: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb3-cli-configuration.html
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- If `.ebignore` is present, the EB CLI uses it **instead of** `.gitignore` for deployment bundling.
- If `.ebignore` is absent, the EB CLI falls back to `.gitignore`.
- The presence of `.ebignore` completely overrides `.gitignore` — they are not merged.
