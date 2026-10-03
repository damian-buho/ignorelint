<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Configuration

Lint policy lives in the `org.ignorelint` subtree of `projectfile.yaml` — no separate dotfile. The document is never parsed by ignorelint itself: the subtree is read through `pf-cli get`, so every encoding (`projectfile.yaml`, `.toml`, `.json`), include fragment, and interpolation pf-cli understands works with no extra code. At startup, `--config` names the document explicitly; otherwise `./projectfile.yaml`, `./projectfile.toml`, then `./projectfile.json` in the working directory is used when present. A missing or unreadable explicit file exits `2`; a discovered file with problems warns on standard error and falls back to defaults.

```yaml
org:
  ignorelint:
    fail-on: warn            # error | warn | info
    format: json             # human | gnu | json | checkstyle | junit | gitlab_codeclimate | codacy | sonarqube | sarif (tty = human)
    fix: false               # rewrite files in place
    recursive: true          # walk subdirectories
    verbose: false           # print the discovery report
    disabled-rules:          # skip these codes for the whole run
      - IG-020
    override:                # per-rule severity, applied before --fail-on
      error: [IG-020]
      warning: [IG-001]
      info: [IG-003]
```

`disabled-rules` also accepts one comma-separated string, and `fail_on` / `disabled_rules` spellings work. `override` buckets accept a list or one comma-separated string each, and `warn` works as an alias of `warning`. Unknown keys warn instead of failing, so newer policy never breaks older binaries. Without `pf-cli` on `PATH`, an info notice is printed and only flags plus environment apply — the run never fails for a missing reader.

Precedence is explicit flags, then environment, then the projectfile subtree, then built-in defaults. `--disabled-rules` on the command line replaces the file list entirely. Overrides merge per code — a flag beats the environment for that code, the environment beats the file — so mixed planes compose instead of colliding. Every option is available on all three planes except `--diff`, which stays per-invocation by design.

`IGNORELINT_*` variables mirror their flags for CI systems that set policy once; `ignorelint --help` lists them. `IGNORELINT_RECURSIVE` and `IGNORELINT_FIX` accept `1`/`true`-style values; `0`, `false`, `no`, `n` and `off` disable. `SHELL_VERBOSITY=1` acts as `-v` and `-1` as `-q`. `NO_COLOR` disables colour following the no-color.org convention; colour also requires a terminal unless `FORCE_COLOR` or `--ansi` is set, and `--no-ansi` beats both.

Each rule’s default severity is in [the rules reference](rules.md).

<!-- textlint-enable -->
