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
| `--diff` | off | Preview what `--fix` would change without writing (see [rules](rules.md)) |
| `--recursive` / `-r` | off | Search subdirectories, not just the working directory |
| `--verbose` / `-v` | off | Print the discovery report |
| `--version` / `-V`, `--help` / `-h` | — | Print version or help to standard output |
| `--stdin` | off | Lint piped content instead of files (requires `--file`) |
| `--file=NAME` | — | Filename for `--stdin` input; drives format detection and display |
| `--disabled-rules=CODES` | — | Skip rules entirely; comma-separated tags like `IG-001,IG-020` |
| `--config=PATH` | `./projectfile.*` | Projectfile read via pf-cli for the `org.ignorelint` policy subtree (see [Configuration](#configuration)) |

## Configuration

Lint policy lives in the `org.ignorelint` subtree of `projectfile.yaml` — no separate dotfile. The document is never parsed by ignorelint itself: the subtree is read through `pf-cli get`, so every encoding (`projectfile.yaml`, `.toml`, `.json`), include fragment, and interpolation pf-cli understands works with no extra code. At startup, `--config` names the document explicitly; otherwise `./projectfile.yaml`, `./projectfile.toml`, then `./projectfile.json` in the working directory is used when present. A missing or unreadable explicit file exits `2`; a discovered file with problems warns on standard error and falls back to defaults.

```yaml
org:
  ignorelint:
    fail-on: warn            # error | warn | info
    format: json             # human | json | checkstyle | sarif
    fix: false               # rewrite files in place
    recursive: true          # walk subdirectories
    verbose: false           # print the discovery report
    disabled-rules:          # skip these codes for the whole run
      - IG-020
```

`disabled-rules` also accepts one comma-separated string, and `fail_on` / `disabled_rules` spellings work. Unknown keys warn instead of failing, so newer policy never breaks older binaries. Without `pf-cli` on `PATH`, an info notice is printed and only flags plus environment apply — the run never fails for a missing reader.

Precedence is explicit flags, then environment, then the projectfile subtree, then built-in defaults. `--disabled-rules` on the command line replaces the file list entirely. Every option is available on all three planes except `--diff`, which stays per-invocation by design.

## Environment

`IGNORELINT_VERBOSE`, `IGNORELINT_FAIL_ON`, `IGNORELINT_FORMAT`, `IGNORELINT_FIX`, `IGNORELINT_RECURSIVE`, `IGNORELINT_DISABLED_RULES`, and `IGNORELINT_CONFIG` mirror their flags for CI systems that set policy once. Explicit flags always win over environment, which wins over the [projectfile subtree](#configuration). `IGNORELINT_VERBOSE`, `IGNORELINT_RECURSIVE`, and `IGNORELINT_FIX` accept `1`/`true`-style values; `0`, `false`, `no`, `n`, and `off` disable. Disabled rules take comma-separated tags (`IG-001,IG-020`, case-insensitive); unknown codes match nothing. `NO_COLOR` disables colour following the no-color.org convention; colour also requires a terminal.

## Discovery

With no `PATH` arguments the working directory is scanned for the [recognised filenames](formats.md). With `--recursive`, the whole tree is walked instead: paths are reported relative to the working directory in sorted order, while hidden directories, `node_modules`, and symlinks are skipped. Explicit `PATH` arguments override discovery entirely. `--stdin` skips discovery altogether and takes neither `PATH` arguments nor a working-directory scan.

## Standard input

`ignorelint --stdin --file=.gitignore < buffer` lints piped content as if it were that filename: the basename drives format detection and the given name is the display path. Filesystem checks resolve against the working directory (see [rules](rules.md)). Missing `--file`, or combining `--stdin` with `PATH` arguments, exits `2`. With `--fix`, the corrected document goes to standard output while the issue report goes to standard error, so editors can replace the buffer from standard output without parsing the report out of it.

## Output and exit codes

Results go to standard output; diagnostics (bad flags, missing files, unexpected errors) go to standard error, so machine-readable output stays parseable. Exit `0` means no issues at or above `--fail-on`, `1` means issues found, `2` means invalid arguments. `--help` and `--version` print to standard output.

## Container

The image runs `sleep infinity` as its service (no explicit `CMD`); shell in to use it. Projectfile policy inside the container needs `pf-cli` on `PATH` — mount it or install it, otherwise pass policy explicitly with `--config` pointing at a mounted projectfile (still read via pf-cli) or fall back to flags and environment. `command.d/get-ignorelint-version` prints the binary version for the self-test in `test.d/1100-check-version.sh`.

<!-- textlint-enable -->
