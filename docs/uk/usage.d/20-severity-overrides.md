<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Змініть серйозність правила

`--error`, `--warning` і `--info` переводять правила на цей рівень серйозності на весь запуск, ще до оцінки `--fail-on`. Теги нечутливі до регістру, розділяються комами й можуть повторюватися; код, названий у кількох, застосовує `--error`, потім `--warning`, потім `--info`, тож перемагає `--info`. `IGNORELINT_OVERRIDE_ERROR`, `_WARNING` і `_INFO` роблять те саме через оточення.

```console
$ ignorelint --info=IG-003
warn:  .gitignore:3 [IG-008] Duplicate of line 1: "node_modules/"
info:  .gitignore:4 [IG-003] Double negation "!!keep.log" re-includes a file literally named "!keep.log"; write "!\!keep.log" if that is intended
$ echo $?
0
$ ignorelint --info=IG-003 --fail-on=warn > /dev/null; echo $?
1
```
