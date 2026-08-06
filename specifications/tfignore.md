<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# tfignore

- **File**: `.terraformignore` / `.tfignore`
- **Syntax**: gitignore
- **Source**: https://developer.hashicorp.com/terraform/cli/cmd/terraform/plan#planning-without-a-remote-backend
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- Patterns are resolved relative to the `.tfignore` file location.
- Used by `terraform` commands that transfer context (e.g., `terraform plan` in remote mode).
