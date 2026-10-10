<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# Ignorelint — GitHub Action

Lint gitignore, dockerignore and 20+ other ignore files — directly from a GitHub Actions workflow.

This action is a thin composite wrapper around the
[`ghcr.io/damian-buho/ignorelint`](https://github.com/damian-buho/ignorelint/pkgs/container/ignorelint)
image. It runs Ignorelint against the checked-out workspace, renders the
human report into the run summary, optionally posts it as a sticky PR
comment or emits SARIF for code scanning, and gates the job on a
configurable severity threshold.

## Quick start

```yaml
name: Ignorelint
on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents:      read
  pull-requests: write  # only needed when `comment: true`

jobs:
  ignorelint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: damian-buho/ignorelint@1.3.0
        with:
          recursive: true
          comment:   ${{ github.event_name == 'pull_request' }}
```

With no `paths`, known ignore files are discovered automatically in the
working directory; `recursive: true` walks the whole tree instead
(skips hidden directories, `node_modules` and symlinks).

## Version pinning

| Ref       | Selects               | Recommended for             |
| --------- | --------------------- | --------------------------- |
| `@1.3.0`  | Exact release         | All consumers               |
| `@main`   | Bleeding edge         | Not recommended             |

Pin an exact tag for reproducible runs.

## Inputs

| Name                    | Default        | Description                                                                                         |
|-------------------------|----------------|-----------------------------------------------------------------------------------------------------|
| `paths`                 | *(empty)*      | Newline-separated ignore files to lint. Empty enables auto-discovery.                               |
| `recursive`             | `false`        | Search subdirectories for ignore files.                                                             |
| `config_file`           | *(empty)*      | Projectfile path for the `org.ignorelint` policy subtree (read via `--config`).                     |
| `fail_on`               | `error`        | Severity threshold that fails the job: `none`, `error`, `warn`, or `info`.                          |
| `fix`                   | `false`        | Autofix deterministically fixable issues. The workspace will be modified.                           |
| `disabled_rules`        | *(empty)*      | Comma-separated rule tags to skip entirely (e.g. `IG-001,IG-020`).                                  |
| `error`                 | *(empty)*      | Comma-separated rule tags to promote to error severity.                                             |
| `warning`               | *(empty)*      | Comma-separated rule tags to set to warning severity.                                               |
| `info`                  | *(empty)*      | Comma-separated rule tags to demote to info severity.                                               |
| `format`                | *(empty)*      | Extra report format (same values as `--format`). Empty emits none; `sarif` acts like `sarif: true`. |
| `no_fail`               | `false`        | Report every finding but always pass (beats `fail_on`).                                             |
| `diff`                  | `false`        | Preview autofix changes in the human report without writing (needs `fix: false`).                   |
| `plain`                 | `false`        | Human report as one undecorated record per line.                                                    |
| `quiet`                 | `false`        | Only errors in the human report (needs `verbose: false`).                                           |
| `verbose`               | `false`        | Show file discovery output on stderr (needs `quiet: false`).                                        |
| `disable_ignore_pragma` | `false`        | Parse suppression directives but apply none.                                                        |
| `file_path_in_report`   | *(empty)*      | Recorded path in machine-readable reports instead of the linted one.                                |
| `sarif`                 | `false`        | Also emit a SARIF report for `github/codeql-action/upload-sarif`.                                   |
| `upload_sarif`          | `false`        | Upload the SARIF report to GitHub code scanning. Implies `sarif`.                                   |
| `comment`               | `false`        | Post the human report as a sticky comment on the triggering pull request.                           |
| `version`               | `latest`       | Image tag to pull (e.g. `latest`, `1.2.3`). Ignored when `image` is set.                            |
| `image`                 | *(empty)*      | Full image reference override (e.g. for testing a locally-built image). Takes precedence.           |
| `github_token`          | `github.token` | Token used to post PR comments. The default uses the workflow token.                                |

Policy precedence inside the run is flags (these inputs), then
environment, then the projectfile subtree, then built-in defaults.
Projectfile policy inside the container needs `pf-cli` on `PATH`;
without it the run falls back to these inputs plus environment, with an
info notice.

## Outputs

| Name          | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `result`      | `pass` or `fail` after applying the `fail_on` rule.                  |
| `errors`      | Count of error-severity issues.                                      |
| `warnings`    | Count of warning-severity issues.                                    |
| `infos`       | Count of info-severity issues.                                       |
| `fixed`       | Count of auto-fixed issues (`0` unless `fix: true`).                 |
| `total`       | Total issue count across all severities.                             |
| `report_path` | Path on the runner to the generated human-readable report.           |
| `sarif_path`  | Path on the runner to the SARIF report (empty unless `sarif: true`). |
| `format_path` | Path on the runner to the `format` report (empty unless set).        |

## Common recipes

### Lint specific files only

```yaml
- uses: damian-buho/ignorelint@1.3.0
  with:
    paths: |
      .gitignore
      docker/.dockerignore
```

### Monorepo sweep, warnings fail the job

```yaml
- uses: damian-buho/ignorelint@1.3.0
  with:
    recursive: true
    fail_on:   warn
```

### Autofix and commit the result back

```yaml
- uses: damian-buho/ignorelint@1.3.0
  with:
    recursive: true
    fix:       true
- uses: stefanzweifel/git-auto-commit-action@v7
  with:
    commit_message: 'chore: autofix ignore files'
```

With `fix: true`, the counts reflect pre-fix findings (fixed issues are
reported under `fixed` and never fail the gate); the summary body shows
the post-fix workspace.

### Code scanning alerts via SARIF

```yaml
- uses: damian-buho/ignorelint@1.3.0
  with:
    recursive:    true
    upload_sarif: true
```

### Sticky PR comment on every pull request

```yaml
- uses: damian-buho/ignorelint@1.3.0
  with:
    recursive: true
    comment:   ${{ github.event_name == 'pull_request' }}
```

`pull-requests: write` permission is required on the job for the comment to post.
On PRs from forks the workflow token is read-only and the comment step no-ops —
the report still renders to the Actions run summary.

### Warn-only (advisory mode)

```yaml
- uses: damian-buho/ignorelint@1.3.0
  with:
    fail_on: none  # or `warn` to fail on warnings + errors, `info` for everything
```

### Tune rule severities without a projectfile

```yaml
- uses: damian-buho/ignorelint@1.3.0
  with:
    error:          IG-020
    disabled_rules: IG-003
```

### Pin a specific image, e.g. for an air-gapped runner

```yaml
- uses: damian-buho/ignorelint@1.3.0
  with:
    image: my-registry.internal/ignorelint:1.2.3
```

## Permissions

| Permission               | Required when                          |
| ------------------------ | -------------------------------------- |
| `contents: read`         | Always (for `actions/checkout`).       |
| `pull-requests: write`   | `comment: true` on a `pull_request`.   |
| `security-events: write` | `upload_sarif: true`.                  |

## Reporting

The action always writes:

- A human-readable report to `$RUNNER_TEMP/ignorelint-report.txt` (exposed as `report_path`).
- A rendered copy in the Actions run summary page.
- A JSON report (used internally for the `fail_on` gate; not exposed as output).
- A SARIF report when `sarif` or `upload_sarif` is `true` (exposed as `sarif_path`).
- A `format` report when `format` is set (exposed as `format_path`; `human` and `json` reuse the reports above).

Violations at or above `fail_on` also appear as inline annotations on
the PR diff (`error` for errors, `warning` for warnings, `notice` for
infos). With the default `fail_on: error`, only errors annotate;
`warn` adds warnings, `info` adds infos, and `none` annotates nothing.
The full human report still renders to the run summary and the PR comment.

## Source and support

- Source: [github.com/damian-buho/ignorelint](https://github.com/damian-buho/ignorelint)
- Image:  [ghcr.io/damian-buho/ignorelint](https://github.com/damian-buho/ignorelint/pkgs/container/ignorelint)
- Issues: [github.com/damian-buho/ignorelint/issues](https://github.com/damian-buho/ignorelint/issues)

## Development

Step logic lives in [`.scripts/action/`](.scripts/action/) (one script per
step, invoked via `github.action_path`) and is covered by the repository
`auto-shellcheck` gate — `action.yaml` itself holds only inputs, outputs
and step wiring.
