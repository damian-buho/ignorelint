<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Cambiar la severidad de una regla

`--error`, `--warning` e `--info` llevan las reglas a esa severidad durante toda la ejecución, antes de evaluar `--fail-on`. Las etiquetas no distinguen mayúsculas, se separan con comas y se pueden repetir; gana la última mención de un código. `IGNORELINT_OVERRIDE_ERROR`, `_WARNING` e `_INFO` hacen lo mismo desde el entorno.

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
