<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Detección de reglas muertas contra el sistema de archivos

- Los patrones literales se comprueban por existencia y los globs por al menos una coincidencia, para que las rutas eliminadas aparezcan como reglas obsoletas. Ver la [referencia de reglas](docs/rules.md).
- Los patrones negados se omiten, ya que reincluyen en lugar de ignorar.
- Los patrones que salen del árbol se omiten en lugar de explorarse.

<!-- textlint-enable -->
