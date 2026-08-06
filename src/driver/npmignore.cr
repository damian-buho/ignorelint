# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# NPMignore-specific linter and the `NpmignoreStyleLinter` adapter.
#
# `.npmignore` follows gitignore syntax but adds built-in exclude/include rules:
#
#   - **Built-in excludes**: certain files are always excluded from npm packages
#     regardless of `.npmignore` content (e.g., `.git`, `node_modules`, `._*`).
#     Listing these in `.npmignore` is redundant.
#
#   - **Built-in includes**: certain files are always included and cannot be
#     excluded (e.g., `package.json`, `README*`, `LICENSE`). A negation pattern
#     trying to re-include one of these is meaningless (it is already included).
#
# These checks help users avoid misleading patterns that appear to do something
# but have no actual effect.
require "../format_linter"
require "./common_glob"
require "./conflicts"

module Ignorelint
  module Checks
    # Semantic checks specific to npmignore files.
    #
    # Detects redundant patterns that duplicate npm's built-in exclude/include
    # behavior.
    module NpmignoreSemantics
      extend self

      # Files/directories always excluded by npm, regardless of `.npmignore`.
      #
      # Users often list these in `.npmignore` thinking they need to, but npm
      # already excludes them. See: https://docs.npmjs.com/cli/v10/commands/npm-pack
      BUILTIN_EXCLUDES = {
        "*.swp",
        "._*",
        ".DS_Store",
        ".git",
        ".hg",
        ".svn",
        "node_modules",
      }

      # Files always included by npm — cannot be excluded even with `.npmignore`.
      #
      # These are required for the package to function. A negation pattern
      # (`!package.json`) is meaningless because the file is already included.
      BUILTIN_INCLUDES = {
        "package.json",
        "README*",
        "CHANGELOG*",
        "LICENSE",
        "LICENCE",
      }

      # Check a single pattern for npmignore-specific issues.
      #
      # Checks:
      #   - IG-018: Pattern duplicates a built-in exclude (redundant)
      #   - IG-019: Negation targets a built-in include (cannot be excluded)
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        if !pat.negated? && matches_builtin_exclude?(pat.body)
          issues << Issue.new(pat.line,
            "\"#{pat.raw}\" is already excluded by default in npm — redundant pattern",
            :info, :redundant_builtin_exclude)
        end

        if pat.negated? && matches_builtin_include?(pat.body)
          issues << Issue.new(pat.line,
            "\"#{pat.raw}\" can never be excluded — built-in include in npm",
            :warn, :builtin_include_protected)
        end

        issues
      end

      # Check if the pattern body matches one of npm's built-in excludes.
      #
      # Handles exact matches and common variations (e.g., `.git` matches
      # both `.git` and `.git/`).
      private def matches_builtin_exclude?(body : String) : Bool
        BUILTIN_EXCLUDES.any? { |builtin| body == builtin || glob_matches?(body, builtin) }
      end

      # Check if the pattern body matches one of npm's built-in includes.
      #
      # Handles glob-style patterns: `"README*"` matches any body starting
      # with `"README"`.
      private def matches_builtin_include?(body : String) : Bool
        BUILTIN_INCLUDES.any? do |builtin|
          if builtin.ends_with?('*')
            body.starts_with?(builtin.rchop('*'))
          else
            body == builtin
          end
        end
      end

      # Simple glob match for patterns like `._*` matching `._*` or `.git` matching `.git/`.
      #
      # This is a limited matcher — it handles the specific built-in patterns
      # npm uses, not a general-purpose glob engine.
      private def glob_matches?(pattern : String, builtin : String) : Bool
        return true if pattern == builtin
        return true if pattern == "#{builtin}/"
        return true if builtin == "._*" && pattern.starts_with?("._") && pattern.size == 3
        false
      end
    end
  end

  # The linter adapter for npmignore files.
  #
  # Combines:
  #   1. `CommonGlob.check` — shared glob-validity rules
  #   2. `GitignoreSemantics.check` — gitignore-specific rules (reused)
  #   3. `NpmignoreSemantics.check` — redundant built-in exclude/include checks
  #   4. `Conflicts.check` — cross-pattern conflict detection
  struct NpmignoreStyleLinter
    include FormatLinter

    def check_pattern(pat : Pattern) : Array(Issue)
      issues = Checks::CommonGlob.check(pat)
      issues.concat(Checks::GitignoreSemantics.check(pat))
      issues.concat(Checks::NpmignoreSemantics.check(pat))
      issues
    end

    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
      Checks::Conflicts.check(patterns, issues)
    end
  end
end
