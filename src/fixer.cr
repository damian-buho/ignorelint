# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The `Fixer` module: auto-fix engine for deterministic, safe corrections.
#
# Not all issues can be auto-fixed. This module maintains a whitelist of
# fixable codes (`FIXABLE_CODES`) and provides a fix for each one. The fix
# pipeline works in three phases:
#
#   1. **Collect** — `collect_fixes` scans all issues and produces an `Array(Fix)`
#      plus an optional `SortFix` for alphabetization.
#
#   2. **Apply** — `apply_fixes` rewrites the file content by applying all
#      individual fixes (replacements and deletions) and then the sort fix.
#
#   3. **Write** — the `CLI` writes the new content back to disk.
#
# ## Design decisions
#
# - Fixes are *deterministic*: the same input always produces the same output.
#   No heuristics, no ambiguity.
# - Deletions (for duplicate rules and redundant built-in excludes) are
#   processed before replacements to avoid index-shifting bugs.
# - Sorting is a bulk operation (`SortFix`) applied after individual fixes,
#   because sorting changes the order of all active lines, not just one.
#
# ## Crystal note: `Set{}`
#
# `Set{...}` creates a `Set` literal — an unordered collection with O(1)
# membership tests. We use it instead of `Array#include?` because the
# `fixable?` check is called for every issue on every file.
require "./fix"
require "./issue"
require "./parser"
require "./pattern"

