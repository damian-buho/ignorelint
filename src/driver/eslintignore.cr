# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# ESLintignore-specific linter and the `EslintignoreStyleLinter` adapter.
#
# `.eslintignore` follows gitignore syntax with one important difference:
#
#   - **Unrooted patterns are non-recursive**: In gitignore, a pattern like
#     `"build"` matches at any depth (`./build`, `./src/build`, etc.). In
#     `.eslintignore`, an unrooted pattern without `/` or `**` matches only
#     at the same directory level as the ignore file. To match recursively,
#     the user must use `"**/build"` or `"build/**"`.
#
# This difference is a common source of confusion for users who assume
# eslintignore behaves exactly like gitignore.
require "../format_linter"
require "./common_glob"
require "./conflicts"

module Ignorelint
  module Checks
    # Semantic checks specific to eslintignore files.
    module EslintignoreSemantics
      extend self

      # Check a single pattern for eslintignore-specific issues.
      #
      # Checks:
      #   - IG-017: Unrooted pattern without path separators — matches at the
      #     same directory level only (non-recursive). The user likely expects
      #     recursive matching (gitignore behavior) and should use `**/pattern`.
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        # In .eslintignore, unrooted patterns match at the same directory
        # level only (non-recursive), unlike gitignore where they match
        # at any depth. Warn when user likely expects recursive matching.
        if !pat.rooted? && !pat.body.includes?('/') && !pat.body.includes?("**")
          issues << Issue.new(pat.line,
            "Unrooted pattern \"#{pat.raw}\" matches same-directory only in .eslintignore (non-recursive)",
            :warn, :unrooted_non_recursive)
        end

        issues
      end
    end
  end

  # The linter adapter for eslintignore files.
  #
  # Combines:
  #   1. `CommonGlob.check` — shared glob-validity rules
  #   2. `GitignoreSemantics.check` — gitignore-specific rules (reused because
  #      eslintignore shares most gitignore semantics)
  #   3. `EslintignoreSemantics.check` — non-recursive matching warning
  #   4. `Conflicts.check` — cross-pattern conflict detection
  #
  # Overrides `build_glob` because unrooted patterns are non-recursive — no
  # `**/` prefix should be used in dead-rule detection.
  struct EslintignoreStyleLinter
    include FormatLinter

    # Override glob building for eslintignore semantics.
    #
    # In eslintignore, unrooted patterns match same-directory only — they are
    # NOT recursive. For dead-rule detection, this means we should NOT add a
    # `**/` prefix (which would search subdirectories). Both rooted and
    # unrooted patterns resolve to the same direct path.
    def build_glob(pat : Pattern, base_dir : String) : String
      if pat.rooted?
        File.join(base_dir, pat.body)
      else
        File.join(base_dir, pat.body)
      end
    end

    def check_pattern(pat : Pattern) : Array(Issue)
      issues = Checks::CommonGlob.check(pat)
      issues.concat(Checks::GitignoreSemantics.check(pat))
      issues.concat(Checks::EslintignoreSemantics.check(pat))
      issues
    end

    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
      Checks::Conflicts.check(patterns, issues)
    end
  end
end
