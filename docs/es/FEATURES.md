<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

[English](../../FEATURES.md) · [Українська](../uk/FEATURES.md)

# Características

## Características del proyecto

### CLI, formatos de salida y códigos de salida

- Flags: `--fail-on=LEVEL` (`error`|`warn`|`info`, por defecto `error`), `--format=FORMAT` (`human`|`json`|`checkstyle`|`sarif`, por defecto `human`), `--fix`, `--verbose`/`-v`, `--version`/`-V`, `--help`/`-h`; un `PATH...` posicional anula el autodescubrimiento.
- Variables de entorno que sobrescriben (menor prioridad que los flags de CLI): `IGNORELINT_VERBOSE`, `IGNORELINT_FAIL_ON`, `NO_COLOR` (desactiva el color según la convención no-color.org; el color además requiere TTY).
- Cuatro formateadores de salida (`src/formatter/`): `human` (color, consciente de TTY), `json`, `checkstyle`, `sarif`; SARIF incrusta `VERSION` (mantenida en sincronía con `shard.yml` en `src/version.cr`).
- Códigos de salida: `0` sin problemas en el nivel `--fail-on` o por encima, `1` problemas encontrados en el umbral o por encima, `2` argumentos de CLI inválidos.
- Cableado del contenedor: `entrypoint.d/5000-start.sh` ejecuta `sleep infinity` (sin `CMD` explícito); `command.d/get-ignorelint-version` imprime la versión de `ignorelint` para la autoprueba `test.d/1100-check-version.sh`.

### Reglas del linter y pipeline de comprobaciones

- 24 códigos de diagnóstico `IG-001`…`IG-024` (`CODE_TAG_MAP` en `src/issue.cr`) con severidades `error`/`warn`/`info` (más una severidad sintética `fixed` aplicada tras `--fix`); todo código se emite en todos los formatos de salida.
- `Linter.lint` (`src/linter.cr`) ejecuta un pipeline de cuatro fases: comprobaciones universales, comprobaciones específicas del formato mediante un adaptador `FormatLinter`, comprobaciones de reglas muertas contra el sistema de archivos, y por último una ordenación determinista de líneas.
- Universales (todos los formatos): `IG-001` espacio final, `IG-002` `#` sin escapar, `IG-003` doble negación, `IG-004` patrón vacío, `IG-005` `***` consecutivos, `IG-006` corchetes malformados, `IG-007` espacio en el patrón (suprimido para dockerignore), `IG-008` regla duplicada, `IG-022` barra doble, `IG-023` regla sin ordenar, `IG-024` espacio al inicio.
- Ejemplos específicos del formato: `IG-014` path traversal (dockerignore/containerignore), `IG-015` barra inicial/final inefectiva, `IG-018` exclusión integrada redundante (npm/prettier/cf).
- Detección de reglas muertas contra el sistema de archivos: `IG-020` la ruta literal no existe, `IG-021` el glob no coincide con ningún archivo/directorio; los patrones negados se omiten (reincluyen en lugar de ignorar).
- `--fix` autocorrige nueve códigos deterministas (`IG-001,002,003,008,015,018,022,023,024`): primero se aplican reemplazos/eliminaciones de líneas, luego un `SortFix` masivo ordena alfabéticamente todas las líneas activas; los problemas corregidos se reetiquetan con severidad `fixed` y quedan excluidos de la decisión de fallo.

### Formatos de archivos ignore soportados

