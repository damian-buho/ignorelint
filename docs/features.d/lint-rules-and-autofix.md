<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# Linter rules and check pipeline

- 24 diagnostic codes `IG-001`…`IG-024` (`src/issue.cr` `CODE_TAG_MAP`) with severities `error`/`warn`/`info` (plus a synthetic `fixed` severity set after `--fix`); every code is emitted in all output formats.
- `Linter.lint` (`src/linter.cr`) runs a four-phase pipeline: universal checks, format-specific checks via a `FormatLinter` adapter, filesystem dead-rule checks, then a deterministic line sort.
- Universal (all formats): `IG-001` trailing whitespace, `IG-002` unescaped `#`, `IG-003` double negation, `IG-004` empty pattern, `IG-005` consecutive `***`, `IG-006` malformed brackets, `IG-007` space in pattern (suppressed for dockerignore), `IG-008` duplicate rule, `IG-022` double slash, `IG-023` unsorted rule, `IG-024` leading whitespace.
- Format-specific examples: `IG-014` path traversal (dockerignore/containerignore), `IG-015` ineffective leading/trailing slash, `IG-018` redundant built-in exclude (npm/prettier/cf).
- Filesystem dead-rule detection: `IG-020` literal path does not exist, `IG-021` glob matches no files/directories; negated patterns are skipped (they re-include rather than ignore).
- `--fix` auto-corrects nine deterministic codes (`IG-001,002,003,008,015,018,022,023,024`): line replacements/deletions are applied first, then a bulk `SortFix` alphabetises all active lines (skipped when any pattern is negated, since negation order decides the match); fixed issues are relabelled severity `fixed` and excluded from the fail decision.
- Suppression directives: a comment `# ignorelint: disable-next-line IG-020, IG-021` silences the listed codes on the next pattern; unknown codes match nothing, so a typo fails safe and the issue is still reported.
