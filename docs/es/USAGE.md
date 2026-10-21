<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

[English](../USAGE.md) · [Українська](../uk/USAGE.md)

# Uso

## ignorelint

```console
$ ignorelint --help
Description:
  Linter for *ignore files (.gitignore, .dockerignore, .eslintignore, etc.)

Usage:
  ignorelint [options] [--] [<paths>...]

Arguments:
  paths                                          Files to lint; none discovers them in the current directory, a lone - reads stdin

Options:
      --fail-on=FAIL-ON                          Exit non-zero at this severity or worse (error|warn|info|none, default: error)
      --no-fail                                  Report every finding but always exit 0 (beats --fail-on)
      --plain                                    Human output as one undecorated path:line [CODE] severity: message record per line
      --file-path-in-report=FILE-PATH-IN-REPORT  Record this path instead of the linted one in machine-readable reports
      --format=FORMAT                            Output format (human|tty|gnu|json|checkstyle|junit|gitlab_codeclimate|codacy|sonarqube|sarif, default: human)
  -r, --recursive                                Search subdirectories for *ignore files (skips hidden dirs, node_modules, symlinks)
      --fix                                      Auto-fix deterministically fixable issues (IG-001,003,008,015,018,022,023,024)
      --diff                                     Preview auto-fix changes without writing (cannot combine with --fix)
      --stdin                                    Lint piped content instead of files (requires --file; a lone - path does the same)
      --file=FILE                                Filename for --stdin input (drives format detection)
      --disabled-rules=DISABLED-RULES            Skip rules entirely (comma-separated tags, e.g. IG-001,IG-020) (multiple values allowed)
      --error=ERROR                              Promote rules to error severity (comma-separated tags, e.g. IG-020) (multiple values allowed)
      --warning=WARNING                          Set rules to warning severity (comma-separated tags) (multiple values allowed)
      --info=INFO                                Demote rules to info severity (comma-separated tags; applied last) (multiple values allowed)
      --disable-ignore-pragma                    Parse suppression directives but apply none; IG-026 still lists them
      --config=CONFIG                            Projectfile read via pf-cli for the org.ignorelint policy subtree (default: ./projectfile.*)
  -h, --help                                     Display help for the given command. When no command is given display help for the ignorelint command
      --silent                                   Do not output any message
  -q, --quiet                                    Only errors are displayed. All other output is suppressed
  -V, --version                                  Display this application version
      --ansi|--no-ansi                           Force (or disable --no-ansi) ANSI output
  -n, --no-interaction                           Do not ask any interactive question
  -v|vv|vvv, --verbose                           Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug

Help:
  When no path is given, discovers supported *ignore files in the current directory.
  Discovery and diagnostics go to stderr; stdout carries only the report.

  Environment variables:
    SHELL_VERBOSITY=1          Same as -v (-1 same as -q)
    IGNORELINT_FAIL_ON=LEVEL   Same as --fail-on (error|warn|info|none)
    IGNORELINT_NOFAIL=1        Same as --no-fail
    IGNORELINT_FORMAT=FORMAT   Same as --format
    IGNORELINT_FIX=1           Same as --fix
    IGNORELINT_RECURSIVE=1     Same as --recursive
    IGNORELINT_DISABLED_RULES=CODES Same as --disabled-rules
    IGNORELINT_OVERRIDE_ERROR=CODES Same as --error
    IGNORELINT_OVERRIDE_WARNING=CODES Same as --warning
    IGNORELINT_OVERRIDE_INFO=CODES Same as --info
    IGNORELINT_CONFIG=PATH     Same as --config
    IGNORELINT_PF_CLI_TIMEOUT=SECONDS Give pf-cli this long to answer (default 30)
    IGNORELINT_DISABLE_IGNORE_PRAGMA=1 Same as --disable-ignore-pragma
    IGNORELINT_FILE_PATH_IN_REPORT=PATH Same as --file-path-in-report
    NO_COLOR=1                 Disable colored output (also TERM=dumb)
    FORCE_COLOR=1              Color even when piped (--ansi and --no-ansi beat both)
```

## Revisar los archivos ignore de un directorio

Sin rutas, ignorelint revisa cada archivo ignore que reconoce en el directorio de trabajo; `--recursive` recorre todo el árbol y omite los directorios ocultos, `node_modules` y los enlaces simbólicos. La salida `0` significa nada en `--fail-on` o por encima, `1` significa problemas encontrados y `2` argumentos no válidos.

```console
$ printf 'node_modules/\n*.log\nnode_modules/\n!!keep.log\n' > .gitignore
$ ignorelint
warn:  .gitignore:3 [IG-008] Duplicate of line 1: "node_modules/"
error: .gitignore:4 [IG-003] Double negation "!!keep.log" re-includes a file literally named "!keep.log"; write "!\!keep.log" if that is intended
$ echo $?
1
```

## Cambiar la severidad de una regla

`--error`, `--warning` e `--info` llevan las reglas a esa severidad durante toda la ejecución, antes de evaluar `--fail-on`. Las etiquetas no distinguen mayúsculas, se separan con comas y se pueden repetir; un código nombrado en varias aplica `--error`, luego `--warning` y luego `--info`, así que gana `--info`. `IGNORELINT_OVERRIDE_ERROR`, `_WARNING` e `_INFO` hacen lo mismo desde el entorno.

```console
$ ignorelint --info=IG-003
warn:  .gitignore:3 [IG-008] Duplicate of line 1: "node_modules/"
info:  .gitignore:4 [IG-003] Double negation "!!keep.log" re-includes a file literally named "!keep.log"; write "!\!keep.log" if that is intended
$ echo $?
0
$ ignorelint --info=IG-003 --fail-on=warn > /dev/null; echo $?
1
```

## Corregir un búfer del editor por la entrada estándar

`--stdin` revisa el contenido recibido por tubería como si fuera el archivo que nombra `--file`. Con `--fix`, el documento corregido va a la salida estándar y el informe a la salida de errores, así un editor puede sustituir su búfer por la salida estándar tal cual.

```console
$ printf 'build/\nbuild/\n' | ignorelint --stdin --file=.gitignore --fix 2> /dev/null
build/
```

## Seguir el avance y acotar la consulta de política

Cada ejecución escribe `linting N file(s)…` en la salida de errores antes del primer archivo y `checked N file(s) in Xms (F fixes, P pf-cli calls)` tras el último, así un árbol lento nunca parece colgado; `--quiet` silencia ambas. La política del projectfile se lee con `pf-cli`, que dispone de 30 segundos para responder; `IGNORELINT_PF_CLI_TIMEOUT` fija otro número entero de segundos. Al agotarse el plazo, ignorelint avisa y sigue solo con opciones y entorno. Ctrl-C escribe `interrupted, cleaning up…` y termina con `130`.

Los formatos humano y `gnu` emiten cada archivo al terminar; `json`, `checkstyle`, `junit`, `sarif` y los demás informes se acumulan y se imprimen una sola vez al final.
<!-- textlint-enable -->