- Linter para archivos `*ignore`, en Crystal nativo (`shard.yml`, `crystal >= 1.13.0`); compilado `--release --no-debug` a `/export/usr/local/bin/ignorelint` en la etapa `compile-crystal` (base `b19/crystal`, APT del builder `libxml2-dev`), runtime `b19/ubuntu/resolute`.
- 25 nombres de archivo reconocidos en `KNOWN_FILES` (`src/file_type.cr`): `.gitignore`, `.dockerignore`, `.containerignore`, `.npmignore`, `.yarnignore`, `.eslintignore`, `.prettierignore`, `.stylelintignore`, `.tfignore`, `.helmignore`, `.gcloudignore`, `.ebignore`, `.slugignore`, `.vercelignore`, `.cfignore`, `.openapi-generator-ignore`, `.cursorignore`, `.aiderignore`, `.aiexclude`, `.codeiumignore`, `.claudeignore`, `.ignore`, `.rgignore`, `.fdignore`, `.eleventyignore`.
- Ocho drivers de glob específicos del formato en `src/driver/` (`gitignore`, `dockerignore`, `npmignore`, `prettierignore`, `eslintignore`, `helmignore`, `slugignore`, `cfignore`) modelan la semántica de coincidencia de cada herramienta; `.containerignore` reutiliza el driver dockerignore, y los nombres base no reconocidos caen solo a las reglas universales.
- Sin argumentos PATH el CLI autodescubre toda entrada de `KNOWN_FILES` presente en el directorio actual; `--verbose` imprime un informe de encontrados/no encontrados.
- Los documentos de especificación por formato viven en `specifications/` (24 formatos) y los fixtures dorados en `spec/fixtures/{valid,broken}/`.

## Heredado de B19/Ubuntu 1.0.0

### Persistent APT cache across builds

- APT package and index caches survive across builds via BuildKit cache mounts, keyed by Ubuntu series and architecture.
- Repeated builds reuse downloaded packages instead of re-downloading.
- Optional LAN APT cacher proxy auto-detection for environments with a caching proxy.

### Service process management with log routing (b19-exec)

- Long-running processes (daemons, servers) have stdout and stderr automatically routed through the structured logger.
- The service PID is tracked for signal forwarding -- Docker stop gracefully terminates the main process.
- Log levels for stdout and stderr streams are independently configurable.
- Exit code of the service is captured and available to downstream hooks.

### Cached artifact downloads with integrity verification (b19-fetch)

- All external downloads go through a three-tier cache: local `.fetch/` directory, BuildKit persistent cache, then upstream via aria2c with up to 16 connections.
- Optional SHA-512 verification at every tier; hash mismatch causes fallthrough to the next tier rather than failure.
- Offgrid mode blocks all downloads entirely, failing fast with a clear error if a cache miss occurs.
- Supports a near-cache proxy for LAN-only builds that route through a caching proxy.

### Timed command execution with failure reporting (b19-run)

- Any command can be wrapped to get automatic elapsed-time measurement and success/failure reporting.
- Success output is visible only at higher verbosity levels; failure output is always shown.
- In debug mode, command output streams live instead of being buffered.

### Run-once initialization (bootstrap.d)

- One-time setup tasks (database migrations, admin user creation, directory init) run on first container start only.
- Automatic idempotency: completed scripts are never re-run, even across container restarts.
- Failed scripts are retried on next start; successful ones stay locked.
- State can be reset by clearing a volume, triggering a full re-bootstrap.
- Downstream images add their own init scripts by dropping them into a directory.

### Modular build hooks (build.d)

- All image build logic lives in numbered shell scripts instead of inline Dockerfile `RUN` commands.
- Hooks are organized in `pre/on/post` phases and auto-discovered by the stage name passed to `build-stage`.
- The reserved `always/{pre,post}` scope brackets every stage, whatever it is named, so cross-cutting setup is written once instead of per stage.
- Inheritable hooks propagate to downstream images automatically via Docker layer overlay -- downstream gets parent’s build logic for free.
- Non-inheritable hooks are cleaned up after execution to prevent leaking into later stages.

### Automatic CPU count detection (NUMPROCS)

- Available CPUs are detected automatically with Kubernetes downward API, cgroups v2, or `nproc` fallback.
- The detected count is available as `NUMPROCS` throughout the build and runtime, used for parallel compilation, template rendering, and test execution.
- Eliminates hardcoded job counts and ensures consistent parallelism across Docker, Kubernetes, and CI.

