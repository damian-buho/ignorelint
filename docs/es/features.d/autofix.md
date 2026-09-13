<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Autocorrección que preserva el significado del archivo

- `--fix` corrige problemas deterministas en el lugar, para limpiar sin editar a mano. Ver la [referencia de reglas](docs/rules.md).
- Las correcciones de una misma línea se combinan en una sola pasada, para converger en una ejecución.
- Los archivos se reescriben de forma atómica conservando los permisos, para que una interrupción nunca deje un archivo truncado.
- Las negaciones nunca se reordenan y los enlaces simbólicos nunca se reescriben, para que una corrección no cambie lo que el archivo ignora.
- Los hallazgos corregidos se reetiquetan y quedan fuera de la decisión de fallo, para que los códigos de salida reflejen lo pendiente.

<!-- textlint-enable -->
