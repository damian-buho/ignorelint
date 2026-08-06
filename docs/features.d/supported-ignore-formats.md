<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# Supported ignore-file formats

- Linter for `*ignore` files, built-in Crystal (`shard.yml`, `crystal >= 1.13.0`); compiled `--release --no-debug` to `/export/usr/local/bin/ignorelint` at the `compile-crystal` stage (base `b19/crystal`, builder APT `libxml2-dev`), runtime `b19/ubuntu/resolute`.
- 25 filenames are recognised in `KNOWN_FILES` (`src/file_type.cr`): `.gitignore`, `.dockerignore`, `.containerignore`, `.npmignore`, `.yarnignore`, `.eslintignore`, `.prettierignore`, `.stylelintignore`, `.tfignore`, `.helmignore`, `.gcloudignore`, `.ebignore`, `.slugignore`, `.vercelignore`, `.cfignore`, `.openapi-generator-ignore`, `.cursorignore`, `.aiderignore`, `.aiexclude`, `.codeiumignore`, `.claudeignore`, `.ignore`, `.rgignore`, `.fdignore`, `.eleventyignore`.
- Eight format-specific glob drivers in `src/driver/` (`gitignore`, `dockerignore`, `npmignore`, `prettierignore`, `eslintignore`, `helmignore`, `slugignore`, `cfignore`) model each tool’s matching semantics; `.containerignore` reuses the dockerignore driver, and unrecognised basenames fall back to universal rules only.
- With no PATH arguments the CLI auto-discovers every `KNOWN_FILES` entry present in the current directory; `--verbose` prints a found/not-found report.
- Per-format specification documents live in `specifications/` (24 formats) and golden fixtures in `spec/fixtures/{valid,broken}/`.
