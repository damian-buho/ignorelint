# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The single source of truth for the project version.
#
# This constant is referenced by `CLI` (for `--version`) and by `SarifFormatter`
# (for the `"version"` field in SARIF output). Crystal does not have a built-in
# version-from-shard mechanism at runtime, so we keep it in sync with
# `shard.yml` manually.
module Ignorelint
  VERSION = "0.1.0"
end
