<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Змініть серйозність правила

`--error`, `--warning` і `--info` переводять правила на цей рівень серйозності на весь запуск, ще до оцінки `--fail-on`. Теги нечутливі до регістру, розділяються комами й можуть повторюватися; перемагає остання згадка коду. `IGNORELINT_OVERRIDE_ERROR`, `_WARNING` і `_INFO` роблять те саме через оточення.

```console
$ ignorelint --info=IG-003
info:  .gitignore:1 [IG-020] Directory "node_modules" does not exist
info:  .gitignore:2 [IG-021] Glob "*.log" matches no files (dead rule)
warn:  .gitignore:3 [IG-008] Duplicate of line 1: "node_modules/"
info:  .gitignore:3 [IG-020] Directory "node_modules" does not exist
info:  .gitignore:4 [IG-003] Double negation "!!keep.log" cancels out
$ echo $?
0
$ ignorelint --info=IG-003 --fail-on=warn > /dev/null; echo $?
1
```
