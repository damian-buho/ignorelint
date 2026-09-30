<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Output pipelines can parse

- Ten renderings — human, GNU, JSON, Checkstyle, JUnit, Code Climate, Codacy, SonarQube, SARIF and the `tty` alias of human — so results feed terminals, every major review platform and code scanning alike. See the [formats reference](docs/how-to/formats.md).
- Diagnostics go to standard error, so machine-readable standard output stays parseable.
- Severity thresholds decide the exit code, so warnings break a build only when asked.
