<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Output pipelines can parse

- Human, JSON, Checkstyle, and SARIF renderings, so results feed terminals and code scanning alike. See the [usage guide](USAGE.md).
- Diagnostics go to standard error, so machine-readable standard output stays parseable.
- Severity thresholds decide the exit code, so warnings break a build only when asked.
