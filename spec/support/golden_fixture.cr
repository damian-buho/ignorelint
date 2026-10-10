# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "../../src/formatter"
require "../../src/output_format"
require "../../src/issue"

def make_issue(line : Int32, message : String, severity : Ignorelint::Severity = :error,
               code : Ignorelint::Code = :trailing_whitespace) : Ignorelint::Issue
  Ignorelint::Issue.new(line, message, severity, code)
end

def make_result(path : String, issues : Array(Ignorelint::Issue)) : Ignorelint::FileResult
  Ignorelint::FileResult.new(path, issues)
end

# Directory holding the committed expected output of each machine format.
GOLDEN_DIR = File.join(__DIR__, "..", "fixtures", "output")

# The fixed multi-issue fixture every output golden file is rendered from.
#
# Three files, three severities, a fixed finding, a clean file and a message with
# XML/JSON metacharacters, so one comparison pins a format's whole contract.
def golden_files : Array(Ignorelint::FileResult)
  [
    make_result(".gitignore", [
      make_issue(1, "Trailing whitespace in \"build  \"", :warn, :trailing_whitespace),
      make_issue(2, "Double negation \"!!keep\" cancels out", :error, :double_negation),
      make_issue(3, "Directory \"node_modules\" does not exist", :info, :path_not_found),
      make_issue(4, "Trailing whitespace fixed", :fixed, :trailing_whitespace),
    ]),
    make_result("sub/.npmignore", [
      make_issue(2, "Bad <tag> & \"quotes\"", :warn, :space_in_pattern),
    ]),
    make_result("clean/.gitignore", [] of Ignorelint::Issue),
  ]
end

# Renders the shared multi-issue fixture through one formatter.
def render_golden(formatter : Ignorelint::Formatter) : String
  io = IO::Memory.new
  formatter.start(io)
  golden_files.each { |result| formatter.format_file(result, io) }
  formatter.finish(io)
  io.to_s
end

# Golden filename to formatter constructor, shared by the spec and the regen script.
GOLDEN_TARGETS = {
  "gnu.txt"                 => -> { Ignorelint::GnuFormatter.new },
  "junit.xml"               => -> { Ignorelint::JunitFormatter.new },
  "gitlab_codeclimate.json" => -> { Ignorelint::GitlabCodeclimateFormatter.new },
  "codacy.json"             => -> { Ignorelint::CodacyFormatter.new },
  "sonarqube.json"          => -> { Ignorelint::SonarqubeFormatter.new },
}
