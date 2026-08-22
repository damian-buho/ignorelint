# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The project version, baked in at COMPILE time.
#
# Crystal has no linker flag for injecting a value (Go's `-ldflags -X`), so the
# build reads an env var through a macro instead. M6E_VERSION is the fleet's one
# version answer — `m6e-version.sh` resolves it as explicit override > CI tag ref >
# exact git tag > short commit sha — and it is the SAME value the container's OCI
# `version` label carries, so `ignorelint --version` and the image it ships in can
# never disagree. A bare `crystal build` with no env set says "dev", which is the
# honest answer for an unstamped local compile.
#
# Referenced by `CLI` (for `--version`) and by `SarifFormatter` (the `"version"`
# field of its tool driver).
module Ignorelint
  VERSION = {{ env("M6E_VERSION") || "dev" }}
end