module Ignorelint
  # The set of `Code` values that can be automatically fixed.
  #
  # This is a module-level constant (created once at program startup) because
  # it never changes. `Set` gives O(1) lookups via `includes?`.
  FIXABLE_CODES = Set{
    Code::TrailingWhitespace,
    Code::UnescapedHash,
    Code::DoubleNegation,
    Code::DuplicateRule,
    Code::DoubleSlash,
    Code::UnsortedRule,
    Code::LeadingWhitespace,
    Code::SlashNoEffect,
    Code::RedundantBuiltinExclude,
  }

  # The fixer module. Uses `extend self` so methods can be called as
  # `Fixer.apply_fixes(...)` without instantiating a class.
  module Fixer
    extend self

    # Check whether a given diagnostic code has an auto-fix available.
    #
    # Used by `CLI#mark_fixed` to decide which issues to relabel as `:fixed`.
    def fixable?(code : Code) : Bool
      FIXABLE_CODES.includes?(code)
    end

    # Generate a `Fix` for a single issue, given the surrounding context of
    # all parsed patterns.
    #
    # Returns `nil` when the issue's code is not fixable or when the pattern
    # for the affected line cannot be found (should not happen in practice).
    #
    # The `patterns` array is needed because the fix needs access to the
    # parsed `Pattern` struct (which holds the decomposed body, flags, etc.)
    # to compute the corrected text.
    def fix_for_issue(issue : Issue, patterns : Array(Pattern)) : Fix?
      pat = patterns.find { |pattern| pattern.line == issue.line }
      return unless pat

      case issue.code
      when .trailing_whitespace?       then fix_trailing_whitespace(pat)
      when .unescaped_hash?            then fix_unescaped_hash(pat)
      when .double_negation?           then fix_double_negation(pat)
      when .duplicate_rule?            then fix_duplicate_rule(pat)
      when .double_slash?              then fix_double_slash(pat)
      when .leading_whitespace?        then fix_leading_whitespace(pat)
      when .slash_no_effect?           then fix_slash_no_effect(pat)
      when .redundant_builtin_exclude? then fix_redundant_builtin_exclude(pat)
      end
    end

    # Collect all fixes for a set of issues. Returns individual line fixes
    # plus a special bulk SortFix when sorting is needed.
    #
    # The separation between individual `Fix` values and the `SortFix` is
    # important: individual fixes are simple line-by-line replacements or
    # deletions, while the `SortFix` reorders all active lines alphabetically.
    # They must be applied in the right order (individual first, then sort)
    # to avoid index-shifting bugs.
    def collect_fixes(issues : Array(Issue), patterns : Array(Pattern),
                      content_lines : Array(String)) : {Array(Fix), SortFix?}
      fixes = [] of Fix
      sort_fix = nil

      issues.each do |issue|
        next unless fixable?(issue.code)

        # Sorting is a bulk operation — don't create individual fixes for each
        # unsorted rule. Instead, build one SortFix that reorders everything.
        if issue.code.unsorted_rule?
          sort_fix ||= build_sort_fix(patterns, content_lines)
          next
        end

        fix = fix_for_issue(issue, patterns)
        fixes << fix if fix
      end

      {fixes, sort_fix}
    end

    # Apply individual fixes + sort fix to content lines, return new content.
    #
    # The algorithm:
    #   1. Detect the file's line-ending style (CRLF vs LF) and chomp all lines
    #   2. Compose per-line fixes (each recomputed on the evolving line text)
    #   3. Apply deletions (remove lines whose fix is a deletion)
    #   4. Apply sort fix (reorder all active lines alphabetically)
    #   5. Re-join with the detected ending, restoring the final newline
    #
    # `content_lines` comes from `content.lines(chomp: false)` — each element
    # may or may not end with `\n`. We normalize by chomping everything and
    # then adding a final ending at the end if the original file had one.
    def apply_fixes(content_lines : Array(String), fixes : Array(Fix),
                    sort_fix : SortFix?) : String
      return content_lines.join if fixes.empty? && sort_fix.nil?

      eol = detect_eol(content_lines)

      # Work with chomped lines to avoid newline mismatch issues.
      # Preserve whether the original content ended with a newline.
      had_final_newline = content_lines.last?.try(&.ends_with?('\n')) || false
      lines = content_lines.map(&.chomp)

      # Track which line indices should be deleted (duplicates, redundant
      # built-in excludes). We collect all deletions first and remove them
      # in one pass to avoid shifting indices during iteration.
      deleted = Set(Int32).new
      apply_line_fixes(lines, fixes, deleted)

      # Remove deleted lines in one pass. The `reject` filter removes lines
      # whose 0-based index is in the `deleted` set, then `map(&.[0])` extracts
      # just the line strings (discarding the index).
      unless deleted.empty?
        lines = lines.each_with_index.reject { |_, i| deleted.includes?(i) }.map(&.[0]).to_a
      end

      # Apply sort fix after deletions so the indices are stable.
      if sort_fix
        lines = apply_sort_fix(lines, sort_fix)
      end

      result = lines.join(eol)
      result += eol if had_final_newline && !result.ends_with?(eol)
      result
    end

    # Detect the file's line-ending style (majority vote, ties go to LF).
    private def detect_eol(content_lines : Array(String)) : String
      crlf = content_lines.count(&.ends_with?("\r\n"))
      lf = content_lines.count { |line| line.ends_with?('\n') && !line.ends_with?("\r\n") }
      crlf > 0 && crlf >= lf ? "\r\n" : "\n"
    end

    # Compose same-line fixes: each fix is recomputed on the evolving text
    # so later fixes see earlier ones (a stored replacement would clobber).
    private def apply_line_fixes(lines : Array(String), fixes : Array(Fix), deleted : Set(Int32)) : Nil
      fixes.group_by(&.line_number).each do |line_number, line_fixes|
        idx = line_number - 1 # Convert 1-based line number to 0-based array index
        next if idx >= lines.size
        if line_fixes.any?(&.deletion?)
          deleted << idx
        else
          text = lines[idx]
          line_fixes.each do |fix|
            text = refine_fix(fix.code, text, line_number)
          end
          lines[idx] = text
        end
      end
    end

    # A SortFix describes which active lines to reorder.
    #
    # Rather than tracking exact indices (which shift after deletions), the
    # sort fix records the active lines' values before and after sorting.
    # `apply_sort_fix` re-scans the post-deletion array for active lines and
    # sorts their content in place, using `needed?` to skip already-sorted input.
    struct SortFix
      getter original_values : Array(String)
      getter sorted_values : Array(String)

      def initialize(@original_values : Array(String), @sorted_values : Array(String))
      end

      # Whether sorting is actually needed (i.e. the file is not already sorted).
      def needed? : Bool
        @original_values != @sorted_values
      end
    end

    # Build a `SortFix` from the parsed patterns and original content lines.
    #
    # Collects all active (non-blank, non-comment) patterns, records their
    # positions and values, and computes the alphabetically sorted order.
    #
    # Returns `nil` if there are fewer than 2 active patterns (nothing to sort).
    private def build_sort_fix(patterns : Array(Pattern),
                               content_lines : Array(String)) : SortFix?
      active = patterns.reject(&.blank?).reject(&.comment?)
      return if active.any?(&.negated?)
      original = [] of String
      active.each do |pat|
        raw = content_lines[pat.line - 1]? || pat.raw
        original << raw.strip
      end

      return if original.size < 2

      SortFix.new(original, original.sort)
    end

    # Apply the sort fix to the (already deletion-adjusted) line array.
    #
    # After individual fixes and deletions, the original indices stored in the
    # `SortFix` may no longer be valid. Instead of tracking index shifts, we
    # re-scan the array for active (non-blank, non-comment) lines and sort
    # their content in-place. This is simpler and more robust.
    private def apply_sort_fix(lines : Array(String), sort_fix : SortFix) : Array(String)
      return lines unless sort_fix.needed?

      # Map original line-number-based indices to current array positions
      # After deletions, indices shift. We need to find where the active lines
      # are now. The SortFix was built with original indices; after deletions
      # the lines moved. We use a simpler approach: find all non-blank,
      # non-comment lines and sort their content.
      result = lines.dup
      active_positions = [] of Int32
      has_negation = false
      result.each_with_index do |line, i|
        stripped = line.strip
        next if stripped.empty?
        next if stripped.starts_with?('#')
        has_negation ||= stripped.starts_with?('!')
        active_positions << i
      end

      return result if has_negation

      return result if active_positions.size < 2

      active_values = active_positions.map { |i| result[i].strip }
      sorted_values = active_values.sort

      active_positions.each_with_index do |pos, i|
        result[pos] = sorted_values[i]
      end

      result
    end

    # Recompute a replacement fix against evolving line text.
    #
    # Stored `Fix#replacement` values are computed from the original line, so
    # same-line fixes must be re-derived in sequence to compose. Deletion codes
    # never reach here (deletion wins the whole line in `apply_fixes`).
    private def refine_fix(code : Code, text : String, line_number : Int32) : String
      pat = Pattern.new(text, line_number)
      case code
      when .trailing_whitespace? then fix_trailing_whitespace(pat).replacement
      when .unescaped_hash?      then fix_unescaped_hash(pat).replacement
      when .double_negation?     then fix_double_negation(pat).replacement
      when .double_slash?        then fix_double_slash(pat).replacement
      when .leading_whitespace?  then fix_leading_whitespace(pat).replacement
      when .slash_no_effect?     then fix_slash_no_effect(pat).replacement
      else                            text
      end
    end

    # -- Individual fix generators -------------------------------------------
    #
    # Each method takes a `Pattern` and returns a `Fix` that corrects the
    # problem. The fix is a simple text transformation on the raw line.

    # Fix: strip trailing spaces/tabs from the pattern line.
    #
    # `"build  "` → `"build"`
    private def fix_trailing_whitespace(pat : Pattern) : Fix
      raw = pat.raw.rstrip
      Fix.new(:trailing_whitespace, pat.line, pat.raw, raw)
    end

    # Fix: escape unescaped `#` characters with a backslash.
    #
    # `"file#1.txt"` → `"file\#1.txt"`
    #
    # The algorithm walks the raw string character by character, tracking
    # escape state and the comment zone. Once inside a comment (line starting
    # with `#`), everything passes through unchanged.
    private def fix_unescaped_hash(pat : Pattern) : Fix
      fixed = String::Builder.new(pat.raw.bytesize)
      escaped = false
      in_comment = pat.raw.lstrip.starts_with?('#')

      pat.raw.each_char do |char|
        if in_comment
          fixed << char
        elsif escaped
          fixed << char
          escaped = false
        elsif char == '\\'
          fixed << char
          escaped = true
        elsif char == '#'
          fixed << "\\#"
        else
          fixed << char
        end
      end

      Fix.new(:unescaped_hash, pat.line, pat.raw, fixed.to_s)
    end

    # Fix: remove the double negation prefix `!!`.
    #
    # `"!!build"` → `"build"`, `"!!!!x"` → `"x"` (pairs cancel out).
    private def fix_double_negation(pat : Pattern) : Fix
      fixed = pat.raw.lstrip
      while fixed.starts_with?("!!")
        fixed = fixed.lchop("!!")
      end
      Fix.new(:double_negation, pat.line, pat.raw, fixed)
    end

    # Fix: delete the duplicate line (empty replacement = deletion).
    #
    # The first occurrence is kept; this fix targets the later duplicate.
    private def fix_duplicate_rule(pat : Pattern) : Fix
      Fix.new(:duplicate_rule, pat.line, pat.raw, "")
    end

    # Fix: collapse double slashes into a single slash.
    #
    # `"src//dist"` → `"src/dist"`, `"a///b"` → `"a/b"`.
    private def fix_double_slash(pat : Pattern) : Fix
      fixed = pat.raw.gsub(/\/\/+/, "/")
      Fix.new(:double_slash, pat.line, pat.raw, fixed)
    end

    # Fix: strip leading whitespace from the pattern line.
    #
    # `"  build"` → `"build"`
    private def fix_leading_whitespace(pat : Pattern) : Fix
      fixed = pat.raw.lstrip
      Fix.new(:leading_whitespace, pat.line, pat.raw, fixed)
    end

    # Fix: strip ineffective leading/trailing slashes (dockerignore).
    #
    # Docker strips slashes before matching, so `"/build"` and `"build/"`
    # behave identically to `"build"`. Remove the confusing slash.
    private def fix_slash_no_effect(pat : Pattern) : Fix
      fixed = pat.raw
      while fixed.starts_with?('/')
        fixed = fixed.lchop('/')
      end
      while fixed.ends_with?('/')
        fixed = fixed.rchop('/')
      end
      Fix.new(:slash_no_effect, pat.line, pat.raw, fixed)
    end

    # Fix: delete the redundant built-in exclude (empty replacement = deletion).
    #
    # Some tools (npm, Prettier, Cloud Foundry) already exclude certain paths
    # by default. Listing them in the ignore file is redundant.
    private def fix_redundant_builtin_exclude(pat : Pattern) : Fix
      Fix.new(:redundant_builtin_exclude, pat.line, pat.raw, "")
    end
  end
end
