<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Salida que los pipelines pueden procesar

- Versiones legibles, JSON, Checkstyle y SARIF, para alimentar terminales y escaneo de código por igual. Ver la [referencia CLI](docs/cli.md).
- Los diagnósticos van al error estándar, para que la salida estándar procesable siga siendo válida.
- Los umbrales de severidad deciden el código de salida, para que las advertencias solo rompan una compilación cuando se pida.

<!-- textlint-enable -->
