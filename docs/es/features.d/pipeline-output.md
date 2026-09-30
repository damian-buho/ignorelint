<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Salida que los pipelines pueden procesar

- Diez renderizados — legible, GNU, JSON, Checkstyle, JUnit, Code Climate, Codacy, SonarQube, SARIF y el alias `tty` de la salida legible — para que los resultados alimenten terminales, todas las grandes plataformas de revisión y el escaneo de código por igual. Ver la [referencia de formatos](docs/how-to/formats.md).
- Los diagnósticos van al error estándar, para que la salida estándar procesable siga siendo válida.
- Los umbrales de severidad deciden el código de salida, para que las advertencias solo rompan una compilación cuando se pida.

<!-- textlint-enable -->
