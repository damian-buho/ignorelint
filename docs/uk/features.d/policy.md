<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Політика живе у projectfile.yaml

- Політика лінту (`fail-on`, `format`, `fix`, `disabled-rules`) живе у піддереві `org.ignorelint` файла `projectfile.yaml`, тож один файл несе ідентичність проєкту і правила. Див. [довідник CLI](docs/cli.md).
- Піддерево читається через pf-cli, тож документи TOML і JSON плюс спільні include-фрагменти працюють без зайвого коду; без pf-cli у `PATH` прапорці й середовище діють як завжди.
- Кожна опція задається трьома способами — прапорець, середовище `IGNORELINT_*`, піддерево projectfile — прапорці перемагають середовище, а воно файл, тож типові CI і локальні перевизначення поєднуються, а не конфліктують.
- `--config` вказує на інший projectfile, коли одна копія перевіряє іншу, а `IGNORELINT_CONFIG` робить те саме для систем, що налаштовуються лише середовищем.
- Невідомі ключі попереджають замість помилки, тож політика, написана для новішої версії, ніколи не ламає старішу.

<!-- textlint-enable -->
