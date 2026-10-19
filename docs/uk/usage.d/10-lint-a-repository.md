<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Перевірте ignore-файли в каталозі

Без шляхів ignorelint перевіряє кожен відомий йому ignore-файл у робочому каталозі; `--recursive` обходить усе дерево, пропускаючи приховані каталоги, `node_modules` і символьні посилання. Код виходу `0` означає, що нічого на рівні `--fail-on` чи вище немає, `1` — знайдено проблеми, `2` — неприпустимі аргументи.

```console
$ printf 'node_modules/\n*.log\nnode_modules/\n!!keep.log\n' > .gitignore
$ ignorelint
warn:  .gitignore:3 [IG-008] Duplicate of line 1: "node_modules/"
error: .gitignore:4 [IG-003] Double negation "!!keep.log" re-includes a file literally named "!keep.log"; write "!\!keep.log" if that is intended
$ echo $?
1
```
