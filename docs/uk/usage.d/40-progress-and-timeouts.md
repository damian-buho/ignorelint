<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Стежте за перебігом і обмежте запит політики

Кожен запуск пише `linting N file(s)…` у стандартний потік помилок перед першим файлом і `checked N file(s) in Xms (F fixes, P pf-cli calls)` після останнього, тож повільне дерево не виглядає зависшим; `--quiet` вимикає обидва рядки. Політика projectfile читається через `pf-cli`, якому дається 30 секунд на відповідь; `IGNORELINT_PF_CLI_TIMEOUT` задає інше ціле число секунд. Після таймауту ignorelint попереджає й продовжує лише з прапорцями та середовищем. Ctrl-C друкує `interrupted, cleaning up…` і завершується з кодом `130`.

Людський формат і `gnu` виводять кожен файл одразу; `json`, `checkstyle`, `junit`, `sarif` та інші формати звітів накопичують усе й друкують один раз наприкінці.
