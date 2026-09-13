<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Dead-rule detection against the live filesystem

- Literal patterns are checked for existence and globs for at least one match, so removed paths surface as stale rules. See the [rules reference](docs/rules.md).
- Negated patterns are skipped, since they re-include rather than ignore.
- Patterns reaching outside the tree are skipped instead of probed.
