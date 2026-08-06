# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Output formatters: `FileResult`, `Formatter` base class, and concrete implementations.
#
# The formatter hierarchy converts `Issue` values into structured output:
#
#   - `HumanFormatter` — colored terminal output for interactive use
#   - `JsonFormatter` — machine-readable JSON for tooling integration
#   - `CheckstyleFormatter` — XML for CI systems that consume Checkstyle reports
#   - `SarifFormatter` — SARIF 2.1.0 for GitHub Advanced Security code scanning
#
# All formatters follow a three-phase lifecycle:
#
#   1. `start(io)` — called once before any files are processed
#   2. `format_file(result, io)` — called once per file
#   3. `finish(io)` — called once after all files are processed
#
# This allows streaming formatters (like HumanFormatter) to emit output
# immediately, while batch formatters (like JsonFormatter, SarifFormatter)
# collect everything and emit in `finish`.
#
# ## Crystal note: `abstract class` vs `abstract def`
#
# `Formatter` is an `abstract class` — you cannot instantiate it directly.
# The three `abstract def` methods must be implemented by subclasses. Crystal
# enforces this at compile time: if a subclass is missing an implementation,
# the program will not compile.
#
# ## Crystal note: `require` at the bottom
#
# The concrete formatter `require` statements are at the bottom of this file
# because each formatter file references types defined here (`Formatter`,
# `FileResult`). Crystal's `require` is single-pass, so the base types must
# be defined before the concrete types that inherit from them.
require "./issue"

module Ignorelint
  # The lint result for a single file, ready for formatting.
  #
  # Bundles the file path with its issues. The `CLI` creates one `FileResult`
  # per file and passes it to the active `Formatter`.
  #
  # This is a `struct` because it is a small, immutable data carrier — created
  # once and passed to the formatter without modification.
  struct FileResult
    # The file path (as given by the user or discovered by auto-discovery).
    getter path : String

    # All issues found in this file (may be empty if the file is clean).
    getter issues : Array(Issue)

    def initialize(@path : String, @issues : Array(Issue))
    end
  end

  # Abstract base class for all output formatters.
  #
  # Subclasses must implement the three-phase lifecycle:
  #   - `start`: called before processing begins
  #   - `format_file`: called once per linted file
  #   - `finish`: called after all files are processed
  #
  # The `io` parameter is the output stream (usually STDOUT). Formatters
  # write directly to it — they do not buffer internally (except for
  # JSON/SARIF which need the complete structure before writing).
  #
  # ## Crystal note: `abstract class` vs `module`
  #
  # We use an abstract class (not a module) because formatters need per-instance
  # state (e.g., `HumanFormatter` stores `@color`, `JsonFormatter` collects
  # `@results`). Modules in Crystal cannot have per-instance state when used
  # via `include` — they share state with the including type.
  abstract class Formatter
    # Called once before any files are processed. Use for document headers.
    abstract def start(io : IO) : Nil

    # Called once per file with the lint results for that file.
    abstract def format_file(result : FileResult, io : IO) : Nil

    # Called once after all files are processed. Use for document footers
    # and final aggregation (e.g., JSON total count).
    abstract def finish(io : IO) : Nil
  end
end

# Load concrete formatter implementations.
# Each file defines a subclass of `Formatter`.
require "./formatter/human"
require "./formatter/json"
require "./formatter/checkstyle"
require "./formatter/sarif"
