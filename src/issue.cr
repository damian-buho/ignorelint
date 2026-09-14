# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Issue reporting types: severity levels, diagnostic codes, and the `Issue` struct.
#
# This file defines the vocabulary for every problem the linter can report.
# Each lint check produces one or more `Issue` values, tagged with a `Code`
# (e.g. `:trailing_whitespace`) and a `Severity` (e.g. `:warn`). The formatters
# then render these issues in the chosen output format.
#
# ## Adding a new lint rule
#
# 1. Add a member to the `Code` enum
# 2. Add entries in `CODE_TAG_MAP` and `CODE_TITLE_MAP`
# 3. Implement the check in `Linter` or a format-specific driver
# 4. (Optional) Add auto-fix support in `Fixer`
module Ignorelint
  # Severity levels for lint issues, ordered from most to least serious.
  #
  # Crystal enums are backed by integers starting at 0, so `Error.value` is 0,
  # `Warn.value` is 1, etc. This ordering allows the CLI to compare severity
  # values numerically: `issue.severity.value <= @fail_on.value`.
  #
  # `Fixed` is a pseudo-severity — it replaces the original severity when the
  # `--fix` flag auto-corrects an issue. It is not produced by any lint check;
  # only `CLI#mark_fixed` sets it.
  enum Severity
    Error
    Warn
    Info
    Fixed
  end

  # Machine-readable diagnostic codes for every known lint rule.
  #
  # Each code maps to a human-readable `"IG-NNN"` tag via `#tag`. The tag
  # appears in all output formats (human, JSON, Checkstyle, SARIF) so users
  # can suppress or search for specific rules.
  #
  # The naming convention is `CamelCase` for the Crystal enum member and
  # `snake_case` for the `:symbol` used in `Issue.new(...)`.
  CODE_TAG_MAP = {
    Code::TrailingWhitespace      => "IG-001",
    Code::UnescapedHash           => "IG-002",
    Code::DoubleNegation          => "IG-003",
    Code::EmptyPattern            => "IG-004",
    Code::ConsecutiveStar         => "IG-005",
    Code::MalformedBrackets       => "IG-006",
    Code::SpaceInPattern          => "IG-007",
    Code::DuplicateRule           => "IG-008",
    Code::InvalidDoublestar       => "IG-009",
    Code::RootedShallow           => "IG-010",
    Code::NegatedRooted           => "IG-011",
    Code::RedundantPair           => "IG-012",
    Code::NegationUnsupported     => "IG-013",
    Code::PathTraversal           => "IG-014",
    Code::SlashNoEffect           => "IG-015",
    Code::DoublestarUnsupported   => "IG-016",
    Code::UnrootedNonRecursive    => "IG-017",
    Code::RedundantBuiltinExclude => "IG-018",
    Code::BuiltinIncludeProtected => "IG-019",
    Code::PathNotFound            => "IG-020",
    Code::DeadGlobRule            => "IG-021",
    Code::DoubleSlash             => "IG-022",
    Code::UnsortedRule            => "IG-023",
    Code::LeadingWhitespace       => "IG-024",
    Code::CaseMismatch            => "IG-025",
  }

  # Every known diagnostic tag in upper case, for override validation.
  VALID_TAGS = CODE_TAG_MAP.values.to_set
  # Human-readable rule titles, e.g. for SARIF `shortDescription`.
  CODE_TITLE_MAP = {
    Code::TrailingWhitespace      => "Trailing whitespace",
    Code::UnescapedHash           => "Unescaped hash",
    Code::DoubleNegation          => "Double negation",
    Code::EmptyPattern            => "Empty pattern",
    Code::ConsecutiveStar         => "Consecutive asterisks",
    Code::MalformedBrackets       => "Malformed brackets",
    Code::SpaceInPattern          => "Space in pattern",
    Code::DuplicateRule           => "Duplicate rule",
    Code::InvalidDoublestar       => "Invalid doublestar",
    Code::RootedShallow           => "Rooted shallow pattern",
    Code::NegatedRooted           => "Negated rooted pattern",
    Code::RedundantPair           => "Redundant pair",
    Code::NegationUnsupported     => "Negation unsupported",
    Code::PathTraversal           => "Path traversal",
    Code::SlashNoEffect           => "Slash has no effect",
    Code::DoublestarUnsupported   => "Doublestar unsupported",
    Code::UnrootedNonRecursive    => "Unrooted non-recursive pattern",
    Code::RedundantBuiltinExclude => "Redundant built-in exclude",
    Code::BuiltinIncludeProtected => "Built-in include protected",
    Code::PathNotFound            => "Path not found",
    Code::DeadGlobRule            => "Dead glob rule",
    Code::DoubleSlash             => "Double slash",
    Code::UnsortedRule            => "Unsorted rule",
    Code::LeadingWhitespace       => "Leading whitespace",
    Code::CaseMismatch            => "Case mismatch",
  }

  enum Code
    TrailingWhitespace
    UnescapedHash
    DoubleNegation
    EmptyPattern
    ConsecutiveStar
    MalformedBrackets
    SpaceInPattern
    DuplicateRule
    InvalidDoublestar
    RootedShallow
    NegatedRooted
    RedundantPair
    NegationUnsupported
    PathTraversal
    SlashNoEffect
    DoublestarUnsupported
    UnrootedNonRecursive
    RedundantBuiltinExclude
    BuiltinIncludeProtected
    PathNotFound
    DeadGlobRule
    DoubleSlash
    UnsortedRule
    LeadingWhitespace
    CaseMismatch

    def tag : String
      CODE_TAG_MAP[self]? || "IG-???"
    end

    # Override `to_s` so that string interpolation of a `Code` produces the
    # tag instead of the enum member name. E.g. `"#{code}"` yields `"IG-001"`
    # instead of `"TrailingWhitespace"`.
    def to_s(io : IO) : Nil
      io << tag
    end

    # Human-readable rule title (e.g. for SARIF `shortDescription`).
    def title : String
      CODE_TITLE_MAP[self]? || raise "missing Code#title for #{tag}"
    end
  end

  # A single lint finding — one problem detected on one line of an ignore file.
  #
  # Issues are collected during `Linter.lint` and passed to formatters for
  # output. When `--fix` is active, issues with fixable codes get their
  # severity changed to `Fixed` after the fix is applied.
  #
  # This is a `struct` (value type) because issues are created in bulk and
  # never mutated after creation (except by `CLI#mark_fixed`, which creates
  # new Issue instances rather than mutating existing ones).
  struct Issue
    # 1-based line number where the issue was found.
    getter line : Int32

    # Human-readable description of the problem, suitable for terminal output.
    getter message : String

    # How serious this issue is. Controls exit code and color in output.
    getter severity : Severity

    # Machine-readable diagnostic code (e.g. `Code::TrailingWhitespace`).
    getter code : Code

    def initialize(@line : Int32, @message : String, @severity : Severity = :error,
                   @code : Code = :trailing_whitespace)
    end
  end
end
