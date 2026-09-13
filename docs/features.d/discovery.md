<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Whole-tree discovery for monorepos

- With no paths given, ignore files are found automatically: one directory, or the whole tree with `--recursive`. See the [CLI reference](docs/cli.md).
- Findings report working-directory-relative paths in sorted order, so output is stable across runs.
- Hidden directories, `node_modules`, and symlinks are skipped, so internals, dependencies, and link cycles are never linted.
- Explicit paths override discovery entirely.
