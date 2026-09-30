# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Supported output formats for lint results.
#
# Each value corresponds to a concrete `Formatter` subclass:
#
#   - `Human`       → `HumanFormatter`     — colored terminal output
#   - `Gnu`         → `GnuFormatter`       — one `path:line: severity: CODE message` per line
#   - `Json`        → `JsonFormatter`       — machine-readable JSON
#   - `Checkstyle`  → `CheckstyleFormatter` — XML for CI integrations
#   - `Junit`       → `JunitFormatter`      — testsuite/testcase XML for test reporters
#   - `GitlabCodeclimate` → `GitlabCodeclimateFormatter` — Code Climate JSON for GitLab
#   - `Codacy`      → `CodacyFormatter`     — generic issue JSON for Codacy
#   - `Sonarqube`   → `SonarqubeFormatter`  — generic issue JSON for SonarQube
#   - `Sarif`       → `SarifFormatter`      — SARIF 2.1.0 for GitHub Advanced Security
#
# Crystal enums are value types (like structs). Each member gets an integer
# index starting at 0. You can pattern-match on them with `case` using the
# `when .human?` shorthand (the `?` is a macro-generated predicate method).
module Ignorelint
  enum OutputFormat
    Human
    Gnu
    Json
    Checkstyle
    Junit
    GitlabCodeclimate
    Codacy
    Sonarqube
    Sarif

    # Parse a format name string into the enum value.
    #
    # Returns `nil` if the string does not match any known format (used by the
    # CLI to detect invalid `--format` arguments).
    #
    # `tty` is an accepted alias of `human`.
    #
    # In Crystal, `self.` in an enum method refers to the enum type, and the
    # return type `OutputFormat?` means "OutputFormat or Nil" (a union type).
    def self.parse?(value : String) : OutputFormat?
      case value.downcase
      when "human", "tty"       then Human
      when "gnu"                then Gnu
      when "json"               then Json
      when "checkstyle"         then Checkstyle
      when "junit"              then Junit
      when "gitlab_codeclimate" then GitlabCodeclimate
      when "codacy"             then Codacy
      when "sonarqube"          then Sonarqube
      when "sarif"              then Sarif
      end
    end

    # Human-readable list of all valid format names, for error messages and help text.
    def self.valid_values : String
      "human|tty|gnu|json|checkstyle|junit|gitlab_codeclimate|codacy|sonarqube|sarif"
    end
  end
end
