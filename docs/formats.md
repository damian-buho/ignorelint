<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Formats reference

25 filenames are recognised. Each is checked against its own tool’s matching semantics, so Docker rules are never judged by git semantics. Per-format behaviour is pinned in `specifications/` (one document per format) with golden fixtures under `spec/fixtures/{valid,broken}/`.

## Recognised files

`.gitignore`, `.dockerignore`, `.containerignore`, `.npmignore`, `.yarnignore`, `.eslintignore`, `.prettierignore`, `.stylelintignore`, `.tfignore`, `.helmignore`, `.gcloudignore`, `.ebignore`, `.slugignore`, `.vercelignore`, `.cfignore`, `.openapi-generator-ignore`, `.cursorignore`, `.aiderignore`, `.aiexclude`, `.codeiumignore`, `.claudeignore`, `.ignore`, `.rgignore`, `.fdignore`, `.eleventyignore`.

## Matching engines

| Engine | Files |
|---|---|
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
