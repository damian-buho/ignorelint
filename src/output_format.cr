# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Supported output formats for lint results.
#
# Each value corresponds to a concrete `Formatter` subclass:
#
#   - `Human`       → `HumanFormatter`     — colored terminal output
#   - `Json`        → `JsonFormatter`       — machine-readable JSON
#   - `Checkstyle`  → `CheckstyleFormatter` — XML for CI integrations
#   - `Sarif`       → `SarifFormatter`      — SARIF 2.1.0 for GitHub Advanced Security
#
# Crystal enums are value types (like structs). Each member gets an integer
# index starting at 0. You can pattern-match on them with `case` using the
# `when .human?` shorthand (the `?` is a macro-generated predicate method).
module Ignorelint
  enum OutputFormat
    Human
    Json
    Checkstyle
    Sarif

    # Parse a format name string into the enum value.
    #
    # Returns `nil` if the string does not match any known format (used by the
    # CLI to detect invalid `--format` arguments).
    #
    # In Crystal, `self.` in an enum method refers to the enum type, and the
    # return type `OutputFormat?` means "OutputFormat or Nil" (a union type).
    def self.parse?(value : String) : OutputFormat?
      case value.downcase
      when "human"      then Human
      when "json"       then Json
      when "checkstyle" then Checkstyle
      when "sarif"      then Sarif
      end
    end

    # Human-readable list of all valid format names, for error messages and help text.
    def self.valid_values : String
      "human|json|checkstyle|sarif"
    end
  end
end
