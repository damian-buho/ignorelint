# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The `Linter` module: core linting engine that orchestrates all checks.
#
# This is the heart of ignorelint. `Linter.lint` takes a file path and its
# content, runs all applicable checks, and returns a `LintResult` containing
# every issue found and every pattern parsed.
#
# ## Check pipeline
#
# The linter runs checks in four phases:
#
#   1. **Universal checks** — apply to all ignore file formats (trailing
#      whitespace, duplicate rules, unsorted rules, etc.)
#
#   2. **Format-specific checks** — delegate to a `FormatLinter` adapter
#      based on the file type (e.g. dockerignore gets path-traversal checks,
#      npmignore gets redundant-built-in checks)
#
#   3. **Filesystem checks** — detect dead rules by checking whether literal
#      paths exist and whether glob patterns match any files on disk
#
#   4. **Sort** — issues are sorted by line number for deterministic output
#
# ## Crystal note: `module` with `extend self`
#
# The `Linter` module uses `extend self` so its methods can be called without
# instantiation: `Linter.lint(path, content)`. This is Crystal's idiomatic way
# to create a stateless service — no object is needed because there is no
# mutable state to track.
require "./fix"
require "./fixer"
require "./issue"
require "./format_linter"
require "./parser"

module Ignorelint
  # The result of linting one file.
  #
  # Contains both the discovered `issues` and the parsed `patterns`. The
  # patterns are kept so the `CLI` can use them for auto-fixing (fixes need
  # access to the `Pattern` structs, not just the issues).
  #
  # This is a `struct` (value type) because it is created once per file and
  # never mutated after construction.
  struct LintResult
    # All issues found during linting, sorted by line number.
    getter issues : Array(Issue)

    # All patterns parsed from the file (including blanks and comments).
    getter patterns : Array(Pattern)

    def initialize(@issues : Array(Issue) = [] of Issue,
                   @patterns : Array(Pattern) = [] of Pattern)
    end

    # True when no issues were found (the file is clean).
    def ok? : Bool
      @issues.empty?
    end

    # Convenience: delegate fix collection to `Fixer`.
    #
    # The CLI calls this when `--fix` is active. It bridges the lint result
    # to the fixer without the CLI needing to pass `issues` and `patterns`
    # separately.
    def collect_fixes(content_lines : Array(String)) : {Array(Fix), Fixer::SortFix?}
      Fixer.collect_fixes(@issues, @patterns, content_lines)
    end
  end

  # The main linting module. Stateless — all data flows through parameters.
  module Linter
    extend self

    # Lint a single ignore file and return all found issues.
    #
    # Parameters:
    #   - `path`: file path (used for format detection and error messages)
    #   - `content`: the full file content as a string
    #
    # Returns a `LintResult` with all issues sorted by line number and all
    # parsed patterns.
    #
    # The method never raises — all errors are represented as `Issue` values
    # with appropriate severity levels.
    def lint(path : String, content : String) : LintResult
      # Phase 0: Parse the file into Pattern structs
      patterns = Parser.parse(content)
      file_type = Ignorelint.file_type_from_path(path)
      issues = [] of Issue

      # Phase 1: Universal checks (apply to ALL ignore file formats)
      # These catch problems that are wrong regardless of the tool consuming
      # the ignore file: trailing whitespace, duplicate rules, malformed globs.
      seen = {} of String => Int32
      patterns.each do |pat|
        next if pat.blank? || pat.comment?
        issues.concat(check_universal(pat, path))
        check_duplicate(pat, seen, issues)
      end

      check_unsorted(patterns, issues)

      # Phase 2: Format-specific checks (via the adapter pattern)
      # Each ignore format has its own semantics. For example, dockerignore
      # strips slashes before matching, so leading/trailing `/` is meaningless.
      # The FormatLinter adapter for each file type knows these quirks.
      format_linter = FormatLinterRegistry.for(file_type)
      format_linter.check_patterns(patterns, issues)
      patterns.each do |pat|
        next if pat.blank? || pat.comment?
        issues.concat(format_linter.check_pattern(pat))
      end

      # Phase 3: Filesystem checks (dead-rule detection)
      # These check whether the patterns actually match anything on disk.
      # A rule that matches no files is likely stale (e.g., ignoring a
      # directory that was deleted months ago).
      base_dir = File.dirname(File.expand_path(path))
      if Dir.exists?(base_dir)
        patterns.each do |pat|
          next if pat.blank? || pat.comment?
          next if pat.negated? # Negated patterns re-include, not ignore — skip dead-rule check
          check_path_exists(pat, base_dir, issues)
          check_glob_matches(pat, base_dir, issues, format_linter)
        end
      end

      # Sort issues by line number for deterministic, editor-friendly output
      LintResult.new(issues: issues.sort_by(&.line), patterns: patterns)
    end

    # -- Universal checks (all ignore formats) ----------------------------
    #
    # These checks are format-agnostic. They catch structural problems that
    # are wrong no matter which tool reads the ignore file.

    # Run all universal checks on a single pattern.
    #
    # Returns an array of issues (may be empty if the pattern is clean).
    private def check_universal(pat : Pattern, path : String) : Array(Issue)
      issues = [] of Issue

      check_structural(pat, issues)
      check_whitespace_and_format(pat, path, issues)

      issues
    end

    private def check_structural(pat : Pattern, issues : Array(Issue)) : Nil
      if pat.has_trailing_whitespace?
        issues << Issue.new(pat.line, "Trailing whitespace in \"#{pat.raw}\"", :warn,
          :trailing_whitespace)
      end

      if pat.has_unescaped_hash?
        issues << Issue.new(pat.line, "Unescaped # in \"#{pat.raw}\"", :warn,
          :unescaped_hash)
      end

      if pat.double_negation?
        issues << Issue.new(pat.line, "Double negation \"#{pat.raw}\" cancels out", :error,
          :double_negation)
      end

      if pat.empty_pattern?
        issues << Issue.new(pat.line, "Empty pattern \"#{pat.raw}\"", :error,
          :empty_pattern)
      end

      if pat.consecutive_asterisks?
        issues << Issue.new(pat.line, "Consecutive *** in \"#{pat.body}\"", :error,
          :consecutive_star)
      end

      if pat.malformed_brackets?
        issues << Issue.new(pat.line, "Malformed bracket expression in \"#{pat.body}\"", :error,
          :malformed_brackets)
      end
    end

    private def check_whitespace_and_format(pat : Pattern, path : String, issues : Array(Issue)) : Nil
      if !dockerignore?(path) && pat.body.includes?(' ')
        issues << Issue.new(pat.line, "Space in pattern \"#{pat.raw}\"", :warn,
          :space_in_pattern)
      end

      if pat.has_leading_whitespace?
        issues << Issue.new(pat.line, "Leading whitespace in \"#{pat.raw}\"", :warn,
          :leading_whitespace)
      end

      if pat.has_double_slash?
        issues << Issue.new(pat.line, "Double slash in \"#{pat.raw}\"", :warn,
          :double_slash)
      end
    end

    # IG-008: Detect duplicate patterns.
    #
    # Uses a `seen` hash to track which raw patterns have already appeared
    # and on which line. When the same raw text appears again, a duplicate
    # warning is emitted pointing to the original line.
    private def check_duplicate(pat : Pattern, seen : Hash(String, Int32), issues : Array(Issue)) : Nil
      key = pat.raw.strip
      if prev = seen[key]?
        issues << Issue.new(pat.line, "Duplicate of line #{prev}: \"#{pat.raw}\"", :warn,
          :duplicate_rule)
      else
        seen[key] = pat.line
      end
    end

    # IG-023: Check that all active (non-blank, non-comment) patterns are
    # sorted alphabetically (case-sensitive).
    #
    # Skipped when any active pattern is negated: negation order is semantic
    # (last match wins), so sorting would change what the file ignores.
    #
    # Only reports the first unsorted line to avoid flooding the output.
    # The `--fix` flag will sort all active lines at once.
    private def check_unsorted(patterns : Array(Pattern), issues : Array(Issue)) : Nil
      active = patterns.reject(&.blank?).reject(&.comment?)
      return if active.any?(&.negated?)
      sorted = active.map(&.raw.strip).sort!
      active.each_with_index do |pat, i|
        if pat.raw.strip != sorted[i]
          issues << Issue.new(pat.line, "Unsorted rule \"#{pat.raw.strip}\"", :info,
            :unsorted_rule)
          return # Report only the first unsorted rule
        end
      end
    end

    # -- Filesystem checks ---------------------------------------------------
    #
    # These checks look at the actual filesystem to detect dead rules —
    # patterns that don't match any existing files or directories.

    # IG-020: Check whether a literal pattern matches an existing path.
    #
    # For patterns without glob metacharacters (e.g. `"build"`, `"dist/"`),
    # we check `File.exists?` / `Dir.exists?` directly. If the target does
    # not exist, the rule is likely stale.
    private def check_path_exists(pat : Pattern, base_dir : String, issues : Array(Issue)) : Nil
      return unless pat.literal?

      target = File.join(base_dir, pat.body)
      return if File.exists?(target) || Dir.exists?(target)

      kind = pat.directory_only? ? "Directory" : "Path"
      issues << Issue.new(pat.line, "#{kind} \"#{pat.body}\" does not exist", :info,
        :path_not_found)
    end

    # IG-021: Check whether a glob pattern matches any files on disk.
    #
    # For patterns with glob metacharacters (e.g. `"*.log"`, `"src/**/test"`),
    # we expand the glob against the filesystem. If no matches are found,
    # the rule is dead.
    #
    # The `format_linter` provides the glob expression via `build_glob`,
    # because different ignore formats have different matching semantics
    # (e.g. dockerignore strips slashes, so rooted patterns still match
    # recursively).
    private def check_glob_matches(pat : Pattern, base_dir : String, issues : Array(Issue),
                                   format_linter : FormatLinter) : Nil
      return if pat.literal?

      glob = format_linter.build_glob(pat, base_dir)
      matches = begin
        Dir.glob(glob).reject(&.starts_with?('.'))
      rescue File::BadPatternError
        # If the pattern is invalid as a filesystem glob, skip the check
        # rather than crashing. The structural glob checks will have already
        # flagged it.
        return
      end
      matches = matches.select { |match| Dir.exists?(match) } if pat.directory_only?

      return unless matches.empty?

      label = pat.directory_only? ? "directory" : "file"
      issues << Issue.new(pat.line, "Glob \"#{pat.body}\" matches no #{label}s (dead rule)", :info,
        :dead_glob_rule)
    end

    # -- Helpers -----------------------------------------------------------

    # Check whether the given path is a dockerignore file.
    #
    # Dockerignore has unique semantics: it allows spaces in patterns
    # (they delimit multiple patterns on one line) and strips leading/trailing
    # slashes before matching.
    private def dockerignore?(path : String) : Bool
      basename = File.basename(path)
      basename == ".dockerignore" || basename == "dockerignore" ||
        basename == ".containerignore" || basename == "containerignore"
    end
  end
end
