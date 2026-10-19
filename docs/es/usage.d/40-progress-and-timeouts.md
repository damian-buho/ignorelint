<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Seguir el avance y acotar la consulta de política

Cada ejecución escribe `linting N file(s)…` en la salida de errores antes del primer archivo y `checked N file(s) in Xms (F fixes, P pf-cli calls)` tras el último, así un árbol lento nunca parece colgado; `--quiet` silencia ambas. La política del projectfile se lee con `pf-cli`, que dispone de 30 segundos para responder; `IGNORELINT_PF_CLI_TIMEOUT` fija otro número entero de segundos. Al agotarse el plazo, ignorelint avisa y sigue solo con opciones y entorno. Ctrl-C escribe `interrupted, cleaning up…` y termina con `130`.

Los formatos humano y `gnu` emiten cada archivo al terminar; `json`, `checkstyle`, `junit`, `sarif` y los demás informes se acumulan y se imprimen una sola vez al final.
