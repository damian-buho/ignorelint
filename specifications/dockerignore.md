<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# dockerignore

- **File**: `.dockerignore`
- **Syntax**: dockerignore
- **Source**: https://docs.docker.com/build/concepts/context/#dockerignore-file
- **Reference**: gitignore with significant deviations

## Syntax

- Empty lines are ignored.
- Lines starting with `#` are comments.
- `!` prefix negates a pattern.
- Uses Go `filepath.Match` semantics plus `**` extension.
- `*` matches any sequence of non-`/` characters.
- `?` matches a single non-`/` character.
- `[a-z]` matches one character in the given range or set.
- `**` matches any number of directories (zero or more).
- Patterns are cleaned with `filepath.Clean` before matching.
- The pattern `.` is ignored (special case in the matcher).

## Deviations from gitignore

- **Leading and trailing slashes are stripped** before matching. A pattern `foo/` and `foo` are equivalent; a pattern `/foo` and `foo` are equivalent. There is no concept of "rooted" or "directory-only" patterns.
- `filepath.Clean` is applied to all patterns, normalizing `./` prefixes and double slashes.
- The pattern `.` is silently ignored by the matcher.
- Matching is performed against the full relative path using Go’s `filepath.Match` + `**`, not Git’s fnmatch-based engine.

## Notes

- The slash-stripping behavior is the most critical deviation: tools that expect rooted or directory-only semantics will not work correctly.
- The Go matcher (`moby/patternmatcher`) is the authoritative implementation, not the documentation.