### Declarative dependency management (b19-deps)

- External dependency metadata (URL, version, SHA-512 hash) stored as plain text files, completely separate from build scripts.
- Supports architecture-specific downloads, multi-version series, and nested component paths.
- Dependencies are auto-discovered at Makefile parse time -- add files to the right directory and the build picks them up without manual declarations.
- `make fetch` pre-downloads everything for offline builds; version bumps trigger automatic re-fetch and hash updates.

### Pluggable startup system (entrypoint.d)

- Every container startup runs through a sequence of numbered hooks: signal setup, secrets loading, CPU detection, port validation, template rendering, bootstrap, service start.
- Ad-hoc commands (`docker run img command`) automatically bypass part of the startup chain and execute directly.
- Individual hooks or the entire entrypoint can be skipped at runtime via environment variables, no image rebuild needed.
- Downstream images override a single hook (slot 5000) to launch their service; everything else is inherited.

### Feature toggles for all subsystems

- Every major subsystem (entrypoint, healthchecks, bootstrap, tests, secrets, port validation, i18n, shell hooks) can be disabled at runtime via environment variables.
- Individual entrypoint and bootstrap hooks can be skipped by name without disabling the whole subsystem.
- No image rebuild required -- toggles are runtime-only.

### Built-in health monitoring (healthcheck.d)

- Docker-native healthcheck declared in the base image and inherited by all downstream images with no extra configuration.
- Seven default checks: disk space on home, cache, and temp directories; HTTPS connectivity, DNS resolution, ICMP ping; and filesystem writability.
- Network checks are fault-tolerant -- success on any target counts as pass.
- All network checks automatically skip in offgrid mode; all checks can be disabled at runtime.
- Downstream images add service-specific checks (HTTP endpoints, database connections, process liveness) by dropping scripts into a directory.

### Multilingual shell output (b19-i18n)

- All user-facing log messages and script output are translatable via GNU gettext.
- Ships with English, Spanish (`es_CL`), and Ukrainian (`uk_UA`) out of the box.
- Downstream images inherit all parent translations automatically; only new or overridden strings need translating.
- Translations are compiled at build time with no runtime overhead.

### Image lineage tracking

- Every image records its build metadata (namespace, project, version, base image) into a lineage file during build.
- Downstream images chain lineage from their parent, producing a full base-to-current provenance chain.
- At container startup, the full lineage chain is logged, making it easy to trace what a running container was built from.

### Structured, level-filtered logging (b19-log)

- All container output goes through a leveled logger with four thresholds: error, warn, info, debug.
- Messages below the configured verbosity are silently discarded, keeping production logs clean.
- Colors auto-detect terminal support and respect `NO_COLOR=1`.
- Pipable: command output can be routed through the logger to apply level filtering and tags.

### Non-root container by default

- The container runs as a non-root user (`ubuntu`, UID/GID 1000) with all runtime files owned by that user.
- A two-stage build separates root-level system installation from user-level runtime setup.
- User identity is configurable at build time.

### Air-gapped / offline build and runtime support

- A single environment variable (`B19_OFFGRID_MODE=Y`) cuts all internet access at build time and runtime.
- Build-time: downloads are blocked, APT updates are skipped, SSH keyscans are skipped. All artifacts must come from cache tiers.
- Runtime: network healthchecks automatically skip with a healthy result, so containers stay green on isolated networks.
- APT package lists can be snapshotted and injected for fully offline image builds.
- LAN services (caching proxies, registries) remain reachable -- offgrid blocks internet, not all networking.

### Runtime overlay injection

- Configuration or data files can be injected at container startup by setting `B19_OVERLAY` to a directory name.
- Overlay contents are recursively copied to the container root, overwriting existing files -- no image rebuild needed.
- Skipped in immutable mode, preventing runtime modification of production-locked images.

