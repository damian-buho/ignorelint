# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Slugignore-specific linter and the `SlugignoreStyleLinter` adapter.
#
# Slugignore (`.slugignore`) is used by Heroku/SLC buildpacks. It has simpler
# semantics than gitignore:
#
#   - **No negation**: the `!` prefix is not supported. Every line is an
#     ignore pattern — there is no way to re-include files.
#   - Glob patterns follow basic gitignore syntax.
#
# Because it lacks negation support, the conflict detection module (`Conflicts`)
# is not used — there can be no ignore/negation conflicts without negation.
require "../format_linter"
require "./common_glob"

module Ignorelint
  module Checks
    # Semantic checks specific to slugignore files.
    module SlugignoreSemantics
      extend self

      # Check a single pattern for slugignore-specific issues.
      #
      # Checks:
      #   - IG-013: Negation (`!`) is not supported in slugignore.
      #     Heroku's slug compiler does not understand the `!` prefix — the
      #     pattern `"!important.txt"` would be treated as a literal filename,
      #     not a re-inclusion rule.
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        if pat.negated?
          issues << Issue.new(pat.line, "Negation not supported in slugignore: \"#{pat.raw}\"", :error,
            :negation_unsupported)
        end

        issues
      end
    end
  end

  # The linter adapter for slugignore files.
  #
  # Combines:
  #   1. `CommonGlob.check` — shared glob-validity rules
  #   2. `SlugignoreSemantics.check` — negation-not-supported check
  #
  # Does NOT use `Conflicts.check` because slugignore has no negation support.
  struct SlugignoreStyleLinter
    include FormatLinter

    def check_pattern(pat : Pattern) : Array(Issue)
      issues = Checks::CommonGlob.check(pat)
      issues.concat(Checks::SlugignoreSemantics.check(pat))
      issues
    end

    # No cross-pattern conflict detection — slugignore has no negation.
    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
    end
  end
end
