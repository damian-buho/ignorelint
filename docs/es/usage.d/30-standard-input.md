<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Corregir un búfer del editor por la entrada estándar

`--stdin` revisa el contenido recibido por tubería como si fuera el archivo que nombra `--file`. Con `--fix`, el documento corregido va a la salida estándar y el informe a la salida de errores, así un editor puede sustituir su búfer por la salida estándar tal cual.

```console
$ printf 'build/\nbuild/\n' | ignorelint --stdin --file=.gitignore --fix 2> /dev/null
build/
```
