<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# CLI reference

Synopsis: `ignorelint [OPTIONS] [PATH…]`. With no paths, known ignore files are discovered automatically.

## Flags

| Flag | Default | Meaning |
|---|---|---|
| `--fail-on=LEVEL` | `error` | Exit non-zero on `error`, `warn`, or `info` and above |
| `--format=FORMAT` | `human` | `human`, `json`, `checkstyle`, or `sarif` |
| `--fix` | off | Rewrite files to correct deterministic issues (see [rules](rules.md)) |
| `--recursive` / `-r` | off | Search subdirectories, not just the working directory |
| `--verbose` / `-v` | off | Print the discovery report |
| `--version` / `-V`, `--help` / `-h` | — | Print version or help to standard output |

## Environment

`IGNORELINT_VERBOSE`, `IGNORELINT_FAIL_ON`, and `IGNORELINT_RECURSIVE` mirror their flags for CI systems that set policy once. Explicit flags always win. `IGNORELINT_VERBOSE` and `IGNORELINT_RECURSIVE` accept `1`/`true`-style values; `0`, `false`, `no`, `n`, and `off` disable. `NO_COLOR` disables colour following the no-color.org convention; colour also requires a terminal.

## Discovery

With no `PATH` arguments the working directory is scanned for the [recognised filenames](formats.md). With `--recursive`, the whole tree is walked instead: paths are reported relative to the working directory in sorted order, while hidden directories, `node_modules`, and symlinks are skipped. Explicit `PATH` arguments override discovery entirely.

## Output and exit codes

Results go to standard output; diagnostics (bad flags, missing files, unexpected errors) go to standard error, so machine-readable output stays parseable. Exit `0` means no issues at or above `--fail-on`, `1` means issues found, `2` means invalid arguments. `--help` and `--version` print to standard output.

## Container

The image runs `sleep infinity` as its service (no explicit `CMD`); shell in to use it. `command.d/get-ignorelint-version` prints the binary version for the self-test in `test.d/1100-check-version.sh`.
