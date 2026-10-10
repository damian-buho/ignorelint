<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Output formats reference

Ten renderings ship today. Each one exists for a named consumer, so pick the format that consumer reads rather than parsing a terminal report yourself.

## Format to consumer

| Format | Consumer | Artifact recipe |
| --- | --- | --- |
| `human` | terminals, CI logs | `ignorelint --format=human` |
| `tty` | alias of `human` | `ignorelint --format=tty` |
| `gnu` | editors and CI log grepping | `ignorelint --format=gnu` |
| `json` | generic CI and custom tooling | `ignorelint --format=json > report.json` |
| `checkstyle` | IDEs and CI that aggregate Checkstyle | `ignorelint --format=checkstyle > checkstyle.xml` |
| `junit` | Jenkins, GitLab test reports | `ignorelint --format=junit > report.xml` |
| `gitlab_codeclimate` | GitLab merge-request code quality | `ignorelint --format=gitlab_codeclimate > code-quality-report.json` |
| `codacy` | Codacy | `ignorelint --format=codacy > issues.json` |
| `sonarqube` | SonarQube external issues | `ignorelint --format=sonarqube > issues.json` |
| `sarif` | GitHub code scanning | `ignorelint --format=sarif > results.sarif` |

`tty` is accepted as an alias of `human`, so a habit learned on a tool that defaults to `tty` carries over.

## Platform recipes

GitLab code quality — write the report where the widget looks for it:

```yaml
lint:
  script: ignorelint --format=gitlab_codeclimate > code-quality-report.json
  artifacts:
    reports:
      codequality: code-quality-report.json
```

GitHub code scanning — upload SARIF with the standard action:

```yaml
- run: ignorelint --format=sarif > results.sarif
- uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: results.sarif
```

Jenkins or GitLab test reports — publish JUnit XML:

```yaml
- run: ignorelint --format=junit > report.xml || true
```

Editor and CI log grepping — one record per line, `file:line` first:

```console
$ ignorelint --format=gnu | grep ': error:'
.gitignore:4: error: IG-003 Double negation "!!keep.log" cancels out
```

SonarQube — import the generic issue format, naming the report in your scanner configuration:

```sh
ignorelint --format=sonarqube > sonar-issues.json
```

## GitHub Action

The action always runs JSON for gating and human for display. Every other format is one input away:

```yaml
- uses: damian-buho/ignorelint@2.0.3
  id: ignorelint
  with:
    format: junit
- uses: actions/upload-artifact@v4
  with:
    path: ${{ steps.ignorelint.outputs.format_path }}
```

`format: sarif` behaves like `sarif: true` and fills `sarif_path` too. An invalid `format` fails the step before the container runs.

## Severity mapping

Every machine format carries the rule tag (`IG-NNN`), the line and the message, so a finding stays identifiable whatever the platform calls its levels. Severities are translated into each platform’s own closed vocabulary:

| Severity | `gnu` | `checkstyle` | `junit` | `gitlab_codeclimate` | `sonarqube` | `sarif` |
| --- | --- | --- | --- | --- | --- | --- |
| error | `error` | `error` | `error` | `critical` | `CRITICAL` | `error` |
| warn | `warning` | `warning` | `warning` | `major` | `MAJOR` | `warning` |
| info | `info` | `info` | `info` | `minor` | `MINOR` | `note` |
| fixed | `fixed` | `info` | `skipped` | `info` | `INFO` | `note` |

A finding autofix already resolved is reported as `skipped` in JUnit rather than a failure, because it no longer describes a problem in the tree.

## Path in reports

`--file-path-in-report=PATH` records `PATH` instead of the linted path in every machine-readable format — the form to use when the report is uploaded from a container and the consumer expects repository-relative paths. Human output keeps the real path.

## Recognised files

25 filenames are recognised. Each is checked against its own tool’s matching semantics, so Docker rules are never judged by git semantics. Per-format behaviour is pinned in `specifications/` (one document per format) with golden fixtures under `spec/fixtures/{valid,broken}/`.

`.gitignore`, `.dockerignore`, `.containerignore`, `.npmignore`, `.yarnignore`, `.eslintignore`, `.prettierignore`, `.stylelintignore`, `.tfignore`, `.helmignore`, `.gcloudignore`, `.ebignore`, `.slugignore`, `.vercelignore`, `.cfignore`, `.openapi-generator-ignore`, `.cursorignore`, `.aiderignore`, `.aiexclude`, `.codeiumignore`, `.claudeignore`, `.ignore`, `.rgignore`, `.fdignore`, `.eleventyignore`.

## Matching engines

| Engine | Files |
| --- | --- |
| gitignore | `.gitignore` and all git-style files (`.claudeignore`, `.yarnignore`, `.ignore`, …) |
| dockerignore | `.dockerignore`, `.containerignore` |
| npmignore | `.npmignore` |
| prettierignore | `.prettierignore` |
| eslintignore | `.eslintignore` |
| helmignore | `.helmignore` |
| slugignore | `.slugignore` |
| cfignore | `.cfignore` |

Filenames outside the list above still get the universal checks; only the format-specific engine is skipped.

## Build

Single static binary written in Crystal (`crystal >= 1.13.0`, no dependencies), compiled `--release --no-debug`. No runtime to install: it runs anywhere, including minimal CI containers.

<!-- textlint-enable -->
