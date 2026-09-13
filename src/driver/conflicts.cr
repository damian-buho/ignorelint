# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Cross-pattern conflict detection: find negation/ignore pairs that cancel out.
#
# When a pattern is ignored and then immediately negated (e.g. `"build"` on
# line 5 followed by `"!build"` on line 6), the two rules cancel each other.
# This is almost always a mistake — the user likely removed one of them and
# forgot to clean up the other.
#
# Only *adjacent* pairs are flagged (the negation must come right after the
# ignore) because non-adjacent patterns may be intentional (e.g., ignore
# everything then re-include specific files).
require "../issue"
require "../pattern"

module Ignorelint
  module Checks
    # Detect redundant ignore/negation pairs.
    #
    # Scans the active (non-blank, non-comment) pattern list for negated
    # patterns that immediately follow their non-negated counterpart.
    module Conflicts
      extend self

      # Check all patterns for adjacent ignore/negation conflicts.
      #
      # Only flags pairs adjacent in the active list (blanks and comments
      # aside) — non-adjacent pairs may be intentional (e.g., ignore
      # everything then re-include specific files). Both orders are
      # covered: an ignore cancelled by a negation, and a negation made
      # dead by a later ignore.
      #
      # Mutates `issues` in place by appending found conflicts.
      def check(patterns : Array(Pattern), issues : Array(Issue)) : Nil
        active = patterns.reject(&.blank?).reject(&.comment?)
        active.each_cons(2) do |pair|
          first, second = pair[0], pair[1]
          if second.negated? && !first.negated? && second.conflicts_with?(first)
            issues << Issue.new(second.line,
              "Redundant pair — \"#{second.raw}\" cancels \"#{first.raw}\" on line #{first.line}", :warn,
              :redundant_pair)
          elsif first.negated? && !second.negated? && second.conflicts_with?(first)
            issues << Issue.new(second.line,
              "Redundant pair — \"#{second.raw}\" overrides earlier \"#{first.raw}\" on line #{first.line}", :warn,
              :redundant_pair)
          end
        end
      end
    end
  end
end
