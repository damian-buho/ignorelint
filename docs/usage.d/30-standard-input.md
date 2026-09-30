<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Fix an editor buffer through standard input

`--stdin` lints piped content as if it were the file named by `--file`. With `--fix`, the corrected document goes to standard output and the report to standard error, so an editor can replace its buffer with standard output as is.

```console
$ printf 'build/\nbuild/\n' | ignorelint --stdin --file=.gitignore --fix 2> /dev/null
build/
```
