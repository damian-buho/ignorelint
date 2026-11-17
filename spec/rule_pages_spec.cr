# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "file_utils"
require "../src/cli"

private def run_rules(args : Array(String)) : {Int32, String, String}
  io = IO::Memory.new
  err = IO::Memory.new
  code = Ignorelint::CLI.new(io, err, IO::Memory.new).main(["--rules"] + args)
  {code, io.to_s, err.to_s}
end

describe Ignorelint::RulePages do
  it "gives every code a severity entry, retired ones empty" do
    Ignorelint::Code.values.each { |code| Ignorelint::RulePages::CODE_SEVERITY_MAP.has_key?(code).should be_true }
    retired = Ignorelint::Code.values.select { |code| Ignorelint::RulePages.retired?(code) }.map(&.tag)
    retired.should eq(["IG-002", "IG-011", "IG-017"])
  end

  it "lists every code once, in order, at org.projectfile.pages.rules.items" do
    items = YAML.parse(Ignorelint::RulePages.catalog)["org"]["projectfile"]["pages"]["rules"]["items"].as_a
    items.map(&.["id"].as_s).should eq(Ignorelint::Code.values.map(&.tag))
    items.first["severity"].as_s.should eq("warn")
    items[1]["retired"].as_bool.should be_true
  end

  it "keeps the first word of a severity that varies by format" do
    items = YAML.parse(Ignorelint::RulePages.catalog)["org"]["projectfile"]["pages"]["rules"]["items"].as_a
    items.find! { |item| item["id"] == "IG-009" }["severity"].as_s.should eq("warn")
  end

  it "says a fixable code fixes with --fix and a retired one is retired" do
    Ignorelint::RulePages.page(Ignorelint::Code::TrailingWhitespace).should contain("| Autofix | yes, with `--fix` |")
    Ignorelint::RulePages.page(Ignorelint::Code::UnescapedHash).should contain("| Status | retired |")
  end

  it "writes a page per code and an index linking each" do
    dir = File.join(Dir.tempdir, "ignorelint-rule-pages-#{Process.pid}")
    begin
      Ignorelint::RulePages.write_all(dir).should eq(Ignorelint::Code.values.size + 1)
      File.read(File.join(dir, "IG-001.md")).should start_with("# IG-001: Trailing whitespace\n")
      File.read(File.join(dir, "index.md")).should contain("| [IG-027](IG-027.md) | Hint |")
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  it "exits 2 on markdown without --output, yaml with --output and an unknown format" do
    [["--format", "markdown"], ["--output", "x"], ["--format", "json"]].each do |args|
      code, _, err = run_rules(args)
      code.should eq(2), "#{args}: #{err}"
    end
  end

  it "prints the catalog with --rules alone" do
    code, out, _ = run_rules([] of String)
    code.should eq(0)
    out.should start_with("org:\n")
  end
end
