# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "json"
require "./fixer"
require "./issue"

module Ignorelint
  # The `rules` page collection: the catalog at `org.projectfile.pages.rules.items` and one Markdown page per code.
  module RulePages
    extend self

    # Default severity as a reader sees it, empty for a retired code.
    CODE_SEVERITY_MAP = {
      Code::TrailingWhitespace      => "warn",
      Code::UnescapedHash           => "",
      Code::DoubleNegation          => "error",
      Code::EmptyPattern            => "error",
      Code::ConsecutiveStar         => "error (warn in `.gitignore`, where git collapses a run of stars)",
      Code::MalformedBrackets       => "error",
      Code::SpaceInPattern          => "warn",
      Code::DuplicateRule           => "warn",
      Code::InvalidDoublestar       => "warn (error in `.dockerignore`, unless the `**` ends the rule)",
      Code::RootedShallow           => "info",
      Code::NegatedRooted           => "",
      Code::RedundantPair           => "warn",
      Code::NegationUnsupported     => "error",
      Code::PathTraversal           => "error",
      Code::SlashNoEffect           => "info",
      Code::DoublestarUnsupported   => "error",
      Code::UnrootedNonRecursive    => "",
      Code::RedundantBuiltinExclude => "info",
      Code::BuiltinIncludeProtected => "warn",
      Code::PathNotFound            => "info",
      Code::DeadGlobRule            => "info",
      Code::DoubleSlash             => "warn",
      Code::UnsortedRule            => "info",
      Code::LeadingWhitespace       => "warn",
      Code::CaseMismatch            => "info",
      Code::SuppressionDirective    => "info",
      Code::Hint                    => "info",
    }

    # What a code reports, beyond its title.
    CODE_MEANING_MAP = {
      Code::UnescapedHash         => "Retired: `#` mid-pattern is literal in every format.",
      Code::RootedShallow         => "Reported only when an unignored entry of that name sits below the root.",
      Code::NegatedRooted         => "Retired: a leading `/` anchors a negation as it anchors any pattern.",
      Code::DoublestarUnsupported => "Helm rejects any `.helmignore` rule containing `**`.",
      Code::InvalidDoublestar     => "A `**` that is not a whole path segment.",
      Code::UnrootedNonRecursive  => "Retired: `.eslintignore` matches unrooted patterns at any depth.",
      Code::PathNotFound          => "Reported only with a clue: a close spelling or a deletion in git history.",
      Code::DeadGlobRule          => "Reported only with a clue: matching files deleted in git history, or a match at another depth.",
      Code::CaseMismatch          => "A literal path that matches nothing exists in another case.",
      Code::SuppressionDirective  => "Lists each `# ignorelint: disable-next-line` directive and the codes it silences.",
      Code::Hint                  => "A file a known pattern names exists but is not ignored.",
    }

    FORMATS = {"yaml", "markdown"}

    # Whether `code` is retired: still reserved, never reported.
    def retired?(code : Code) : Bool
      CODE_SEVERITY_MAP[code].empty?
    end

    # The catalog of every code as a projectfile document in YAML, each list indented under its key.
    def catalog : String
      String.build do |io|
        io << "org:\n  projectfile:\n    pages:\n      rules:\n        items:\n"
        Code.values.each do |code|
          io << "          - id: " << code.tag << "\n"
          io << "            title: " << code.title.to_json << "\n"
          io << "            autofix: " << Fixer.fixable?(code) << "\n"
          if retired?(code)
            io << "            retired: true\n"
          else
            io << "            severity: " << CODE_SEVERITY_MAP[code].split(" ", 2).first << "\n"
          end
        end
      end
    end

    # One code’s page: its title, what it is, then its meaning.
    def page(code : Code) : String
      rows = [{"Code", "`#{code.tag}`"}]
      rows << (retired?(code) ? {"Status", "retired"} : {"Default severity", CODE_SEVERITY_MAP[code]})
      rows << {"Autofix", Fixer.fixable?(code) ? "yes, with `--fix`" : "no"}
      table = (["| | |", "|---|---|"] + rows.map { |(label, value)| "| #{label} | #{value} |" }).join("\n")
      blocks = ["# #{code.tag}: #{code.title}", table]
      if meaning = CODE_MEANING_MAP[code]?
        blocks << meaning
      end
      blocks.join("\n\n") + "\n"
    end

    # Writes `<tag>.md` per code and an `index.md` into `dir`; returns how many pages.
    def write_all(dir : String) : Int32
      Dir.mkdir_p(dir)
      Code.values.each { |code| File.write(File.join(dir, "#{code.tag}.md"), page(code)) }
      rows = Code.values.map do |code|
        severity = retired?(code) ? "retired" : CODE_SEVERITY_MAP[code]
        "| [#{code.tag}](#{code.tag}.md) | #{code.title} | #{severity} | #{Fixer.fixable?(code) ? "✓" : "—"} |"
      end
      index = ["# Rules", "| Code | Title | Default severity | Autofix |\n| --- | --- | --- | --- |\n#{rows.join("\n")}"]
      File.write(File.join(dir, "index.md"), index.join("\n\n") + "\n")
      Code.values.size + 1
    end
  end
end
