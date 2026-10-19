<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Dead-rule detection against the live filesystem

- A rule is reported as stale only with evidence, a deleted path or a near-miss spelling, so a fresh clone stays quiet. See the [rules reference](how-to/rules.md).
- Negated patterns are skipped, since they re-include rather than ignore.
- Patterns reaching outside the tree are skipped instead of probed.
