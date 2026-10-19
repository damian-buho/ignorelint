<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Lint the ignore files in a directory

With no path, ignorelint lints every ignore file it recognises in the working directory; `--recursive` walks the whole tree, skipping hidden directories, `node_modules` and symlinks. Exit `0` means nothing at or above `--fail-on`, `1` means issues found, `2` means invalid arguments.

```console
$ printf 'node_modules/\n*.log\nnode_modules/\n!!keep.log\n' > .gitignore
$ ignorelint
warn:  .gitignore:3 [IG-008] Duplicate of line 1: "node_modules/"
error: .gitignore:4 [IG-003] Double negation "!!keep.log" re-includes a file literally named "!keep.log"; write "!\!keep.log" if that is intended
$ echo $?
1
```
