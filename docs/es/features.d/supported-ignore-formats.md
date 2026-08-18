<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Formatos de archivos ignore soportados

- Linter para archivos `*ignore`, en Crystal nativo (`shard.yml`, `crystal >= 1.13.0`); compilado `--release --no-debug` a `/export/usr/local/bin/ignorelint` en la etapa `compile-crystal` (base `b19/crystal`, APT del builder `libxml2-dev`), runtime `b19/ubuntu/resolute`.
- 25 nombres de archivo reconocidos en `KNOWN_FILES` (`src/file_type.cr`): `.gitignore`, `.dockerignore`, `.containerignore`, `.npmignore`, `.yarnignore`, `.eslintignore`, `.prettierignore`, `.stylelintignore`, `.tfignore`, `.helmignore`, `.gcloudignore`, `.ebignore`, `.slugignore`, `.vercelignore`, `.cfignore`, `.openapi-generator-ignore`, `.cursorignore`, `.aiderignore`, `.aiexclude`, `.codeiumignore`, `.claudeignore`, `.ignore`, `.rgignore`, `.fdignore`, `.eleventyignore`.
- Ocho drivers de glob específicos del formato en `src/driver/` (`gitignore`, `dockerignore`, `npmignore`, `prettierignore`, `eslintignore`, `helmignore`, `slugignore`, `cfignore`) modelan la semántica de coincidencia de cada herramienta; `.containerignore` reutiliza el driver dockerignore, y los nombres base no reconocidos caen solo a las reglas universales.
- Sin argumentos PATH el CLI autodescubre toda entrada de `KNOWN_FILES` presente en el directorio actual; `--verbose` imprime un informe de encontrados/no encontrados.
- Los documentos de especificación por formato viven en `specifications/` (24 formatos) y los fixtures dorados en `spec/fixtures/{valid,broken}/`.

<!-- textlint-enable -->
