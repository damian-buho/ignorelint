# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Helmignore-specific linter and the `HelmignoreStyleLinter` adapter.
#
# `.helmignore` is used by Helm charts to exclude files from the chart archive.
# It follows gitignore syntax with one important caveat:
#
#   - **`**` is not documented**: The Helm documentation does not explicitly
#     state that `**` is supported. While the underlying Go `filepath.Match`
#     may handle it in some versions, relying on `**` is risky because the
#     behavior may vary across Helm versions.
#
# The linter warns on `**` usage so users are aware of the ambiguity.
require "../format_linter"
require "./common_glob"
require "./conflicts"

module Ignorelint
  module Checks
    # Semantic checks specific to helmignore files.
    module HelmignoreSemantics
      extend self

      # Check a single pattern for helmignore-specific issues.
      #
      # Checks:
      #   - IG-016: Helm refuses to load a `.helmignore` with any `**` rule.
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        if pat.body.includes?("**")
          issues << Issue.new(pat.line,
            "\"**\" in \"#{pat.raw}\": Helm rejects a .helmignore rule containing \"**\"",
            :error, :doublestar_unsupported)
        end

        issues
      end
    end
  end

  # The linter adapter for helmignore files.
  #
  # Combines:
  #   1. `CommonGlob.check` — shared glob-validity rules
  #   2. `HelmignoreSemantics.check` — rejected `**` error
  #   3. `Conflicts.check` — cross-pattern conflict detection
  struct HelmignoreStyleLinter
    include FormatLinter

    def check_pattern(pat : Pattern) : Array(Issue)
      issues = Checks::CommonGlob.check(pat)
      issues.concat(Checks::HelmignoreSemantics.check(pat))
      issues
    end

    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
      Checks::Conflicts.check(patterns, issues)
    end
  end
end
