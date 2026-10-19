<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Change a rule’s severity

`--error`, `--warning` and `--info` move rules to that severity for the whole run, before `--fail-on` is evaluated. Tags are case-insensitive, comma-separated and repeatable; a code named in several applies `--error`, then `--warning`, then `--info`, so `--info` wins. `IGNORELINT_OVERRIDE_ERROR`, `_WARNING` and `_INFO` do the same from the environment.

```console
$ ignorelint --info=IG-003
warn:  .gitignore:3 [IG-008] Duplicate of line 1: "node_modules/"
info:  .gitignore:4 [IG-003] Double negation "!!keep.log" re-includes a file literally named "!keep.log"; write "!\!keep.log" if that is intended
$ echo $?
0
$ ignorelint --info=IG-003 --fail-on=warn > /dev/null; echo $?
1
```
