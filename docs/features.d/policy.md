<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Policy lives in projectfile.yaml

- Lint policy (`fail-on`, `format`, `fix`, `disabled-rules`, `override`) lives in the `org.ignorelint` subtree of `projectfile.yaml`, so one file carries project identity and linter rules together. See the [CLI reference](docs/cli.md).
- The subtree is read through pf-cli, so TOML and JSON documents plus shared include fragments work with no extra code; without pf-cli on `PATH`, flags and environment still apply.
- Every option is settable three ways — flag, `IGNORELINT_*` environment, projectfile subtree — with flags beating environment and environment beating file, so CI defaults and local overrides compose instead of colliding.
- `--config` points at another projectfile when one checkout lints another, and `IGNORELINT_CONFIG` does the same for systems that configure through environment only.
- Unknown keys warn instead of failing, so a policy written for a newer binary never breaks an older one.
