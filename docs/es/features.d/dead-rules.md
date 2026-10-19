<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Detección de reglas muertas contra el sistema de archivos

- Una regla se marca como obsoleta solo con evidencia, una ruta eliminada o una grafía casi igual, así un clon recién hecho queda en silencio. Ver la [referencia de reglas](../how-to/rules.md).
- Los patrones negados se omiten, ya que reincluyen en lugar de ignorar.
- Los patrones que salen del árbol se omiten en lugar de explorarse.

<!-- textlint-enable -->
