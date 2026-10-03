<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# ignorelint

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
      --fix                                      Auto-fix deterministically fixable issues (IG-001,002,003,008,015,018,022,023,024)
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
    IGNORELINT_DISABLE_IGNORE_PRAGMA=1 Same as --disable-ignore-pragma
    IGNORELINT_FILE_PATH_IN_REPORT=PATH Same as --file-path-in-report
    NO_COLOR=1                 Disable colored output (also TERM=dumb)
    FORCE_COLOR=1              Color even when piped (--ansi and --no-ansi beat both)
```
