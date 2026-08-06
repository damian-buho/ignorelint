<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# helmignore

- **File**: `.helmignore`
- **Syntax**: gitignore (Unix shell glob variant)
- **Source**: https://helm.sh/docs/chart_template_guide/getting_started/#the-chart-file-structure
- **Reference**: gitignore

## Syntax

- One pattern per line.
- Lines starting with `#` are comments.
- `!` prefix negates a pattern (re-includes previously excluded paths).
- Unix shell glob matching: `*` matches any non-`/` characters, `?` matches one non-`/` character, `[b-d]` matches a character range.
- Trailing `/` matches directories only.
- Leading `/` anchors the pattern to the `.helmignore` file location (rooted match).
- Without a leading `/`, patterns match at any depth.

## Deviations from gitignore

- No documented `**` support in the original spec (though the Go implementation may accept it depending on version).

## Built-in excludes

The Helm chart packager has defaults that cannot be overridden:

- `.` (current directory references)
- `..` (parent directory references)

## Notes

- Patterns are resolved relative to the `.helmignore` file location (chart root).
- `.helmignore` is used when packaging charts with `helm package` or `helm chart save`.
