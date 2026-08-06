# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# File-type identification and the global registry of known *ignore files.
#
# This module answers two questions:
#
#   1. "Given a filename like `.dockerignore`, what kind of ignore file is it?"
#   2. "What files should I look for when auto-discovering in a directory?"
#
# The `KNOWN_FILES` hash maps filenames (e.g. `".gitignore"`) to `FileType`
# enum values. Both `CLI.find_ignore_files` and `Linter.lint` consult it.
#
# Each `FileType` value drives format-specific linting via the
# `FormatLinterRegistry` — the linter for `.gitignore` is different from the
# linter for `.dockerignore` because their matching semantics differ.
module Ignorelint
  # Enumerates all recognized *ignore file types.
  #
  # Each value corresponds to a distinct set of lint rules (or reuses the
  # gitignore-style rules). The `FormatLinterRegistry` maps each type to a
  # concrete `FormatLinter` implementation.
  #
  # `Unknown` is the fallback — files whose basename is not in `KNOWN_FILES`
  # get this type and are linted with only universal rules (no format-specific
  # checks).
  enum FileType
    Gitignore
    Dockerignore
    Npmignore
    Claudeignore
    Eslintignore
    Prettierignore
    Stylelintignore
    Yarnignore
    Tfignore
    Containerignore
    Helmignore
    Gcloudignore
    Ebignore
    Slugignore
    Vercelignore
    Cfignore
    OpenapiGeneratorIgnore
    Cursorignore
    Aiderignore
    Aiexclude
    Codeiumignore
    Ignore
    Rgignore
    Fdignore
    Eleventyignore
    Unknown

    # Resolve a file path to its type by looking up the basename in `KNOWN_FILES`.
    #
    # Returns `Unknown` when the filename is not recognized.
    def self.from_path(path : String) : FileType
      KNOWN_FILES[File.basename(path)]? || Unknown
    end
  end

  # Master registry of all recognized *ignore filenames → their `FileType`.
  #
  # Used by:
  # - `CLI.find_ignore_files` to auto-discover files in the current directory
  # - `Ignorelint.file_type_from_path` to determine which format linter to use
  #
  # The type annotation `of String => FileType` tells Crystal this is a
  # `Hash(String, FileType)`, ensuring type safety at compile time.
  KNOWN_FILES = {
    ".gitignore"                => FileType::Gitignore,
    ".dockerignore"             => FileType::Dockerignore,
    ".npmignore"                => FileType::Npmignore,
    ".claudeignore"             => FileType::Claudeignore,
    ".eslintignore"             => FileType::Eslintignore,
    ".prettierignore"           => FileType::Prettierignore,
    ".stylelintignore"          => FileType::Stylelintignore,
    ".yarnignore"               => FileType::Yarnignore,
    ".tfignore"                 => FileType::Tfignore,
    ".containerignore"          => FileType::Containerignore,
    ".helmignore"               => FileType::Helmignore,
    ".gcloudignore"             => FileType::Gcloudignore,
    ".ebignore"                 => FileType::Ebignore,
    ".slugignore"               => FileType::Slugignore,
    ".vercelignore"             => FileType::Vercelignore,
    ".cfignore"                 => FileType::Cfignore,
    ".openapi-generator-ignore" => FileType::OpenapiGeneratorIgnore,
    ".cursorignore"             => FileType::Cursorignore,
    ".aiderignore"              => FileType::Aiderignore,
    ".aiexclude"                => FileType::Aiexclude,
    ".codeiumignore"            => FileType::Codeiumignore,
    ".ignore"                   => FileType::Ignore,
    ".rgignore"                 => FileType::Rgignore,
    ".fdignore"                 => FileType::Fdignore,
    ".eleventyignore"           => FileType::Eleventyignore,
  } of String => FileType

  # Check whether a filename (e.g. `".gitignore"`) is a recognized *ignore file.
  def self.known_file?(name : String) : Bool
    KNOWN_FILES.has_key?(name)
  end

  # Resolve a file path to its `FileType` by looking up the basename.
  #
  # Returns `FileType::Unknown` for unrecognized filenames.
  def self.file_type_from_path(path : String) : FileType
    KNOWN_FILES[File.basename(path)]? || FileType::Unknown
  end
end
