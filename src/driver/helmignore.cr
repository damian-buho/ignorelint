# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Helmignore-specific linter and the `HelmignoreStyleLinter` adapter.
#
# `.helmignore` is used by Helm charts to exclude files from the chart archive.
# It follows gitignore syntax with one important caveat:
#
#   - **`**` is not documented**: The Helm documentation does not explicitly
#     state that `**` is supported. While the underlying Go `filepath.Match`
#     may handle it in some versions, relying on `**` is risky because the
#     behavior may vary across Helm versions.
#
# The linter warns on `**` usage so users are aware of the ambiguity.
require "../format_linter"
require "./common_glob"
require "./conflicts"

module Ignorelint
  module Checks
    # Semantic checks specific to helmignore files.
    module HelmignoreSemantics
      extend self

      # Check a single pattern for helmignore-specific issues.
      #
      # Checks:
      #   - IG-016: `**` is not documented in `.helmignore` — behavior may
      #     vary across Helm versions. Warn so the user can decide whether to
      #     rely on it.
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        if pat.body.includes?("**")
          issues << Issue.new(pat.line,
            "\"**\" in \"#{pat.raw}\" is not documented in .helmignore — behavior may vary",
            :warn, :doublestar_unsupported)
        end

        issues
      end
    end
  end

  # The linter adapter for helmignore files.
  #
  # Combines:
  #   1. `CommonGlob.check` — shared glob-validity rules
  #   2. `HelmignoreSemantics.check` — undocumented `**` warning
  #   3. `Conflicts.check` — cross-pattern conflict detection
  struct HelmignoreStyleLinter
    include FormatLinter

    # Build the glob for dead-rule detection.
    #
    # Helmignore has no documented `**` support — the `**/` prefix in the
    # glob could produce false negatives if Helm's matcher does not support
    # it. However, for dead-rule detection a false negative (missed dead rule)
    # is less harmful than a false positive (flagging a valid rule), so we
    # use `**/` for unrooted patterns to match as broadly as possible.
    def build_glob(pat : Pattern, base_dir : String) : String
      if pat.rooted?
        File.join(base_dir, pat.body)
      else
        File.join(base_dir, "**", pat.body)
      end
    end

    def check_pattern(pat : Pattern) : Array(Issue)
      issues = Checks::CommonGlob.check(pat)
      issues.concat(Checks::HelmignoreSemantics.check(pat))
      issues
    end

    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
      Checks::Conflicts.check(patterns, issues)
    end
  end
end
