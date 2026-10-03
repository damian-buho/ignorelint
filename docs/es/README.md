<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
pf-cli-managed: yes
-->

<!-- textlint-disable terminology,common-misspellings -->

[English](../../README.md) · [Українська](../uk/README.md)

# Ignorelint

Ignorelint es un linter y corrector automático para archivos de ignorados como .gitignore, .dockerignore y .npmignore, escrito en Crystal. Reconoce 25 nombres de archivo a través de ocho controladores de globs específicos de formato e informa 25 reglas de diagnóstico con diez formatos de salida, desde el legible y GNU hasta JUnit, Code Climate, Codacy, SonarQube y SARIF.

[![Stand with Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://damian-buho.github.io/support-ukraine/) [![Projectfile inside](https://badges.kiota.ch/static/v1?label=projectfile&message=inside&labelColor=0d0d0d&color=8c6723&style=flat-square)](https://projectfile.org) [![License](https://badges.kiota.ch/static/v1?label=license&message=MIT&color=1e5913&style=flat-square)](LICENSE) [![Cosign](https://badges.kiota.ch/static/v1?label=cosign&message=enabled&color=1e5913&style=flat-square)](https://docs.sigstore.dev/cosign/verifying/verify/) [![PRs welcome](https://badges.kiota.ch/static/v1?label=PRs&message=welcome&color=1e5913&style=flat-square)](CONTRIBUTING.md) [![REUSE compliance](https://api.reuse.software/badge/codeberg.org/damian-buho/ignorelint)](https://api.reuse.software/info/codeberg.org/damian-buho/ignorelint)

![Project status](https://badges.kiota.ch/static/v1?label=status&message=maintained&color=1d63ed&style=flat-square) [![Last commit on kiota.ch](https://badges.kiota.ch/gitea/last-commit/damian-buho/ignorelint?gitea_url=https://kiota.ch&label=last%20commit%20on%20kiota.ch&style=flat-square)](https://kiota.ch/damian-buho/ignorelint) [![Last commit on Codeberg](https://badges.kiota.ch/gitea/last-commit/damian-buho/ignorelint?gitea_url=https://codeberg.org&label=last%20commit%20on%20Codeberg&style=flat-square)](https://codeberg.org/damian-buho/ignorelint) [![Last commit on GitHub](https://badges.kiota.ch/github/last-commit/damian-buho/ignorelint?label=last%20commit%20on%20GitHub&style=flat-square)](https://github.com/damian-buho/ignorelint)

[![Publish pipeline on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/published.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Vulnerability audit on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/audited.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Dependency freshness on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/check-outdated.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Analysis sweep on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/analyzed.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions)

[![Publish pipeline on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/published.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Vulnerability audit on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/audited.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Dependency freshness on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/check-outdated.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Analysis sweep on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/analyze.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions)

## Características

- Autocorrección que preserva el significado del archivo
- Detección de reglas muertas contra el sistema de archivos
- Descubrimiento de todo el árbol para monorepos
- Salida que los pipelines pueden procesar
- La política vive en projectfile.yaml
- Supresiones para excepciones intencionales

También hereda las características de B19 / Ubuntu; consulta [Características](FEATURES.md) para ver la lista completa.

## Qué entrega este proyecto

- **Acción de CI** `damian-buho/ignorelint@1.7.1`
- **Ejecutable** `ignorelint` — comando `ignorelint`
- **Imagen de contenedor** `ghcr.io/damian-buho/ignorelint:latest`
- **Imagen de contenedor** `damianbuho/ignorelint:latest`

## Instalación

### Imagen de contenedor

Descarga la imagen de contenedor publicada:

#### Descargar de GHCR — linux/amd64, linux/arm64

```sh
docker pull ghcr.io/damian-buho/ignorelint:latest
alias ignorelint='docker run --rm --user "$(id -u):$(id -g)" --group-add 0 --volume "$PWD:/app/ws" --workdir /app/ws ghcr.io/damian-buho/ignorelint:latest ignorelint'
```

#### Descargar de DockerHub — linux/amd64

```sh
docker pull damianbuho/ignorelint:latest
alias ignorelint='docker run --rm --user "$(id -u):$(id -g)" --group-add 0 --volume "$PWD:/app/ws" --workdir /app/ws damianbuho/ignorelint:latest ignorelint'
```

Las versiones estables también publican las etiquetas `X.Y.Z`, `X.Y` y `X`: descarga el nivel de precisión que quieras fijar.

Si los registros anteriores no están disponibles, descarga desde el origen:

#### Descargar de Kiota — linux/amd64

```sh
docker pull kiota.ch/damian-buho/ignorelint:latest
alias ignorelint='docker run --rm --user "$(id -u):$(id -g)" --group-add 0 --volume "$PWD:/app/ws" --workdir /app/ws kiota.ch/damian-buho/ignorelint:latest ignorelint'
```

Después, ejecútalo como si estuviera instalado; el alias ejecuta cada ejemplo tal cual sobre el directorio actual:

```sh
ignorelint --help
```

### Binario precompilado

Descarga el binario precompilado para tu plataforma desde la última versión en GitHub:

```sh
curl --fail --location --output ignorelint https://github.com/damian-buho/ignorelint/releases/latest/download/ignorelint-$(uname -s | tr A-Z a-z)-$(uname -m | sed -e s/x86_64/amd64/ -e s/aarch64/arm64/) && chmod +x ignorelint
./ignorelint --help
```

Publicado para: `linux/amd64`, `linux/arm64`

## Uso

Ejecútalo como un paso de un flujo de trabajo de GitHub Actions:

```yaml
- uses: damian-buho/ignorelint@1.7.1
```

La acción acepta estas entradas:

| Entrada | Valor por defecto | Descripción |
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
| `comment` | `false` | Post the human report as a sticky comment on the triggering pull request. |
| `version` | | Image tag to pull (e.g. latest, 1.2.3). Empty follows the release the action is pinned to, else latest. |
| `image` | | Override the full image reference. Takes precedence over `version`. |
| `github_token` | | Token used to post PR comments. Defaults to the workflow github.token when empty. |

### ignorelint

```console
$ ignorelint --help
Usage: ignorelint [OPTIONS] [PATH...]

Linter for *ignore files (.gitignore, .dockerignore, .eslintignore, etc.)

Options:
    -h, --help                       Show this help
    -V, --version                    Show version
        --fail-on=LEVEL              Exit non-zero on LEVEL or worse (error|warn|info|none, default: error)
        --no-fail                    Report every finding but always exit 0 (beats --fail-on)
        --colors=WHEN                Color human output (auto|on|off, default: auto)
        --no-color                   Same as --colors=off
        --plain                      Human output as one undecorated path:line [CODE] severity: message record per line
    -q, --quiet                      Print only issues: no valid-file lines or info notices (cannot combine with --verbose)
        --file-path-in-report=PATH   Record PATH instead of the linted path in machine-readable reports
        --format=FORMAT              Output format (human|tty|gnu|json|checkstyle|junit|gitlab_codeclimate|codacy|sonarqube|sarif, default: human)
    -v, --verbose                    Show discovery output and extra diagnostics
    -r, --recursive                  Search subdirectories for *ignore files (skips hidden dirs, node_modules, symlinks)
        --fix                        Auto-fix deterministically fixable issues (IG-001,002,003,008,015,018,022,023,024)
        --diff                       Preview auto-fix changes without writing (cannot combine with --fix)
        --stdin                      Lint piped content instead of files (requires --file; a lone - PATH does the same)
        --file=NAME                  Filename for --stdin input (drives format detection)
        --disabled-rules=CODES       Skip rules entirely (comma-separated tags, e.g. IG-001,IG-020)
        --error=CODES                Promote rules to error severity (comma-separated tags, e.g. IG-020)
        --warning=CODES              Set rules to warning severity (comma-separated tags)
        --info=CODES                 Demote rules to info severity (comma-separated tags)
        --disable-ignore-pragma      Parse suppression directives but apply none; IG-026 still lists them
        --config=PATH                Projectfile read via pf-cli for the org.ignorelint policy subtree (default: ./projectfile.*)

When no PATH is given, discovers supported *ignore files in the current directory.
Discovery and diagnostics go to stderr; stdout carries only the report.

Environment variables:
  IGNORELINT_VERBOSE=1       Same as --verbose
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
  NO_COLOR=1                 Disable colored output (also IGNORELINT_NO_COLOR=1, TERM=dumb)
  FORCE_COLOR=1              Color even when piped (--colors beats it)
```

Los ejemplos y la ayuda de cada comando están en [Uso](USAGE.md).

## Compilación

Clona el repositorio con sus submódulos:

```sh
git clone --recurse-submodules https://codeberg.org/damian-buho/ignorelint ignorelint && cd ignorelint
```

Compila el binario desde el código fuente en `dist/`:

```sh
make crystal-build
```

Construye la imagen de contenedor en local:

```sh
make container-build
```

- [Referencia del Makefile](../how-to/MAKEFILE.md)

Ejecuta `make` sin argumentos para el destino predeterminado; ejecuta `make help` para listar todos los destinos.

Para el bucle de desarrollo local, `make dev-container` levanta el dev-container.

Puntos de entrada de la canalización:

- `make analyzed` — Ejecuta el análisis pesado (pruebas de mutación, benchmarks)
- `make audited` — Vuelve a escanear las dependencias fijadas y los artefactos publicados en busca de vulnerabilidades nuevas
- `make check-outdated` — Informa de cada dependencia fijada que va por detrás de su versión upstream
- `make ready-to-publish` — Ejecuta localmente el pipeline pseudo-CI — compila, prueba y escanea, sin publicar

## Documentación

- [Configuration](../how-to/configuration.md)
- [Output formats reference](../how-to/formats.md)
- [Rules reference](../how-to/rules.md)

## Políticas

- [Cómo contribuir](CONTRIBUTING.md)
- [Política de seguridad](SECURITY.md)
- [Cómo obtener ayuda](SUPPORT.md)
- [Código de conducta](CODE_OF_CONDUCT.md)
- [Política sobre IA y LLM](AI_POLICY.md)

## Enlaces

- [Especificación de Projectfile](https://projectfile.org)

## Licencia

Este proyecto se publica bajo la licencia MIT — consulta el archivo [LICENSE](LICENSE) para más detalles.

<!-- textlint-enable -->
