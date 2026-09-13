# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Prettierignore-specific linter and the `PrettierignoreStyleLinter` adapter.
#
# `.prettierignore` follows gitignore syntax with built-in excludes:
#
#   - Certain directories are always excluded by Prettier regardless of
#     `.prettierignore` content (e.g., `.git`, `node_modules`). Listing these
#     is redundant.
require "../format_linter"
require "./common_glob"
require "./conflicts"

module Ignorelint
  module Checks
    # Semantic checks specific to prettierignore files.
    module PrettierignoreSemantics
      extend self

      # Directories always excluded by Prettier, regardless of `.prettierignore`.
      #
      # See: https://prettier.io/docs/en/ignore.html
      BUILTIN_EXCLUDES = {
        ".git",
        ".svn",
        ".hg",
        "node_modules",
      }

      # Check a single pattern for prettierignore-specific issues.
      #
      # Checks:
      #   - IG-018: Pattern duplicates a built-in exclude (redundant)
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        if !pat.negated? && matches_builtin?(pat.body)
          issues << Issue.new(pat.line,
            "\"#{pat.raw}\" is already excluded by default in Prettier — redundant pattern",
            :info, :redundant_builtin_exclude)
        end

        issues
      end

      # Check if the pattern body matches a built-in exclude.
      private def matches_builtin?(body : String) : Bool
        BUILTIN_EXCLUDES.includes?(body)
      end
    end
  end

  # The linter adapter for prettierignore files.
  #
  # Combines:
  #   1. `CommonGlob.check` — shared glob-validity rules
  #   2. `GitignoreSemantics.check` — gitignore-specific rules (reused)
  #   3. `PrettierignoreSemantics.check` — redundant built-in exclude check
  #   4. `Conflicts.check` — cross-pattern conflict detection
  struct PrettierignoreStyleLinter
    include FormatLinter

    def check_pattern(pat : Pattern) : Array(Issue)
      issues = Checks::CommonGlob.check(pat)
      issues.concat(Checks::GitignoreSemantics.check(pat))
      issues.concat(Checks::PrettierignoreSemantics.check(pat))
      issues
    end

    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
      Checks::Conflicts.check(patterns, issues)
    end
  end
end
