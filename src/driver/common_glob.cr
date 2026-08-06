# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Shared glob-validity checks used by most format linters.
#
# These checks are common to all ignore formats that follow gitignore-style
# glob syntax (i.e., most of them). Dockerignore handles these checks itself
# because it has different `**` semantics.
#
# ## Crystal note: module as a namespace
#
# `Checks::CommonGlob` is a nested module inside `Ignorelint::Checks`. Crystal
# uses `::` for module nesting (similar to Ruby). The `extend self` pattern
# makes all methods callable as `Checks::CommonGlob.check(pat)`.
require "../issue"
require "../pattern"

module Ignorelint
  module Checks
    # Checks that apply to all gitignore-style glob patterns.
    #
    # Currently checks for:
    #   - IG-009: Invalid `**` placement (not between path separators)
    #   - IG-010: Rooted patterns that only match the top level (shallow anchor)
    module CommonGlob
      extend self

      # Run all common glob checks on a single pattern.
      #
      # Returns an array of issues (may be empty). Each format linter calls
      # this as the first step in its `check_pattern` method, then adds
      # format-specific checks on top.
      def check(pat : Pattern) : Array(Issue)
        issues = [] of Issue

        # IG-009: `**` must be a complete path segment on its own.
        # Valid: `a/**/b`, `**/a`, `a/**`
        # Invalid: `a**b`, `a**`, `**a`
        if pat.invalid_doublestar?
          issues << Issue.new(pat.line, "Invalid ** usage in \"#{pat.body}\"", :error,
            :invalid_doublestar)
        end

        # IG-010: Rooted pattern without path separators matches only at top level.
        # Example: `/build` matches `./build` but NOT `./src/build`.
        # The user likely meant `build` (matches at any depth).
        if pat.rooted_shallow?
          issues << Issue.new(pat.line, "Rooted pattern \"#{pat.raw}\" matches top-level only", :warn,
            :rooted_shallow)
        end

        issues
      end
    end
  end
end
