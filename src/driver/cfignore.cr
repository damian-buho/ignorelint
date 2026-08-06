# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# CFignore-specific linter and the `CfignoreStyleLinter` adapter.
#
# `.cfignore` is used by Cloud Foundry's `cf push` command to exclude files
# from the upload. It follows gitignore syntax with built-in excludes:
#
#   - Certain files are always excluded regardless of `.cfignore` content
#     (e.g., `.git`, `.DS_Store`, `manifest.yml`). Listing these is redundant.
require "../format_linter"
require "./common_glob"
require "./conflicts"

module Ignorelint
  module Checks
    # Semantic checks specific to Cloud Foundry cfignore files.
    module CfignoreSemantics
      extend self

      # Files/directories always excluded by Cloud Foundry, regardless of `.cfignore`.
      #
      # See: https://docs.cloudfoundry.org/devguide/deploy-apps/prepare-to-deploy.html
      BUILTIN_EXCLUDES = {
        ".cfignore",
        "_darcs",
        ".DS_Store",
        ".git",
        ".gitignore",
        ".hg",
        "manifest.yml",
      }

      # Check a single pattern for cfignore-specific issues.
      #
      # Checks:
      #   - IG-018: Pattern duplicates a built-in exclude (redundant)
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        if !pat.negated? && BUILTIN_EXCLUDES.includes?(pat.body) || BUILTIN_EXCLUDES.includes?("#{pat.body}/")
          issues << Issue.new(pat.line,
            "\"#{pat.raw}\" is already excluded by default in Cloud Foundry — redundant pattern",
            :info, :redundant_builtin_exclude)
        end

        issues
      end
    end
  end

  # The linter adapter for Cloud Foundry cfignore files.
  #
  # Combines:
  #   1. `CommonGlob.check` — shared glob-validity rules
  #   2. `GitignoreSemantics.check` — gitignore-specific rules (reused)
  #   3. `CfignoreSemantics.check` — redundant built-in exclude check
  #   4. `Conflicts.check` — cross-pattern conflict detection
  struct CfignoreStyleLinter
    include FormatLinter

    def check_pattern(pat : Pattern) : Array(Issue)
      issues = Checks::CommonGlob.check(pat)
      issues.concat(Checks::GitignoreSemantics.check(pat))
      issues.concat(Checks::CfignoreSemantics.check(pat))
      issues
    end

    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
      Checks::Conflicts.check(patterns, issues)
    end
  end
end
