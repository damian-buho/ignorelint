<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Rules reference

Every file goes through the same pipeline: universal checks, format-specific checks for its [file type](formats.md), filesystem dead-rule checks, then a deterministic sort of the findings. Suppressions (below) are applied last.

## Diagnostic codes

| Code | Default severity | Meaning | Autofix |
| --- | --- | --- | --- |
| IG-001 | warn | Trailing whitespace | ✓ |
| IG-002 | — | Retired: `#` mid-pattern is literal in every format | — |
| IG-003 | error | Double negation | ✓ (`.npmignore`) |
| IG-004 | error | Empty pattern | — |
| IG-005 | error | Consecutive asterisks | — |
| IG-006 | error | Malformed brackets | — |
| IG-007 | warn | Space in pattern | — |
| IG-008 | warn | Duplicate rule | ✓ |
| IG-009 | warn (error in `.dockerignore`) | Invalid doublestar: a `**` that is not a whole path segment | — |
| IG-010 | info | Rooted shallow pattern | — |
| IG-011 | — | Retired: a leading `/` anchors a negation as it anchors any pattern | — |
| IG-012 | warn | Redundant pair | — |
| IG-013 | error | Negation unsupported | — |
| IG-014 | error | Path traversal | — |
| IG-015 | info | Slash has no effect | ✓ |
| IG-016 | error | Doublestar unsupported: Helm rejects any `.helmignore` rule containing `**` | — |
| IG-017 | — | Retired: `.eslintignore` matches unrooted patterns at any depth | — |
| IG-018 | info | Redundant built-in exclude | ✓ |
| IG-019 | warn | Built-in include protected | — |
| IG-020 | info | Path not found | — |
| IG-021 | info | Dead glob rule | — |
| IG-022 | warn | Double slash | ✓ |
| IG-023 | info | Unsorted rule | ✓ |
| IG-024 | warn | Leading whitespace | ✓ |
| IG-025 | info | Case mismatch: a literal path that matches nothing exists in another case | — |

Severities are `error`, `warn`, and `info`; every code is emitted in all output formats. Any default can be changed for the whole run with `--error`, `--warning`, or `--info` (see [USAGE.md](../../USAGE.md)).

## Autofix

`--fix` corrects the nine codes marked above. Same-line fixes compose in one pass, line endings (LF or CRLF) are preserved, and the file is written atomically via temp file plus rename, keeping its permissions. Sorting is skipped while any pattern is negated, since negation order decides the match. Double negation is rewritten only in `.npmignore`, where npm’s matcher cancels each `!!` pair; every other format negates once and reads `!!x` as re-including a file named `!x`, so the finding names that file instead. Symlinks are linted but never rewritten. Fixed findings are relabelled `fixed` and no longer affect the exit code. `--diff` previews the same changes without writing: it lists each replacement as `line N: "old" → "new"`, each deletion as `line N: delete "old"`, and any reordering as `would reorder N lines`, then reports the unfixed findings with the usual exit code. It cannot be combined with `--fix`.

## Suppressions

A comment silences codes on the next pattern line:

```gitignore
# ignorelint: disable-next-line IG-020, IG-021
legacy-path/
```

Blank lines and other comments between the directive and the pattern are skipped; several codes may be listed separated by commas or spaces. Unknown codes match nothing, so a mistyped code fails safe and the finding is still reported. Suppressed findings never reach autofix or the exit code. To silence a rule for the whole run instead of one line, use `--disabled-rules` (see the [configuration guide](configuration.md)).

## Filesystem checks

Literal patterns are tested for existence, glob patterns for at least one match on disk. Negated patterns are skipped (they re-include rather than ignore), as are patterns containing `..` segments. A literal missing only by case warns with the on-disk spelling instead of plain absence. Paths resolve against the directory of the linted file, or the working directory for `--stdin` input.

<!-- textlint-enable -->
