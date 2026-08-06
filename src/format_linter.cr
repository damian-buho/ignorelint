# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The adapter layer: `FormatLinter` mixin, `NullFormatLinter`, and the registry.
#
# Different ignore file formats have different semantics:
#
#   - `.gitignore` supports `**`, negation (`!`), and rooted patterns (`/`)
#   - `.dockerignore` strips leading/trailing slashes before matching
#   - `.slugignore` does not support negation at all
#   - `.npmignore` has built-in excludes that make some patterns redundant
#
# The `FormatLinter` mixin defines the interface that each format adapter
# must implement. The `FormatLinterRegistry` maps `FileType` values to
# concrete linter instances, and the `Linter` delegates format-specific
# checks to the appropriate adapter.
#
# ## Crystal note: `include` for mixins
#
# `include FormatLinter` adds the mixin's methods as instance methods on the
# including type. The `abstract` methods in the mixin MUST be implemented by
# the including type (Crystal enforces this at compile time). Non-abstract
# methods like `build_glob` provide a default implementation that can be
# overridden.
#
# ## Crystal note: `require` ordering
#
# The driver `require` statements are at the BOTTOM of this file because each
# driver references types defined above (like `GitignoreStyleLinter`, which
# includes `FormatLinter`). Crystal is single-pass for requires, so the mixin
# must be fully defined before any type includes it.
require "./file_type"
require "./issue"
require "./pattern"

module Ignorelint
  # The mixin interface for format-specific lint rules.
  #
  # Every supported ignore format has a struct that `include FormatLinter`
  # and implements two methods:
  #
  #   - `check_pattern`: inspect a single pattern and return issues
  #   - `check_patterns`: inspect the full pattern list for cross-pattern issues
  #
  # The mixin also provides a default `build_glob` implementation for
  # filesystem dead-rule detection. Dockerignore overrides this because
  # it strips slashes before matching.
  module FormatLinter
    # Check a single pattern for format-specific issues.
    #
    # Returns an array of `Issue` values (empty if the pattern is clean for
    # this format). Called once per active (non-blank, non-comment) pattern.
    abstract def check_pattern(pat : Pattern) : Array(Issue)

    # Check the full pattern list for cross-pattern issues.
    #
    # Used for conflict detection (e.g. `"build"` followed by `"!build"`).
    # Mutates the `issues` array in place for efficiency.
    abstract def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil

    # Build a filesystem glob for dead-rule detection, accounting for
    # format-specific matching semantics (e.g., dockerignore strips slashes).
    #
    # Rooted patterns get a direct path; unrooted patterns get a `**/` prefix
    # because in gitignore semantics they match at any depth.
    def build_glob(pat : Pattern, base_dir : String) : String
      if pat.rooted?
        File.join(base_dir, pat.body)
      else
        File.join(base_dir, "**", pat.body)
      end
    end
  end

  # A no-op linter for unsupported file types.
  #
  # When the file type is `Unknown` (or any type without a registered linter),
  # `FormatLinterRegistry` returns this. All checks pass without producing
  # issues, so only universal rules apply.
  struct NullFormatLinter
    include FormatLinter

    def check_pattern(pat : Pattern) : Array(Issue)
      [] of Issue
    end

    def check_patterns(patterns : Array(Pattern), issues : Array(Issue)) : Nil
    end
  end
end

# Load all format-specific driver implementations.
# Each driver defines a `Checks::*Semantics` module and a `*StyleLinter` struct.
require "./driver/gitignore"
require "./driver/dockerignore"
require "./driver/slugignore"
require "./driver/helmignore"
require "./driver/eslintignore"
require "./driver/npmignore"
require "./driver/cfignore"
require "./driver/prettierignore"

module Ignorelint
  # Registry that maps `FileType` values to their `FormatLinter` instances.
  #
  # This is the bridge between the file-type system and the linting system.
  # When the `Linter` needs format-specific checks, it calls
  # `FormatLinterRegistry.for(file_type)` and gets back the appropriate adapter.
  #
  # Many file types share the `GitignoreStyleLinter` because they follow
  # gitignore semantics (e.g. `.claudeignore`, `.stylelintignore`, `.rgignore`).
  # Only formats with unique semantics get their own linter.
  #
  # The `LINTERS` hash is a private module constant — it is created once at
  # program startup and reused for every file. Each value is a struct instance
  # (no allocation overhead).
  module FormatLinterRegistry
    private LINTERS = {
      FileType::Gitignore              => GitignoreStyleLinter.new,
      FileType::Npmignore              => NpmignoreStyleLinter.new,
      FileType::Claudeignore           => GitignoreStyleLinter.new,
      FileType::Eslintignore           => EslintignoreStyleLinter.new,
      FileType::Prettierignore         => PrettierignoreStyleLinter.new,
      FileType::Stylelintignore        => GitignoreStyleLinter.new,
      FileType::Yarnignore             => GitignoreStyleLinter.new,
      FileType::Tfignore               => GitignoreStyleLinter.new,
      FileType::Helmignore             => HelmignoreStyleLinter.new,
      FileType::Gcloudignore           => GitignoreStyleLinter.new,
      FileType::Ebignore               => GitignoreStyleLinter.new,
      FileType::Vercelignore           => GitignoreStyleLinter.new,
      FileType::Cfignore               => CfignoreStyleLinter.new,
      FileType::OpenapiGeneratorIgnore => GitignoreStyleLinter.new,
      FileType::Cursorignore           => GitignoreStyleLinter.new,
      FileType::Aiderignore            => GitignoreStyleLinter.new,
      FileType::Aiexclude              => GitignoreStyleLinter.new,
      FileType::Codeiumignore          => GitignoreStyleLinter.new,
      FileType::Ignore                 => GitignoreStyleLinter.new,
      FileType::Rgignore               => GitignoreStyleLinter.new,
      FileType::Fdignore               => GitignoreStyleLinter.new,
      FileType::Eleventyignore         => GitignoreStyleLinter.new,
      FileType::Dockerignore           => DockerignoreStyleLinter.new,
      FileType::Containerignore        => DockerignoreStyleLinter.new,
      FileType::Slugignore             => SlugignoreStyleLinter.new,
    } of FileType => FormatLinter

    # Look up the format-specific linter for a given file type.
    #
    # Returns `NullFormatLinter.new` for unrecognized types, so the caller
    # always gets a valid object and never needs to check for nil.
    def self.for(type : FileType) : FormatLinter
      LINTERS[type]? || NullFormatLinter.new
    end
  end
end
