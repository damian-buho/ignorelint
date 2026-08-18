<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Підтримувані формати ignore-файлів

- Лінтер для файлів `*ignore`, на чистому Crystal (`shard.yml`, `crystal >= 1.13.0`); зібраний `--release --no-debug` до `/export/usr/local/bin/ignorelint` на стадії `compile-crystal` (база `b19/crystal`, APT builder-стадії `libxml2-dev`), runtime `b19/ubuntu/resolute`.
- 25 імен файлів розпізнається в `KNOWN_FILES` (`src/file_type.cr`): `.gitignore`, `.dockerignore`, `.containerignore`, `.npmignore`, `.yarnignore`, `.eslintignore`, `.prettierignore`, `.stylelintignore`, `.tfignore`, `.helmignore`, `.gcloudignore`, `.ebignore`, `.slugignore`, `.vercelignore`, `.cfignore`, `.openapi-generator-ignore`, `.cursorignore`, `.aiderignore`, `.aiexclude`, `.codeiumignore`, `.claudeignore`, `.ignore`, `.rgignore`, `.fdignore`, `.eleventyignore`.
- Вісім специфічних для формату glob-драйверів у `src/driver/` (`gitignore`, `dockerignore`, `npmignore`, `prettierignore`, `eslintignore`, `helmignore`, `slugignore`, `cfignore`) моделюють семантику збігів кожного інструмента; `.containerignore` повторно використовує драйвер dockerignore, а для нерозпізнаних базових імен діє лише універсальний набір правил.
- Без аргументів PATH CLI автоматично виявляє кожен запис із `KNOWN_FILES`, присутній у поточному каталозі; `--verbose` виводить звіт знайдено/не знайдено.
- Специфікації за форматами лежать у `specifications/` (24 формати), а золоті фікстури — у `spec/fixtures/{valid,broken}/`.

<!-- textlint-enable -->
