<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
pf-cli-managed: yes
-->

[Español](docs/es/README.md) · [Українська](docs/uk/README.md)

# Ignorelint

Ignorelint is a linter and auto-fixer for ignore files such as .gitignore, .dockerignore and .npmignore, written in Crystal. It recognises 25 filenames across eight format-specific glob drivers and reports 25 diagnostic rules with ten output formats, from human and GNU to JUnit, Code Climate, Codacy, SonarQube and SARIF.

[![Stand with Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://damian-buho.github.io/support-ukraine/) [![Projectfile inside](https://badges.kiota.ch/static/v1?label=projectfile&message=inside&labelColor=0d0d0d&color=8c6723&style=flat-square)](https://projectfile.org) [![License](https://badges.kiota.ch/static/v1?label=license&message=MIT&color=1e5913&style=flat-square)](LICENSE) [![Cosign](https://badges.kiota.ch/static/v1?label=cosign&message=enabled&color=1e5913&style=flat-square)](https://docs.sigstore.dev/cosign/verifying/verify/) [![PRs welcome](https://badges.kiota.ch/static/v1?label=PRs&message=welcome&color=1e5913&style=flat-square)](CONTRIBUTING.md) [![REUSE compliance](https://api.reuse.software/badge/codeberg.org/damian-buho/ignorelint)](https://api.reuse.software/info/codeberg.org/damian-buho/ignorelint)

![Project status](https://badges.kiota.ch/static/v1?label=status&message=maintained&color=1d63ed&style=flat-square) [![Last commit on kiota.ch](https://badges.kiota.ch/gitea/last-commit/damian-buho/ignorelint?gitea_url=https://kiota.ch&label=last%20commit%20on%20kiota.ch&style=flat-square)](https://kiota.ch/damian-buho/ignorelint) [![Last commit on Codeberg](https://badges.kiota.ch/gitea/last-commit/damian-buho/ignorelint?gitea_url=https://codeberg.org&label=last%20commit%20on%20Codeberg&style=flat-square)](https://codeberg.org/damian-buho/ignorelint) [![Last commit on GitHub](https://badges.kiota.ch/github/last-commit/damian-buho/ignorelint?label=last%20commit%20on%20GitHub&style=flat-square)](https://github.com/damian-buho/ignorelint)

[![Publish pipeline on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/published.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Vulnerability audit on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/audited.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Dependency freshness on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/check-outdated.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Analysis sweep on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/analyzed.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions)

[![Publish pipeline on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/published.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Vulnerability audit on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/audited.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Dependency freshness on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/check-outdated.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Analysis sweep on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/analyzed.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions)

## Features

- Autofix that preserves file meaning
- Dead-rule detection against the live filesystem
- Whole-tree discovery for monorepos
- Output pipelines can parse
- Policy lives in projectfile.yaml
- Suppressions for intentional exceptions

It also inherits the features of B19 / Ubuntu — see [Features](docs/FEATURES.md) for the full list.

## What this provides

- **CI action** `damian-buho/ignorelint@2.0.2`
- **Executable** `ignorelint` — command `ignorelint`
- **Container image** `ghcr.io/damian-buho/ignorelint:latest`
- **Container image** `damianbuho/ignorelint:latest`

## Installation

### Container image

Pull the published container image:

#### Pull from GHCR — linux/amd64, linux/arm64

```sh
docker pull ghcr.io/damian-buho/ignorelint:latest
alias ignorelint='docker run --rm --user "$(id -u):$(id -g)" --group-add 0 --volume "$PWD:/app/ws" --workdir /app/ws ghcr.io/damian-buho/ignorelint:latest ignorelint'
```

#### Pull from DockerHub — linux/amd64

```sh
docker pull damianbuho/ignorelint:latest
alias ignorelint='docker run --rm --user "$(id -u):$(id -g)" --group-add 0 --volume "$PWD:/app/ws" --workdir /app/ws damianbuho/ignorelint:latest ignorelint'
```

Stable releases also publish `X.Y.Z`, `X.Y` and `X` tags — pull the precision you want to pin.

If the registries above are unreachable, pull from the origin instead:

#### Pull from Kiota — linux/amd64

```sh
docker pull kiota.ch/damian-buho/ignorelint:latest
alias ignorelint='docker run --rm --user "$(id -u):$(id -g)" --group-add 0 --volume "$PWD:/app/ws" --workdir /app/ws kiota.ch/damian-buho/ignorelint:latest ignorelint'
```

Then run it as if it were installed — the alias runs every example as written against the current directory:

```sh
ignorelint --help
```

### Prebuilt binary

Download the prebuilt binary for your platform from the latest GitHub release:

```sh
curl --fail --location --output ignorelint https://github.com/damian-buho/ignorelint/releases/latest/download/ignorelint-$(uname -s | tr A-Z a-z)-$(uname -m | sed -e s/x86_64/amd64/ -e s/aarch64/arm64/) && chmod +x ignorelint
./ignorelint --help
```

Published for: `linux/amd64`, `linux/arm64`

## Usage

Run it as a step in a GitHub Actions workflow:

```yaml
- uses: damian-buho/ignorelint@2.0.2
```

The action takes these inputs:

| Input | Default | Description |
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

Examples and every command’s help are in [Usage](docs/USAGE.md).

## Building

Clone the repository with its submodules:

```sh
git clone --recurse-submodules https://codeberg.org/damian-buho/ignorelint ignorelint && cd ignorelint
```

Build the binary from source into `dist/`:

```sh
make crystal-build
```

Build the container image locally:

```sh
make container-build
```

- [Makefile reference](docs/how-to/MAKEFILE.md)

Run `make` with no arguments for the default target; run `make help` to list every target.

For the local dev loop, `make dev-container` brings up the dev-container.

Pipeline entry points:

- `make analyzed` — Run the heavy analysis sweep (mutation testing, benchmarks)
- `make audited` — Re-scan the pinned dependencies and published artifacts for new vulnerabilities
- `make check-outdated` — Report every pinned dependency that lags upstream
- `make ready-to-publish` — Run the pseudo-CI pipeline locally — build, test and scan, without publishing

## Documentation

- [Configuration](docs/how-to/configuration.md)
- [Output formats reference](docs/how-to/formats.md)
- [Rules reference](docs/how-to/rules.md)

## Policies

- [How to contribute](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Getting support](SUPPORT.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [AI and LLM Policy](AI_POLICY.md)

## Links

- [Projectfile Specification](https://projectfile.org)

## License

This project is licensed under MIT — see the [LICENSE](LICENSE) file for details.
