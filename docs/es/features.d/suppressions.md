<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Supresiones para excepciones intencionales

- Una directiva en un comentario silencia los códigos listados en el siguiente patrón, para que las entradas correctas dejen de fallar ejecuciones. Ver la [referencia de reglas](docs/rules.md).
- Las directivas cubren todos los códigos, incluidos los hallazgos de reglas muertas del sistema de archivos.
- Los códigos desconocidos no coinciden con nada, para que una directiva mal escrita falle de forma segura y el hallazgo siga apareciendo.
- Los hallazgos suprimidos nunca llegan a la autocorrección ni a los códigos de salida.
- `--disabled-rules` (o `IGNORELINT_DISABLED_RULES`) omite los códigos listados en toda la ejecución, para que una comprobación con la que el equipo no está de acuerdo deje de fallar compilaciones sin directivas por línea. Ver la [referencia CLI](docs/cli.md).

<!-- textlint-enable -->
