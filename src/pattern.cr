# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The `Pattern` struct: a single parsed line from an ignore file.
#
# This is the central data model of the linter. Every line in an ignore file
# (blank lines, comments, negations, globs — everything) is represented as a
# `Pattern`. The struct decomposes the raw text into its semantic parts during
# initialization so the linter and fixer can inspect properties without
# re-parsing.
#
# ## Decomposition example
#
# Given raw input `"!build/"`:
#
#   - `negated`        → `true`  (the `!` prefix)
#   - `directory_only` → `true`  (the trailing `/`)
#   - `rooted`         → `false` (no leading `/` after removing `!`)
#   - `body`           → `"build"` (escape-stripped, flag-removed core)
#
# ## Why a struct, not a class?
#
# Crystal's `struct` is a stack-allocated value type (no GC pressure). Since
# `Pattern` objects are small, immutable, and created in bulk (one per line),
# using a struct avoids thousands of heap allocations during a lint run.
# Structs in Crystal behave like classes (methods, initializers, getters) but
# are passed by value instead of by reference.
module Ignorelint
  struct Pattern
    # The original raw text from the file (with leading `!` and trailing `/`
    # intact). Used in error messages so the user sees exactly what they wrote.
    getter raw : String

    # 1-based line number in the source file. Used to report issue locations.
    getter line : Int32

    # `true` when the line starts with `!` — a negation pattern that
    # re-includes previously excluded files. Not all ignore formats support
    # negation (e.g. `.slugignore` does not).
    getter? negated : Bool

    # `true` when the line ends with `/` — the pattern only matches directories,
    # not files. In `.dockerignore` this distinction is meaningless because
    # Docker strips trailing slashes before matching.
    getter? directory_only : Bool

    # `true` when the pattern starts with `/` (after removing `!`) — it is
    # "rooted" / "anchored" to the directory containing the ignore file.
    # Without a leading `/`, the pattern matches at any depth.
    getter? rooted : Bool

    # The semantic core of the pattern: escape sequences removed, `!` / `/`
    # flags stripped. This is what the linter inspects for glob validity,
    # duplicate detection, and filesystem matching.
    getter body : String

    # Parse a single raw line into its semantic components.
    #
    # The decomposition order matters:
    #   1. Strip trailing `\n` / `\r` (file read artifacts)
    #   2. Detect `!` prefix → `negated`
    #   3. Detect trailing `/` → `directory_only`
    #   4. Detect leading `/` → `rooted`
    #   5. Strip escape backslashes → `body`
    #
    # Each step peels off the detected flag from `remaining` so the next step
    # only sees what is left.
    def initialize(@raw : String, @line : Int32)
      remaining = @raw

      # Strip trailing newline/carriage return before classification
      remaining = remaining.rstrip('\n').rstrip('\r')
      @raw = remaining if @raw != remaining

      # Step 2: detect negation prefix
      @negated = remaining.starts_with?('!')
      remaining = remaining.lchop('!') if @negated

      # Step 3: detect directory-only trailing slash
      @directory_only = remaining.ends_with?('/')
      remaining = remaining.rchop('/') if @directory_only

      # Step 4: detect root anchoring
      @rooted = remaining.starts_with?('/')
      remaining = remaining.lchop('/') if @rooted

      # Step 5: strip escape backslashes for semantic analysis
      @body = remove_escapes(remaining)
    end

    # True for blank (empty or whitespace-only) lines. Blank lines separate
    # groups visually but carry no pattern meaning.
    def blank? : Bool
      @raw.strip.empty?
    end

    # True for comment lines (start with `#` after optional whitespace).
    # Note: in gitignore, `#` is only a comment marker at the start of a line;
    # a `#` mid-pattern is treated as a literal character (and flagged by
    # `has_unescaped_hash?`).
    def comment? : Bool
      @raw.lstrip.starts_with?('#')
    end

    # -- Structural checks ------------------------------------------------

    # Detect trailing spaces or tabs that are invisible in most editors but
    # affect matching behavior. The `\ ` (backslash-space) escape is excluded
    # because it is an intentional escaped space, not accidental whitespace.
    def has_trailing_whitespace? : Bool
      stripped = @raw
      return false if stripped.ends_with?("\\ ")
      stripped.ends_with?(' ') || stripped.ends_with?('\t')
    end

    # Detect leading spaces or tabs before the pattern. In gitignore, leading
    # whitespace is not stripped — the pattern `" foo"` does not match `"foo"`.
    def has_leading_whitespace? : Bool
      return false if blank?
      return false if comment?
      @raw.starts_with?(' ') || @raw.starts_with?('\t')
    end

    # Detect `//` in the pattern body. Double slashes usually indicate a typo
    # (e.g. `"src//dist"` instead of `"src/dist"`). Gitignore does treat `//`
    # as a single `/`, so this is informational, not an error.
    def has_double_slash? : Bool
      return false if blank?
      return false if comment?
      @body.includes?("//")
    end

    # Detect an unescaped `#` inside the pattern body.
    #
    # In gitignore, `#` starts a comment only at the beginning of a line. A
    # `#` mid-pattern (e.g. `"file#1.txt"`) is technically a literal, but
    # most users do not realize this and may intend it as a comment delimiter.
    # The check skips lines that are already comments.
    #
    # The algorithm walks character-by-character tracking the escape state:
    #   - `\\` toggles `in_escape`
    #   - `#` while not escaped → unescaped hash found
    #   - any other character resets `in_escape`
    def has_unescaped_hash? : Bool
      in_escape = false
      @raw.each_char do |char|
        case
        when char == '\\' && !in_escape
          in_escape = true
        when char == '#' && !in_escape && !@raw.lstrip.starts_with?('#')
          return true
        else
          in_escape = false
        end
      end
      false
    end

    # Detect `!!` at the start of a line (after leading whitespace).
    # Double negation cancels out — `"!!foo"` is equivalent to `"foo"`.
    def double_negation? : Bool
      @raw.lstrip.starts_with?("!!")
    end

    # Detect an empty pattern after decomposition (no body text).
    # Lines like `"!"`, `"!/"` or `"/"` carry flags but no pattern text.
    def empty_pattern? : Bool
      @body.empty?
    end

    # -- Glob validity ----------------------------------------------------

    # More than two consecutive asterisks (*** or more).
    # Gitignore only recognizes `*` (any chars except `/`) and `**` (any
    # chars including `/`). Three or more is almost certainly a typo.
    def consecutive_asterisks? : Bool
      return false if comment?
      count = 0
      @raw.each_char do |char|
        if char == '*'
          count += 1
          return true if count > 2
        else
          count = 0
        end
      end
      false
    end

    # Malformed bracket expression: unclosed `[` or empty `[]`.
    #
    # Bracket expressions like `[abc]` match a single character from the set.
    # Common mistakes:
    #   - Unclosed: `[abc` — missing closing bracket
    #   - Empty: `[]` — no characters to match
    #   - Nested: `[a[b]` — brackets inside brackets
    #
    # Runs on the raw line with escape awareness: an escaped `\[` is a
    # literal bracket, not an expression opener.
    def malformed_brackets? : Bool
      return false if comment?
      in_bracket = false
      bracket_start = false
      in_escape = false
      @raw.each_char do |char|
        if in_escape
          in_escape = false
          bracket_start = false if in_bracket
        else
          case char
          when '\\'
            in_escape = true
          when '['
            return true if in_bracket
            in_bracket = true
            bracket_start = true
          when ']'
            return true if bracket_start
            in_bracket = false
            bracket_start = false
          else
            bracket_start = false if in_bracket
          end
        end
      end
      in_bracket # unclosed [
    end

    # `**` used incorrectly: not between `/` separators.
    #
    # In gitignore, `**` is only valid in these positions:
    #   - `a/**/b` — matches zero or more directories between `a` and `b`
    #   - `**/a`   — matches `a` at any depth
    #   - `a/**`   — matches everything inside `a/`
    #
    # Invalid: `a**b`, `**a`, `a**` (not at segment boundary).
    #
    # The check splits the pattern on `/` and ensures any segment containing
    # `**` is *exactly* `"**"` — no extra characters.
    def invalid_doublestar? : Bool
      return false if comment?
      return false unless @body.includes?("**")
      return false if consecutive_asterisks?

      @body.split('/').each do |segment|
        next unless segment.includes?("**")
        # ** must occupy the entire segment on its own
        return true unless segment == "**"
      end
      false
    end

    # -- .gitignore-specific semantic checks --------------------------------

    # `!` followed by `/` — anchoring has no effect on negation.
    #
    # In gitignore, a leading `/` anchors a pattern to the ignore file's
    # directory. But negation patterns (`!`) are already resolved relative to
    # that directory, so adding `/` to a negation is misleading.
    def negated_rooted? : Bool
      negated? && rooted?
    end

    # Pattern contains a leading slash that anchors to root but is followed
    # by no path separators — it only matches at the top level. Often a
    # mistake when the user wanted to match anywhere.
    #
    # Example: `"/build"` matches only `./build`, not `./src/build`.
    # The user likely meant `"build"` (matches at any depth).
    def rooted_shallow? : Bool
      rooted? && !@body.includes?('/')
    end

    # -- Filesystem check helpers ------------------------------------------

    # True when the body contains no UNESCAPED glob metacharacters (*, ?, [)
    # and the pattern is not negated — i.e. it names a concrete path.
    #
    # Scans the raw line (skipping `\`-escaped chars) so an escaped `\*`
    # counts as a literal asterisk, not a glob.
    #
    # Used by filesystem checks to decide whether to test `File.exists?`
    # (for literal patterns) vs. `Dir.glob` (for glob patterns).
    def literal? : Bool
      return false if negated?
      return false if @body.empty?
      in_escape = false
      @raw.each_char do |char|
        if in_escape
          in_escape = false
        elsif char == '\\'
          in_escape = true
        elsif char == '*' || char == '?' || char == '['
          return false
        end
      end
      true
    end

    # -- Conflict detection helpers ----------------------------------------

    # Normalized form for duplicate/conflict comparison: escape-stripped
    # body, trimmed. Case-sensitive: ignore files are (e.g. `"Build"` and
    # `"build"` match different files on case-sensitive filesystems).
    def normalized : String
      @body.strip
    end

    # Does this pattern (as an ignore) conflict with a later negation?
    # A pattern P and a negation !P cancel each other.
    #
    # Scope flags participate: `/build` vs `!build` (rooted vs unrooted)
    # and `build/` vs `!build` (directory-only vs either) match different
    # sets, so they are not exact cancels.
    #
    # Used by `Checks::Conflicts` to detect redundant pairs like
    # `"build"` followed by `"!build"`.
    def conflicts_with?(other : Pattern) : Bool
      return false if negated? == other.negated?
      return false if rooted? != other.rooted?
      return false if directory_only? != other.directory_only?
      normalized == other.normalized
    end

    # -- Helpers -----------------------------------------------------------

    # Strip backslash escape sequences from the pattern body.
    #
    # In gitignore, `\#` means a literal `#` (not a comment). For semantic
    # analysis we want to see the unescaped characters, so `\#` becomes `#`,
    # `\!` becomes `!`, etc.
    #
    # Uses `String::Builder` (Crystal's efficient string builder) to avoid
    # creating intermediate string objects on each concatenation. `bytesize`
    # pre-allocates the builder to at least the input size.
    private def remove_escapes(s : String) : String
      result = String::Builder.new(s.bytesize)
      escaped = false
      s.each_char do |char|
        if escaped
          result << char
          escaped = false
        elsif char == '\\'
          escaped = true
        else
          result << char
        end
      end
      result << '\\' if escaped # trailing lone backslash is literal
      result.to_s
    end
  end
end
