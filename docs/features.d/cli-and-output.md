<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# CLI, output formats and exit codes

- Flags: `--fail-on=LEVEL` (`error`|`warn`|`info`, default `error`), `--format=FORMAT` (`human`|`json`|`checkstyle`|`sarif`, default `human`), `--fix`, `--verbose`/`-v`, `--version`/`-V`, `--help`/`-h`; positional `PATH...` overrides auto-discovery.
- Environment overrides (lower priority than CLI flags): `IGNORELINT_VERBOSE`, `IGNORELINT_FAIL_ON`, `NO_COLOR` (disables colour per the no-color.org convention; colour also requires a TTY).
- Four output formatters (`src/formatter/`): `human` (colour, TTY-aware), `json`, `checkstyle`, `sarif`; SARIF embeds `VERSION` (kept in sync with `shard.yml` in `src/version.cr`).
- Exit codes: `0` no issues at/above `--fail-on`, `1` issues found at/above the threshold, `2` invalid CLI arguments.
- Container wiring: `entrypoint.d/5000-start.sh` runs `sleep infinity` (no explicit `CMD`); `command.d/get-ignorelint-version` prints the `ignorelint` version for self-test `test.d/1100-check-version.sh`.
