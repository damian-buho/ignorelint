<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Descubrimiento de todo el árbol para monorepos

- Sin rutas, los archivos ignore se encuentran solos: un directorio, o todo el árbol con `--recursive`. Ver la [referencia CLI](docs/cli.md).
- Los hallazgos usan rutas relativas al directorio de trabajo en orden, para una salida estable entre ejecuciones.
- Los directorios ocultos, `node_modules` y los enlaces simbólicos se omiten, para no revisar nunca internos, dependencias ni ciclos de enlaces.
- Las rutas explícitas reemplazan al descubrimiento.

<!-- textlint-enable -->
