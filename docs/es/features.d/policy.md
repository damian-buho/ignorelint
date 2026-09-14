<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# La política vive en projectfile.yaml

- La política de lint (`fail-on`, `format`, `fix`, `disabled-rules`) vive en el subárbol `org.ignorelint` de `projectfile.yaml`, así un solo archivo lleva la identidad del proyecto y sus reglas. Ver la [referencia CLI](docs/cli.md).
- El subárbol se lee vía pf-cli, así los documentos TOML y JSON más los fragmentos include compartidos funcionan sin código extra; sin pf-cli en el `PATH`, las banderas y el entorno siguen valiendo.
- Cada opción se configura de tres formas — bandera, entorno `IGNORELINT_*`, subárbol projectfile — con las banderas sobre el entorno y este sobre el archivo, así los valores de CI y los locales se combinan en vez de chocar.
- `--config` apunta a otro projectfile cuando una copia revisa otra, e `IGNORELINT_CONFIG` hace lo mismo para sistemas que solo configuran por entorno.
- Las claves desconocidas avisan en vez de fallar, así una política escrita para un binario nuevo nunca rompe uno viejo.

<!-- textlint-enable -->
