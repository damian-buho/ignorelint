<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# CLI, формати виводу та коди виходу

- Прапорці: `--fail-on=LEVEL` (`error`|`warn`|`info`, типово `error`), `--format=FORMAT` (`human`|`json`|`checkstyle`|`sarif`, типово `human`), `--fix`, `--verbose`/`-v`, `--version`/`-V`, `--help`/`-h`; позиційний `PATH...` перекриває автовиявлення.
- Перевизначення через середовище (нижчий пріоритет за CLI-прапорці): `IGNORELINT_VERBOSE`, `IGNORELINT_FAIL_ON`, `NO_COLOR` (вимикає кольори за конвенцією no-color.org; колір також потребує TTY).
- Чотири форматувальники виводу (`src/formatter/`): `human` (колір, з урахуванням TTY), `json`, `checkstyle`, `sarif`; SARIF вбудовує `VERSION` (синхронізована з `shard.yml` у `src/version.cr`).
- Коди виходу: `0` — проблем на рівні `--fail-on` чи вище немає, `1` — знайдено проблеми на рівні порога чи вище, `2` — недійсні аргументи CLI.
- Підключення всередині контейнера: `entrypoint.d/5000-start.sh` виконує `sleep infinity` (без явного `CMD`); `command.d/get-ignorelint-version` виводить версію `ignorelint` для самоперевірки `test.d/1100-check-version.sh`.

<!-- textlint-enable -->
