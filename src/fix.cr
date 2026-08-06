# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The `Fix` struct: a single proposed auto-fix for one line.
#
# A `Fix` describes a text replacement: swap `original` (the current line text)
# with `replacement` (the corrected text) on `line_number`. When `replacement`
# is an empty string, the fix is a deletion (used for duplicate rules and
# redundant built-in excludes).
#
# Fixes are produced by `Fixer.fix_for_issue` and collected by
# `Fixer.collect_fixes`. The `CLI` applies them all at once via
# `Fixer.apply_fixes`.
#
# This is a `struct` because fixes are small, immutable data carriers created
# in bulk during the fix-collection phase.
require "./issue"

module Ignorelint
  struct Fix
    # The diagnostic code this fix addresses (e.g. `Code::TrailingWhitespace`).
    getter code : Code

    # 1-based line number in the source file where the fix applies.
    getter line_number : Int32

    # The original text of the line (before the fix).
    getter original : String

    # The corrected text (after the fix). Empty string means "delete this line".
    getter replacement : String

    def initialize(@code : Code, @line_number : Int32, @original : String, @replacement : String)
    end

    # True when this fix removes the line entirely (replacement is empty).
    # Used by `Fixer.apply_fixes` to decide between line deletion and replacement.
    def deletion? : Bool
      @replacement.empty?
    end
  end
end
