# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Lints every spec/fixtures/ corpus file: a valid one is quiet above info, a broken one trips the rule it is named after.
require "spec"
require "file_utils"
require "../src/linter"

private FIXTURES_DIR = File.join(__DIR__, "fixtures")

# Codes the dead-rule and sort checks emit for any fixture staged in an empty directory; a broken fixture reports a rule besides these.
private STAGING_CODES = {
  Ignorelint::Code::PathNotFound,
  Ignorelint::Code::DeadGlobRule,
  Ignorelint::Code::UnsortedRule,
}

# Entries a fixture needs on disk, in a git work tree, before its rule can fire.
private STAGED_ENTRIES = {
  "rooted-shallow.gitignore" => ["a/build/x", "a/dist/x", "a/coverage/x"],
}

# The filename a fixture is detected by: its last extension, or the whole name.
private def staged_name(name : String) : String
  ".#{name.rpartition('.')[2]}"
end

# Lints one fixture under its real dotted name in a fresh empty directory.
private def lint_fixture(corpus : String, name : String) : Ignorelint::LintResult
  dir = File.join(Dir.tempdir, "ignorelint-fixtures-#{Process.pid}-#{Random.rand(1_000_000)}")
  Dir.mkdir_p(dir)
  begin
    if entries = STAGED_ENTRIES[name]?
      entries.each do |entry|
        Dir.mkdir_p(File.dirname(File.join(dir, entry)))
        File.write(File.join(dir, entry), "x\n")
      end
      Process.run("git", ["-C", dir, "init", "--quiet"], clear_env: true, env: {"PATH" => ENV["PATH"], "HOME" => dir})
    end
    Ignorelint::Linter.lint(File.join(dir, staged_name(name)),
      File.read(File.join(FIXTURES_DIR, corpus, name)))
  ensure
    FileUtils.rm_rf(dir)
  end
end

# Every fixture file of one corpus, sorted, minus any REUSE sidecar.
private def fixture_names(corpus : String) : Array(String)
  Dir.children(File.join(FIXTURES_DIR, corpus)).sort.reject(&.ends_with?(".license")).select { |name| File.file?(File.join(FIXTURES_DIR, corpus, name)) }
end

private def describe_issue(issue : Ignorelint::Issue) : String
  "line #{issue.line} [#{issue.code}] #{issue.message}"
end

describe "valid fixtures" do
  fixture_names("valid").each do |name|
    it "#{name} reports nothing above info" do
      issues = lint_fixture("valid", name).issues.reject(&.severity.info?)
      issues.map { |issue| "#{name}: #{describe_issue(issue)}" }.should be_empty
    end
  end
end

describe "broken fixtures" do
  fixture_names("broken").each do |name|
    it "#{name} triggers the rule it is named after" do
      issues = lint_fixture("broken", name).issues.reject { |issue| STAGING_CODES.includes?(issue.code) }
      issues.map { |issue| "#{name}: #{describe_issue(issue)}" }.should_not be_empty
    end
  end
end
