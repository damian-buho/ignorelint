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
      # For each negated pattern, walks backwards through earlier active
      # patterns to find a matching non-negated one. Only flags the pair
      # when the negation immediately follows the ignore (they are adjacent
      # in the active pattern list, ignoring blanks and comments).
      #
      # Mutates `issues` in place by appending found conflicts.
      def check(patterns : Array(Pattern), issues : Array(Issue)) : Nil
        active = patterns.reject(&.blank?).reject(&.comment?)
        active.each_with_index do |pat, i|
          next unless pat.negated?

          active[0...i].reverse_each do |prev|
            next if prev.negated?
            if pat.conflicts_with?(prev)
              # Only flag when the two are adjacent (right next to each other
              # in the active list) — non-adjacent pairs may be intentional
              if i > 0 && active[i - 1] == prev
                issues << Issue.new(pat.line,
                  "Redundant pair — \"#{pat.raw}\" cancels \"#{prev.raw}\" on line #{prev.line}", :warn,
                  :redundant_pair)
              end
            end
          end
        end
      end
    end
  end
end
