# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Dockerignore-specific linter and the `DockerignoreStyleLinter` adapter.
#
# Dockerignore has significantly different semantics from gitignore:
#
#   1. **Slash stripping**: Docker strips leading/trailing `/` before matching,
#      so rooted (`/build`) and directory-only (`build/`) distinctions have no
#      effect. A pattern like `"/build"` matches exactly the same as `"build"`.
#
#   2. **Space delimiting**: Spaces in dockerignore separate multiple patterns
#      on a single line (unlike gitignore where spaces are literal characters).
#
#   3. **Path traversal**: `../` in dockerignore is a security risk — it can
#      reference files outside the build context.
#
#   4. **No `**` nuance**: Dockerignore supports `**` but does not treat it
#      identically to gitignore's `**`.
#
# Because of these differences, the dockerignore linter does NOT delegate to
# `Checks::CommonGlob` for all checks — it handles glob validity directly
# and adds dockerignore-specific semantic checks.
require "../format_linter"
require "./conflicts"

module Ignorelint
  module Checks
    # Semantic checks specific to dockerignore files.
    #
    # These rules catch patterns that exploit dockerignore quirks or indicate
    # a misunderstanding of dockerignore matching behavior.
    module DockerignoreSemantics
      extend self

      # Check a single pattern for dockerignore-specific issues.
      #
      # Checks:
      #   - IG-014: Path traversal (`../`) — security risk, allows accessing
      #     files outside the Docker build context
      #   - IG-015: Leading `/` has no effect — dockerignore strips it
      #   - IG-015: Trailing `/` has no effect — dockerignore strips it
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        # IG-014: Path traversal is a security concern in dockerignore.
        # Patterns like `../../etc/passwd` could leak files outside the
        # build context if Docker's path validation is bypassed.
        if pat.body.includes?("../")
          issues << Issue.new(pat.line, "Path traversal \"#{pat.body}\" in dockerignore", :error,
            :path_traversal)
        end

        # IG-015: Warn on patterns relying on `/` anchoring — dockerignore
        # strips leading/trailing slashes before matching, so rooted and
        # directory-only distinctions have no effect.
        if pat.rooted? && !pat.body.includes?('/')
          issues << Issue.new(pat.line,
            "Leading \"/\" in \"#{pat.raw}\" has no effect — dockerignore strips slashes before matching",
            :info, :slash_no_effect)
        end

        if pat.directory_only? && !pat.body.includes?('/')
          issues << Issue.new(pat.line,
            "Trailing \"/\" in \"#{pat.raw}\" has no effect — dockerignore strips slashes before matching",
            :info, :slash_no_effect)
        end

        issues
      end
    end
  end

  # The linter adapter for dockerignore files.
  #
  # Dockerignore does NOT delegate to `CommonGlob` for all glob checks because
  # its glob semantics differ from gitignore. Instead, it directly checks
  # consecutive asterisks, malformed brackets, and invalid `**` usage, then
  # adds dockerignore-specific semantic checks.
  #
  # Also overrides `build_glob` because dockerignore strips slashes before
  # matching — unrooted and rooted patterns both match recursively.
  struct DockerignoreStyleLinter
    include FormatLinter

    # Override the default glob builder: dockerignore strips leading/trailing
    # slashes before matching, so rooted distinction does not exist — always
    # use `**/` prefix for dead-rule detection.
    #
    # Without this override, a rooted pattern like `/build` would only check
    # for `./build` (missing matches at deeper levels).
    def build_glob(pat : Pattern, base_dir : String) : String
      File.join(base_dir, "**", pat.body)
    end

    # Check a single pattern for dockerignore-specific issues.
    #
    # Performs structural glob checks directly (instead of delegating to
    # `CommonGlob`) because dockerignore has subtly different `**` semantics,
    # then adds dockerignore-specific semantic checks.
    def check_pattern(pat : Pattern) : Array(Issue)
      issues = [] of Issue

      # Structural glob checks still apply (consecutive asterisks, malformed
      # brackets) but NOT gitignore-specific rooted_shallow or invalid_doublestar.
      if pat.consecutive_asterisks?
        issues << Issue.new(pat.line, "Consecutive *** in \"#{pat.body}\"", :error,
          :consecutive_star)
      end

      if pat.malformed_brackets?
        issues << Issue.new(pat.line, "Malformed bracket expression in \"#{pat.body}\"", :error,
          :malformed_brackets)
      end

      if pat.invalid_doublestar?
        issues << Issue.new(pat.line, "Invalid ** usage in \"#{pat.body}\"", :error,
          :invalid_doublestar)
      end

      issues.concat(Checks::DockerignoreSemantics.check(pat))
      issues
    end

    # Check the full pattern list for cross-pattern conflicts.
    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
      Checks::Conflicts.check(patterns, issues)
    end
  end
end
