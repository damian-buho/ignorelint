# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Binary entry point.
#
# This is the file referenced by `shard.yml` → `targets.ignorelint.main`.
# Crystal compiles this file into the `ignorelint` executable. All it does is
# hand `ARGV` over to the CLI module, which parses flags, discovers files,
# runs the linter, and exits with the appropriate code.
#
# In Crystal, `require "./cli"` loads `src/cli.cr` relative to this file's
# directory. The Crystal compiler resolves `.` to mean "same directory as the
# file doing the require", so this works regardless of the working directory.
require "./cli"

Ignorelint::CLI.run(ARGV)