### Reproducible base image (pinned by digest)

- The Ubuntu base image is pinned by SHA-256 digest, not by tag, ensuring deterministic builds.
- Supports multiple Ubuntu series (resolute, noble, optional: jammy, questing) selectable at build time.
- APT mirrors are configurable per architecture for LAN mirrors or air-gapped environments.

### Port validation

- All `*PORT*` environment variables are validated at startup against the WHATWG blocklist of forbidden ports and privileged ports (\<1024).
- Catches misconfigurations like `PORT=0` or `PORT=22` early, before the service fails silently.
- Can be disabled at runtime without rebuilding the image.

### Unified lifecycle runner family

- Eight numbered-hook runners cover the full container lifecycle: startup, healthchecks, tests, bootstrap, build hooks, benchmarks, reports, and shell sessions.
- All runners share the same pattern: drop a numbered script into a directory, it is auto-discovered and executed.
- Scripts from different image layers merge seamlessly -- upstream and downstream hooks coexist without conflict.
- Each runner has tailored failure semantics: abort on error (entrypoint, bootstrap), continue and count failures (healthchecks, tests), always succeed (reports).

### Docker secrets auto-loading (secrets)

- Docker secrets files are automatically discovered and converted to environment variables at startup.
- Dot-notation filenames map to uppercase env vars (`b19.npm.registry_host` becomes `B19_NPM_REGISTRY_HOST`).
- Required secrets can be declared by name; the container refuses to start if any are missing.
- Existing environment variables take precedence over secret-derived values.
- Secrets are also available in interactive shell sessions and healthchecks.
- Non-UTF-8/binary secrets (keys, DER blobs, gzipped tarballs) are **not** exported as env vars: Bash truncates them at the first NUL and the stray bytes panic any tool that reads the environment as UTF-8 (e.g. `minijinja --env`, used to template configs). They remain on disk at `/run/secrets/<name>` for file-based reads — which is the only correct way to consume a binary secret anyway.

### Interactive shell hooks (shell.d)

- `docker exec bash` sessions automatically load Docker secrets and any custom hooks added by downstream images.
- Hooks merge via Docker layer overlay, so inherited and project-specific shell setup coexist.

### Graceful signal handling

- PID 1 is `tini -g`, which reaps zombie processes and forwards signals to the full process group.
- A configurable set of Unix signals (TERM, INT, HUP, USR1, USR2, etc.) is trapped and forwarded to the main service process.
- `docker stop` cleanly terminates the service without orphan processes or signal loss.

### Jinja2 configuration templates (minijinja-cli)

- Jinja2-compatible template rendering at both build time and container startup.
- Drop a `.j2` file anywhere in the app directory; it is discovered at build time and rendered at every startup with all environment variables available.
- Runtime rendering is parallel and automatic -- downstream images get it with zero configuration.
- Immutable mode (`B19_IMMUTABLE=Y`) locks the filesystem to build-time state, skipping all runtime rendering.

### Built-in test framework (test.d)

- Tests run inside the running container via `make test` or `docker exec`.
- Automatically waits for healthchecks to pass before executing.
- No test framework dependency -- tests are plain shell scripts with exit codes.
- Supports Jinja2 templates in tests, useful for asserting build-time values at runtime.
- Continues on failure and reports the total count; never hides partial results.

### Pre-installed utility tools

- `mold` as default linker for faster linking (opt-out available).
- `fd` for fast file finding, `minijinja-cli` for template rendering.
- `aria2c` for multi-connection downloads, `tini` as PID 1 for zombie reaping.
- Parallel compression tools: `pbzip2`, `pigz`, `pixz`.
- gettext tools for i18n compilation, `cURL` for network operations.

### XDG Base Directory paths

- Standard XDG paths (`XDG_CACHE_HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`) are set under the app home directory.
- All paths are writable by the non-root user without privilege escalation.
<!-- textlint-enable -->
