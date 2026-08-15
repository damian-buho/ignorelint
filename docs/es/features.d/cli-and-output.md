<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# CLI, formatos de salida y códigos de salida

- Flags: `--fail-on=LEVEL` (`error`|`warn`|`info`, por defecto `error`), `--format=FORMAT` (`human`|`json`|`checkstyle`|`sarif`, por defecto `human`), `--fix`, `--verbose`/`-v`, `--version`/`-V`, `--help`/`-h`; un `PATH...` posicional anula el autodescubrimiento.
- Variables de entorno que sobrescriben (menor prioridad que los flags de CLI): `IGNORELINT_VERBOSE`, `IGNORELINT_FAIL_ON`, `NO_COLOR` (desactiva el color según la convención no-color.org; el color además requiere TTY).
- Cuatro formateadores de salida (`src/formatter/`): `human` (color, consciente de TTY), `json`, `checkstyle`, `sarif`; SARIF incrusta `VERSION` (mantenida en sincronía con `shard.yml` en `src/version.cr`).
- Códigos de salida: `0` sin problemas en el nivel `--fail-on` o por encima, `1` problemas encontrados en el umbral o por encima, `2` argumentos de CLI inválidos.
- Cableado del contenedor: `entrypoint.d/5000-start.sh` ejecuta `sleep infinity` (sin `CMD` explícito); `command.d/get-ignorelint-version` imprime la versión de `ignorelint` para la autoprueba `test.d/1100-check-version.sh`.
