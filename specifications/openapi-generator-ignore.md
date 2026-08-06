<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# openapi-generator-ignore

- **File**: `.openapi-generator-ignore`
- **Syntax**: gitignore
- **Source**: https://openapi-generator.tech/docs/usage#openapi-generator-ignore
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- Used by OpenAPI Generator to avoid overwriting existing files during code generation.
- If a generated file matches a pattern in `.openapi-generator-ignore`, the generator skips it and preserves the existing version.
- Patterns are resolved relative to the output directory (where code is generated).
