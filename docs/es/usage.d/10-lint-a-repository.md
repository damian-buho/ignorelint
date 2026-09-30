<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Revisar los archivos ignore de un directorio

Sin rutas, ignorelint revisa cada archivo ignore que reconoce en el directorio de trabajo; `--recursive` recorre todo el árbol y omite los directorios ocultos, `node_modules` y los enlaces simbólicos. La salida `0` significa nada en `--fail-on` o por encima, `1` significa problemas encontrados y `2` argumentos no válidos.

```console
$ printf 'node_modules/\n*.log\nnode_modules/\n!!keep.log\n' > .gitignore
$ ignorelint
info:  .gitignore:1 [IG-020] Directory "node_modules" does not exist
info:  .gitignore:2 [IG-021] Glob "*.log" matches no files (dead rule)
warn:  .gitignore:3 [IG-008] Duplicate of line 1: "node_modules/"
info:  .gitignore:3 [IG-020] Directory "node_modules" does not exist
error: .gitignore:4 [IG-003] Double negation "!!keep.log" cancels out
$ echo $?
1
```
