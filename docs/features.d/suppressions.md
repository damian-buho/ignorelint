<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Suppressions for intentional exceptions

- A comment directive silences listed codes on the next pattern, so known-good entries stop failing runs. See the [rules reference](docs/rules.md).
- Directives cover every code, including dead-rule findings from the filesystem.
- Unknown codes match nothing, so a mistyped directive fails safe and the finding still appears.
- Suppressed findings never reach autofix or exit codes.
- `--disabled-rules` (or `IGNORELINT_DISABLED_RULES`) skips listed codes for the whole run, so a check the team disagrees with stops failing builds without per-line directives. See the [CLI reference](docs/cli.md).
