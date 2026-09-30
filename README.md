<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
pf-cli-managed: yes
-->

[Español](docs/es/README.md) · [Українська](docs/uk/README.md)

# Ignorelint

Ignorelint is a linter and auto-fixer for ignore files such as .gitignore, .dockerignore and .npmignore, written in Crystal. It recognises 25 filenames across eight format-specific glob drivers and reports 25 diagnostic rules with human, JSON, checkstyle and SARIF output.

[![Stand with Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://damian-buho.github.io/support-ukraine/) [![Projectfile inside](https://badges.kiota.ch/static/v1?label=projectfile&message=inside&labelColor=0d0d0d&color=8c6723&style=flat-square)](https://projectfile.org) [![License](https://badges.kiota.ch/static/v1?label=license&message=MIT&color=1e5913&style=flat-square)](LICENSE) [![Commit style](https://badges.kiota.ch/static/v1?label=commits&message=conventional%20v1.0.0&color=1877aa&style=flat-square)](https://www.conventionalcommits.org/en/v1.0.0/) ![Workflow](https://badges.kiota.ch/static/v1?label=workflow&message=git-flow&color=1877aa&style=flat-square) [![Versioning](https://badges.kiota.ch/static/v1?label=versioning&message=semantic%20v2.0.0&color=1877aa&style=flat-square)](https://semver.org/) [![Cosign](https://badges.kiota.ch/static/v1?label=cosign&message=enabled&color=1e5913&style=flat-square)](https://docs.sigstore.dev/cosign/verifying/verify/) [![PRs welcome](https://badges.kiota.ch/static/v1?label=PRs&message=welcome&color=1e5913&style=flat-square)](CONTRIBUTING.md) [![Citation](https://badges.kiota.ch/static/v1?label=citation&message=cff&color=1877aa&style=flat-square)](CITATION.cff) [![REUSE compliance](https://api.reuse.software/badge/codeberg.org/damian-buho/ignorelint)](https://api.reuse.software/info/codeberg.org/damian-buho/ignorelint)

![Project status](https://badges.kiota.ch/static/v1?label=status&message=maintained&color=1d63ed&style=flat-square) [![Last commit on kiota.ch](https://badges.kiota.ch/gitea/last-commit/damian-buho/ignorelint?gitea_url=https://kiota.ch&label=last%20commit%20on%20kiota.ch&style=flat-square)](https://kiota.ch/damian-buho/ignorelint) [![Last commit on Codeberg](https://badges.kiota.ch/gitea/last-commit/damian-buho/ignorelint?gitea_url=https://codeberg.org&label=last%20commit%20on%20Codeberg&style=flat-square)](https://codeberg.org/damian-buho/ignorelint) [![Last commit on GitHub](https://badges.kiota.ch/github/last-commit/damian-buho/ignorelint?label=last%20commit%20on%20GitHub&style=flat-square)](https://github.com/damian-buho/ignorelint)

[![Publish pipeline on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/published.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Vulnerability audit on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/audited.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Dependency freshness on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/check-outdated.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions) [![Analysis sweep on GitHub](https://github.com/damian-buho/ignorelint/actions/workflows/analyze.yaml/badge.svg?style=flat-square)](https://github.com/damian-buho/ignorelint/actions)

[![Publish pipeline on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/published.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Vulnerability audit on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/audited.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Dependency freshness on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/check-outdated.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions) [![Analysis sweep on kiota.ch](https://kiota.ch/damian-buho/ignorelint/badges/workflows/analyze.yaml/badge.svg?style=flat-square)](https://kiota.ch/damian-buho/ignorelint/actions)

## Features

- Autofix that preserves file meaning
- Dead-rule detection against the live filesystem
- Whole-tree discovery for monorepos
- Output pipelines can parse
- Policy lives in projectfile.yaml
- Suppressions for intentional exceptions

It also inherits the features of Inherited from B19 / Ubuntu — see [FEATURES.md](FEATURES.md) for the full list.

## What this provides

- **CI action** `damian-buho/ignorelint@1.4.0`
- **Executable** `ignorelint` — command `ignorelint`
- **Container image** `ghcr.io/damian-buho/ignorelint:latest`
- **Container image** `damianbuho/ignorelint:latest`

## Installation

### Container image

Pull the published container image:

Alias the command to the image, so every example runs as written against the current directory:

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
```

Then run it as if it were installed:

```sh
ignorelint --help
```

### Prebuilt binary

Download the prebuilt binary for your platform from the latest GitHub release:

#### Download for linux/amd64

```sh
curl --fail --location --output ignorelint https://github.com/damian-buho/ignorelint/releases/latest/download/ignorelint-linux-amd64 && chmod +x ignorelint
./ignorelint --help
```

#### Download for linux/arm64

```sh
curl --fail --location --output ignorelint https://github.com/damian-buho/ignorelint/releases/latest/download/ignorelint-linux-arm64 && chmod +x ignorelint
./ignorelint --help
```

## Usage

Run it as a step in a GitHub Actions workflow:

```yaml
- uses: damian-buho/ignorelint@1.4.0
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
        --fail-on=LEVEL              Exit non-zero on LEVEL or worse (error|warn|info, default: error)
        --format=FORMAT              Output format (human|json|checkstyle|sarif, default: human)
    -v, --verbose                    Show discovery output and extra diagnostics
    -r, --recursive                  Search subdirectories for *ignore files (skips hidden dirs, node_modules, symlinks)
        --fix                        Auto-fix deterministically fixable issues (IG-001,002,003,008,015,018,022,023,024)
        --diff                       Preview auto-fix changes without writing (cannot combine with --fix)
        --stdin                      Lint piped content instead of files (requires --file)
        --file=NAME                  Filename for --stdin input (drives format detection)
        --disabled-rules=CODES       Skip rules entirely (comma-separated tags, e.g. IG-001,IG-020)
        --error=CODES                Promote rules to error severity (comma-separated tags, e.g. IG-020)
        --warning=CODES              Set rules to warning severity (comma-separated tags)
        --info=CODES                 Demote rules to info severity (comma-separated tags)
        --config=PATH                Projectfile read via pf-cli for the org.ignorelint policy subtree (default: ./projectfile.*)

When no PATH is given, discovers supported *ignore files in the current directory.
Color is disabled when NO_COLOR is set to a non-empty value.

Environment variables:
  IGNORELINT_VERBOSE=1       Same as --verbose
  IGNORELINT_FAIL_ON=LEVEL   Same as --fail-on (error|warn|info)
  IGNORELINT_FORMAT=FORMAT   Same as --format
  IGNORELINT_FIX=1           Same as --fix
  IGNORELINT_RECURSIVE=1     Same as --recursive
  IGNORELINT_DISABLED_RULES=CODES Same as --disabled-rules
  IGNORELINT_OVERRIDE_ERROR=CODES Same as --error
  IGNORELINT_OVERRIDE_WARNING=CODES Same as --warning
  IGNORELINT_OVERRIDE_INFO=CODES Same as --info
  IGNORELINT_CONFIG=PATH     Same as --config
  NO_COLOR=1                 Disable colored output
```

Examples and every command’s help are in [USAGE.md](USAGE.md).

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

- `make analyze` — Run the heavy analysis sweep (mutation testing, benchmarks)
- `make audited` — Re-scan the pinned dependencies and published artifacts for new vulnerabilities
- `make check-outdated` — Report every pinned dependency that lags upstream
- `make ready-to-publish` — Run the pseudo-CI pipeline locally — build, test and scan, without publishing

## Documentation

- [Configuration](docs/how-to/configuration.md)
- [Formats reference](docs/how-to/formats.md)
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
