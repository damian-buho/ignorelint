# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Gitignore-style linter and the `GitignoreStyleLinter` adapter.
#
# This is the default linter for most ignore file formats (`.gitignore`,
# `.claudeignore`, `.stylelintignore`, `.yarnignore`, etc.) because the
# vast majority of `*ignore` files follow gitignore semantics:
#
#   - `#` starts a comment
#   - `!` negates a pattern
#   - `/` anchors to the ignore file's directory
#   - `**` matches across directory boundaries
#   - trailing `/` matches directories only
#
# ## Architecture
#
# The checks are split into composable modules under `Ignorelint::Checks`:
#
#   - `CommonGlob` — glob-validity checks shared by most formats
#   - `GitignoreSemantics` — gitignore-specific semantic checks
#   - `Conflicts` — adjacent ignore/negation pair detection
#
# The `GitignoreStyleLinter` struct combines these checks by calling them
# in sequence. This composition pattern avoids deep inheritance hierarchies
# and makes it easy to add checks to specific formats.
require "../format_linter"
require "./common_glob"
require "./conflicts"

module Ignorelint
  module Checks
    # Gitignore-specific semantic checks.
    #
    # These rules catch patterns that are technically valid but likely
    # indicate a misunderstanding of gitignore semantics.
    module GitignoreSemantics
      extend self

      # Check a single pattern for gitignore-specific issues.
      #
      # Currently checks:
      #   - IG-011: Negated pattern with leading `/` — anchoring has no
      #     effect on negation because negated patterns are already relative
      #     to the ignore file's directory.
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        if pat.negated_rooted?
          issues << Issue.new(pat.line, "Negated pattern \"#{pat.raw}\" — anchoring has no effect on negation", :warn,
            :negated_rooted)
        end

        issues
      end
    end
  end

  # The linter adapter for gitignore-style files.
  #
  # Combines three sets of checks:
  #   1. `CommonGlob.check` — shared glob-validity rules (IG-009, IG-010)
  #   2. `GitignoreSemantics.check` — gitignore-specific rules (IG-011)
  #   3. `Conflicts.check` — cross-pattern conflict detection (IG-012)
  #
  # This is a `struct` that `include FormatLinter`. The struct is instantiated
  # once in `FormatLinterRegistry::LINTERS` and reused for every file.
  struct GitignoreStyleLinter
    include FormatLinter

    # Check a single pattern: common glob + gitignore-specific checks.
    def check_pattern(pat : Pattern) : Array(Issue)
      issues = Checks::CommonGlob.check(pat)
      issues.concat(Checks::GitignoreSemantics.check(pat))
      issues
    end

    # Check the full pattern list for cross-pattern conflicts.
    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
      Checks::Conflicts.check(patterns, issues)
    end
  end
end
