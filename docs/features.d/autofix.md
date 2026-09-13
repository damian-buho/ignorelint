<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Autofix that preserves file meaning

- `--fix` corrects deterministic issues in place, so cleanups apply without hand-editing. See the [rules reference](docs/rules.md).
- Corrections on one line compose in a single pass, so one run converges.
- Files are rewritten atomically with permissions kept, so an interrupted run never leaves a truncated file.
- Negations are never reordered and symlinks never rewritten, so a fix cannot change what the file ignores.
- Fixed findings are relabelled and left out of the failure decision, so exit codes reflect what remains.
