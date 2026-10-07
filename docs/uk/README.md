<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
pf-cli-managed: yes
-->

<!-- textlint-disable terminology,common-misspellings -->

[English](../../README.md) · [Español](../es/README.md)

<p align="center"><img src="docs/logo.png" alt="логотип" width="200"></p>

# Ignorelint

Ignorelint — лінтер і автокоректор для ignore-файлів як-от .gitignore, .dockerignore та .npmignore, написаний на Crystal. Розпізнає 25 назв файлів у восьми специфічних для форматів glob-драйверах і звітує 25 діагностичних правил із десятьма форматами виводу — від людиночитного та GNU до JUnit, Code Climate, Codacy, SonarQube і SARIF.

[![Stand with Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://damian-buho.github.io/support-ukraine/) [![Projectfile inside](https://badges.kiota.ch/static/v1?label=projectfile&message=inside&labelColor=0d0d0d&color=8c6723&style=flat-square)](https://projectfile.org) [![License](https://badges.kiota.ch/static/v1?label=license&message=MIT&color=1e5913&style=flat-square)](LICENSE) [![Cosign](https://badges.kiota.ch/static/v1?label=cosign&message=enabled&color=1e5913&style=flat-square)](https://docs.sigstore.dev/cosign/verifying/verify/) [![PRs welcome](https://badges.kiota.ch/static/v1?label=PRs&message=welcome&color=1e5913&style=flat-square)](CONTRIBUTING.md) [![REUSE compliance](https://api.reuse.software/badge/codeberg.org/damian-buho/ignorelint)](https://api.reuse.software/info/codeberg.org/damian-buho/ignorelint)

![Project status](https://badges.kiota.ch/static/v1?label=status&message=maintained&color=1d63ed&style=flat-square) [![Last commit on kiota.ch](https://badges.kiota.ch/gitea/last-commit/damian-buho/ignorelint?gitea_url=https://kiota.ch&label=last%20commit%20on%20kiota.ch&style=flat-square)](https://kiota.ch/damian-buho/ignorelint) [![Last commit on Codeberg](https://badges.kiota.ch/gitea/last-commit/damian-buho/ignorelint?gitea_url=https://codeberg.org&label=last%20commit%20on%20Codeberg&style=flat-square)](https://codeberg.org/damian-buho/ignorelint) [![Last commit on GitHub](https://badges.kiota.ch/github/last-commit/damian-buho/ignorelint?label=last%20commit%20on%20GitHub&style=flat-square)](https://github.com/damian-buho/ignorelint)

[![Publish pipeline on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/published.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Vulnerability audit on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/audited.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Dependency freshness on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/check-outdated.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Analysis sweep on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/analyzed.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions)

[![Publish pipeline on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/published.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Vulnerability audit on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/audited.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Dependency freshness on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/check-outdated.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Analysis sweep on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/analyzed.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions)

## Можливості

- Автовиправлення, що зберігає зміст файлу
- Виявлення мертвих правил проти живої файлової системи
- Пошук усім деревом для монорепозиторіїв
- Вивід, який розбирають конвеєри
- Політика живе у projectfile.yaml
- Придушення для навмисних винятків

Також успадковує можливості B19 / Ubuntu — повний перелік див. у [Можливості](FEATURES.md).

## Що надає цей проєкт

- **CI-дія** `damian-buho/ignorelint@2.0.2`
- **Виконуваний файл** `ignorelint` — команда `ignorelint`
- **Образ контейнера** `ghcr.io/damian-buho/ignorelint:latest`
- **Образ контейнера** `damianbuho/ignorelint:latest`

## Встановлення

### Образ контейнера

Завантажте опублікований образ контейнера:

#### Завантажити з GHCR — linux/amd64, linux/arm64

```sh
docker pull ghcr.io/damian-buho/ignorelint:latest
alias ignorelint='docker run --rm --user "$(id -u):$(id -g)" --group-add 0 --volume "$PWD:/app/ws" --workdir /app/ws ghcr.io/damian-buho/ignorelint:latest ignorelint'
```

#### Завантажити з DockerHub — linux/amd64

```sh
docker pull damianbuho/ignorelint:latest
alias ignorelint='docker run --rm --user "$(id -u):$(id -g)" --group-add 0 --volume "$PWD:/app/ws" --workdir /app/ws damianbuho/ignorelint:latest ignorelint'
```

Стабільні випуски також публікують теґи `X.Y.Z`, `X.Y` і `X` — завантажте той рівень точності, який хочете зафіксувати.

Якщо наведені вище реєстри недоступні, завантажте з джерела:

#### Завантажити з Kiota — linux/amd64

```sh
docker pull kiota.ch/damian-buho/ignorelint:latest
alias ignorelint='docker run --rm --user "$(id -u):$(id -g)" --group-add 0 --volume "$PWD:/app/ws" --workdir /app/ws kiota.ch/damian-buho/ignorelint:latest ignorelint'
```

Потім запускайте його так, ніби його встановлено, — псевдонім виконує кожен приклад як написано в поточному каталозі:

```sh
ignorelint --help
```

### Готовий бінарний файл

Завантажте готовий бінарний файл для своєї платформи з випусків на GitHub:

```sh
mkdir -p ~/.local/bin && curl --fail --location --output ~/.local/bin/ignorelint https://github.com/damian-buho/ignorelint/releases/latest/download/ignorelint-$(uname -s | tr A-Z a-z)-$(uname -m) && chmod +x ~/.local/bin/ignorelint
~/.local/bin/ignorelint --help
```

Опубліковано для: `linux/amd64`, `linux/arm64`

## Використання

Запускайте його як крок робочого процесу GitHub Actions:

```yaml
- uses: damian-buho/ignorelint@2.0.2
```

Дія приймає такі вхідні параметри:

| Параметр | Типове значення | Опис |
| --- | --- | --- |
| `paths` | | Newline-separated ignore files to lint. Empty enables auto-discovery. |
| `recursive` | `false` | Search subdirectories for ignore files (skips hidden dirs, node_modules, symlinks). |
| `config_file` | | Projectfile path read via pf-cli for the org.ignorelint policy subtree. |
| `fail_on` | `error` | Severity threshold that fails the job: none \| error \| warn \| info |
| `fix` | `false` | Autofix deterministically fixable issues (workspace will be modified). |
| `disabled_rules` | | Comma-separated rule tags to skip entirely (e.g. IG-001,IG-020). |
| `error` | | Comma-separated rule tags to promote to error severity. |
| `warning` | | Comma-separated rule tags to set to warning severity. |
| `info` | | Comma-separated rule tags to demote to info severity. |
| `sarif` | `false` | Also emit SARIF for github/codeql-action/upload-sarif. |
| `upload_sarif` | `false` | Upload the SARIF report to GitHub code scanning (implies sarif; needs security-events: write). |
| `comment` | `false` | Post the human report as a sticky comment on the triggering pull request. |
| `version` | | Image tag to pull (e.g. latest, 1.2.3). Empty follows the release the action is pinned to, else latest. |
| `image` | | Override the full image reference. Takes precedence over `version`. |
| `github_token` | | Token used to post PR comments. Defaults to the workflow github.token when empty. |

### ignorelint

```console
$ ignorelint --help
Description:
  Linter for *ignore files (.gitignore, .dockerignore, .eslintignore, etc.)

Usage:
  ignorelint [options] [--] [<paths>...]

Arguments:
  paths                                          Files to lint; none discovers them in the current directory, a lone - reads stdin

Options:
      --fail-on=FAIL-ON                          Exit non-zero at this severity or worse (error|warn|info|none, default: error)
      --no-fail                                  Report every finding but always exit 0 (beats --fail-on)
      --plain                                    Human output as one undecorated path:line [CODE] severity: message record per line
      --file-path-in-report=FILE-PATH-IN-REPORT  Record this path instead of the linted one in machine-readable reports
      --format=FORMAT                            Output format (human|tty|gnu|json|checkstyle|junit|gitlab_codeclimate|codacy|sonarqube|sarif, default: human)
  -r, --recursive                                Search subdirectories for *ignore files (skips hidden dirs, node_modules, symlinks)
      --fix                                      Auto-fix deterministically fixable issues (IG-001,002,003,008,015,018,022,023,024)
      --diff                                     Preview auto-fix changes without writing (cannot combine with --fix)
      --stdin                                    Lint piped content instead of files (requires --file; a lone - path does the same)
      --file=FILE                                Filename for --stdin input (drives format detection)
      --disabled-rules=DISABLED-RULES            Skip rules entirely (comma-separated tags, e.g. IG-001,IG-020) (multiple values allowed)
      --error=ERROR                              Promote rules to error severity (comma-separated tags, e.g. IG-020) (multiple values allowed)
      --warning=WARNING                          Set rules to warning severity (comma-separated tags) (multiple values allowed)
      --info=INFO                                Demote rules to info severity (comma-separated tags; applied last) (multiple values allowed)
      --disable-ignore-pragma                    Parse suppression directives but apply none; IG-026 still lists them
      --config=CONFIG                            Projectfile read via pf-cli for the org.ignorelint policy subtree (default: ./projectfile.*)
  -h, --help                                     Display help for the given command. When no command is given display help for the ignorelint command
      --silent                                   Do not output any message
  -q, --quiet                                    Only errors are displayed. All other output is suppressed
  -V, --version                                  Display this application version
      --ansi|--no-ansi                           Force (or disable --no-ansi) ANSI output
  -n, --no-interaction                           Do not ask any interactive question
  -v|vv|vvv, --verbose                           Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug

Help:
  When no path is given, discovers supported *ignore files in the current directory.
  Discovery and diagnostics go to stderr; stdout carries only the report.

  Environment variables:
    SHELL_VERBOSITY=1          Same as -v (-1 same as -q)
    IGNORELINT_FAIL_ON=LEVEL   Same as --fail-on (error|warn|info|none)
    IGNORELINT_NOFAIL=1        Same as --no-fail
    IGNORELINT_FORMAT=FORMAT   Same as --format
    IGNORELINT_FIX=1           Same as --fix
    IGNORELINT_RECURSIVE=1     Same as --recursive
    IGNORELINT_DISABLED_RULES=CODES Same as --disabled-rules
    IGNORELINT_OVERRIDE_ERROR=CODES Same as --error
    IGNORELINT_OVERRIDE_WARNING=CODES Same as --warning
    IGNORELINT_OVERRIDE_INFO=CODES Same as --info
    IGNORELINT_CONFIG=PATH     Same as --config
    IGNORELINT_DISABLE_IGNORE_PRAGMA=1 Same as --disable-ignore-pragma
    IGNORELINT_FILE_PATH_IN_REPORT=PATH Same as --file-path-in-report
    NO_COLOR=1                 Disable colored output (also TERM=dumb)
    FORCE_COLOR=1              Color even when piped (--ansi and --no-ansi beat both)
```

Приклади й довідка кожної команди — у [Використання](USAGE.md).

## Збирання

Клонуйте репозиторій разом із підмодулями:

```sh
git clone --recurse-submodules https://codeberg.org/damian-buho/ignorelint ignorelint && cd ignorelint
```

Зберіть бінарний файл із вихідного коду в `dist/`:

```sh
make crystal-build
```

Зберіть образ контейнера локально:

```sh
make container-build
```

- [Довідник із Makefile](../how-to/MAKEFILE.md)

Виконайте `make` без аргументів для типової цілі; виконайте `make help`, щоб переглянути всі цілі.

Для локального циклу розробки `make dev-container` піднімає dev-container.

Точки входу конвеєра:

- `make analyzed` — Запускає важкий аналіз (мутаційне тестування, бенчмарки)
- `make audited` — Повторно сканує закріплені залежності й опубліковані артефакти на нові вразливості
- `make check-outdated` — Звітує про кожну закріплену залежність, що відстає від upstream
- `make ready-to-publish` — Запускає псевдо-CI локально — збирає, тестує й сканує без публікації

## Документація

- [Configuration](../how-to/configuration.md)
- [Output formats reference](../how-to/formats.md)
- [Rules reference](../how-to/rules.md)

## Політики

- [Як зробити внесок](CONTRIBUTING.md)
- [Політика безпеки](SECURITY.md)
- [Як отримати підтримку](SUPPORT.md)
- [Кодекс поведінки](CODE_OF_CONDUCT.md)
- [Політика щодо ШІ та LLM](AI_POLICY.md)

## Посилання

- [Специфікація Projectfile](https://projectfile.org)

## Ліцензія

Цей проєкт ліцензовано на умовах MIT — див. файл [LICENSE](LICENSE) для подробиць.

<!-- textlint-enable -->
