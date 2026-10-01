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
Usage: ignorelint [OPTIONS] [PATH...]

Linter for *ignore files (.gitignore, .dockerignore, .eslintignore, etc.)

Options:
    -h, --help                       Show this help
    -V, --version                    Show version
        --fail-on=LEVEL              Exit non-zero on LEVEL or worse (error|warn|info|none, default: error)
        --no-fail                    Report every finding but always exit 0 (beats --fail-on)
        --colors=WHEN                Color human output (auto|on|off, default: auto)
        --no-color                   Same as --colors=off
        --plain                      Human output as one undecorated path:line [CODE] severity: message record per line
    -q, --quiet                      Print only issues: no valid-file lines or info notices (cannot combine with --verbose)
        --file-path-in-report=PATH   Record PATH instead of the linted path in machine-readable reports
        --format=FORMAT              Output format (human|tty|gnu|json|checkstyle|junit|gitlab_codeclimate|codacy|sonarqube|sarif, default: human)
    -v, --verbose                    Show discovery output and extra diagnostics
    -r, --recursive                  Search subdirectories for *ignore files (skips hidden dirs, node_modules, symlinks)
        --fix                        Auto-fix deterministically fixable issues (IG-001,002,003,008,015,018,022,023,024)
        --diff                       Preview auto-fix changes without writing (cannot combine with --fix)
        --stdin                      Lint piped content instead of files (requires --file; a lone - PATH does the same)
        --file=NAME                  Filename for --stdin input (drives format detection)
        --disabled-rules=CODES       Skip rules entirely (comma-separated tags, e.g. IG-001,IG-020)
        --error=CODES                Promote rules to error severity (comma-separated tags, e.g. IG-020)
        --warning=CODES              Set rules to warning severity (comma-separated tags)
        --info=CODES                 Demote rules to info severity (comma-separated tags)
        --disable-ignore-pragma      Parse suppression directives but apply none; IG-026 still lists them
        --config=PATH                Projectfile read via pf-cli for the org.ignorelint policy subtree (default: ./projectfile.*)

When no PATH is given, discovers supported *ignore files in the current directory.
Discovery and diagnostics go to stderr; stdout carries only the report.

Environment variables:
  IGNORELINT_VERBOSE=1       Same as --verbose
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
  IGNORELINT_DISABLE_IGNORE_PRAGMA=1 Same as --disable-ignore-pragma
  IGNORELINT_FILE_PATH_IN_REPORT=PATH Same as --file-path-in-report
  NO_COLOR=1                 Disable colored output (also IGNORELINT_NO_COLOR=1, TERM=dumb)
  FORCE_COLOR=1              Color even when piped (--colors beats it)
```

## Revisar los archivos ignore de un directorio

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

## Cambiar la severidad de una regla

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

## Corregir un búfer del editor por la entrada estándar

`--stdin` revisa el contenido recibido por tubería como si fuera el archivo que nombra `--file`. Con `--fix`, el documento corregido va a la salida estándar y el informe a la salida de errores, así un editor puede sustituir su búfer por la salida estándar tal cual.

```console
$ printf 'build/\nbuild/\n' | ignorelint --stdin --file=.gitignore --fix 2> /dev/null
build/
```
<!-- textlint-enable -->
