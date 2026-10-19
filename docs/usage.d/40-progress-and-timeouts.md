<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Follow progress and bound the policy lookup

A run prints `linting N file(s)…` to standard error before the first file and `checked N file(s) in Xms (F fixes, P pf-cli calls)` after the last, so a slow tree never looks hung; `--quiet` silences both. The projectfile policy is read through `pf-cli`, which gets 30 seconds to answer; set `IGNORELINT_PF_CLI_TIMEOUT` to a whole number of seconds to change that. On timeout ignorelint warns and continues with flags and environment only. Ctrl-C prints `interrupted, cleaning up…` and exits `130`.

The human and `gnu` formats stream each file as it finishes; `json`, `checkstyle`, `junit`, `sarif` and the other report formats buffer everything and print once at the end.
