<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Виправте буфер редактора через стандартний ввід

`--stdin` перевіряє вміст із конвеєра так, ніби це файл, названий у `--file`. З `--fix` виправлений документ іде в стандартний вивід, а звіт — у стандартний потік помилок, тож редактор може замінити буфер стандартним виводом без змін.

```console
$ printf 'build/\nbuild/\n' | ignorelint --stdin --file=.gitignore --fix 2> /dev/null
build/
```
