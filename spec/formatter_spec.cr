# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "json"
require "xml"
require "../src/formatter"
require "../src/output_format"
require "../src/issue"

private def make_issue(line : Int32, message : String, severity : Ignorelint::Severity = :error,
                       code : Ignorelint::Code = :trailing_whitespace) : Ignorelint::Issue
  Ignorelint::Issue.new(line, message, severity, code)
end

private def make_result(path : String, issues : Array(Ignorelint::Issue)) : Ignorelint::FileResult
  Ignorelint::FileResult.new(path, issues)
end

describe Ignorelint::OutputFormat do
  describe ".parse?" do
    it "parses human" do
      Ignorelint::OutputFormat.parse?("human").should eq(Ignorelint::OutputFormat::Human)
    end

    it "parses json" do
      Ignorelint::OutputFormat.parse?("json").should eq(Ignorelint::OutputFormat::Json)
    end

    it "parses checkstyle" do
      Ignorelint::OutputFormat.parse?("checkstyle").should eq(Ignorelint::OutputFormat::Checkstyle)
    end

    it "parses sarif" do
      Ignorelint::OutputFormat.parse?("sarif").should eq(Ignorelint::OutputFormat::Sarif)
    end

    it "is case-insensitive" do
      Ignorelint::OutputFormat.parse?("JSON").should eq(Ignorelint::OutputFormat::Json)
      Ignorelint::OutputFormat.parse?("SARIF").should eq(Ignorelint::OutputFormat::Sarif)
    end

    it "returns nil for unknown format" do
      Ignorelint::OutputFormat.parse?("xml").should be_nil
    end
  end
end

describe Ignorelint::HumanFormatter do
  it "formats issues with color" do
    io = IO::Memory.new
    f = Ignorelint::HumanFormatter.new(true)
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Trailing whitespace in \"foo  \"", :warn, :trailing_whitespace),
    ]), io)
    f.finish(io)
    output = io.to_s
    output.should contain("warn:")
    output.should contain("[IG-001]")
    output.should contain(".gitignore:1")
    output.should contain("Trailing whitespace")
  end

  it "formats issues without color" do
    io = IO::Memory.new
    f = Ignorelint::HumanFormatter.new(false)
    f.start(io)
    f.format_file(make_result(".gitignore", [make_issue(1, "Double negation \"!!foo\" cancels out", :error)]), io)
    f.finish(io)
    output = io.to_s
    output.should_not contain("\e[")
    output.should contain("error:")
    output.should contain(".gitignore:1")
  end

  it "outputs green check for empty results" do
    io = IO::Memory.new
    f = Ignorelint::HumanFormatter.new(false)
    f.start(io)
    f.format_file(make_result(".gitignore", [] of Ignorelint::Issue), io)
    f.finish(io)
    io.to_s.should eq("✔ .gitignore is valid\n")
  end

  it "formats fixed issues with fixed: tag" do
    io = IO::Memory.new
    f = Ignorelint::HumanFormatter.new(true)
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Double slash in \"foo//bar\"", :fixed, :double_slash),
    ]), io)
    f.finish(io)
    output = io.to_s
    output.should contain("fixed:")
    output.should contain("[IG-022]")
  end

  it "formats fixed issues without color" do
    io = IO::Memory.new
    f = Ignorelint::HumanFormatter.new(false)
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Trailing whitespace fixed", :fixed, :trailing_whitespace),
    ]), io)
    f.finish(io)
    output = io.to_s
    output.should contain("fixed:")
    output.should_not contain("\e[")
  end
end

describe Ignorelint::JsonFormatter do
  it "outputs valid JSON with issues" do
    io = IO::Memory.new
    f = Ignorelint::JsonFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Double negation", :error),
      make_issue(3, "Trailing whitespace", :warn),
    ]), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    parsed["version"].as_s.should eq("1.0")
    parsed["total"].as_i.should eq(2)
    issues = parsed["issues"].as_a
    issues.size.should eq(2)
    issues[0]["file"].as_s.should eq(".gitignore")
    issues[0]["line"].as_i.should eq(1)
    issues[0]["severity"].as_s.should eq("error")
    issues[0]["code"].as_s.should match(/^IG-/)
    issues[1]["severity"].as_s.should eq("warn")
  end

  it "outputs empty issues array for no issues" do
    io = IO::Memory.new
    f = Ignorelint::JsonFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [] of Ignorelint::Issue), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    parsed["total"].as_i.should eq(0)
    parsed["issues"].as_a.should be_empty
  end

  it "aggregates across multiple files" do
    io = IO::Memory.new
    f = Ignorelint::JsonFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [make_issue(1, "err1")]), io)
    f.format_file(make_result(".dockerignore", [make_issue(2, "err2")]), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    parsed["total"].as_i.should eq(2)
    parsed["issues"].as_a.size.should eq(2)
  end

  it "outputs fixed severity" do
    io = IO::Memory.new
    f = Ignorelint::JsonFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Fixed trailing whitespace", :fixed, :trailing_whitespace),
    ]), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    parsed["issues"].as_a[0]["severity"].as_s.should eq("fixed")
  end
end

describe Ignorelint::CheckstyleFormatter do
  it "outputs valid checkstyle XML" do
    io = IO::Memory.new
    f = Ignorelint::CheckstyleFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Double negation", :error),
    ]), io)
    f.finish(io)

    doc = XML.parse(io.to_s)
    files = doc.xpath_nodes("//file")
    files.size.should eq(1)
    files[0]["name"].should eq(".gitignore")

    errors = doc.xpath_nodes("//file/error")
    errors.size.should eq(1)
    errors[0]["line"].should eq("1")
    errors[0]["severity"].should eq("error")
    errors[0]["source"].should match(/^ignorelint\.IG-/)
  end

  it "maps severity levels correctly" do
    io = IO::Memory.new
    f = Ignorelint::CheckstyleFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "warn issue", :warn),
      make_issue(2, "info issue", :info),
    ]), io)
    f.finish(io)

    doc = XML.parse(io.to_s)
    errors = doc.xpath_nodes("//file/error")
    errors[0]["severity"].should eq("warning")
    errors[1]["severity"].should eq("info")
  end

  it "skips files with no issues" do
    io = IO::Memory.new
    f = Ignorelint::CheckstyleFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [] of Ignorelint::Issue), io)
    f.format_file(make_result(".dockerignore", [make_issue(1, "err")]), io)
    f.finish(io)

    doc = XML.parse(io.to_s)
    doc.xpath_nodes("//file").size.should eq(1)
  end
end

describe Ignorelint::SarifFormatter do
  it "outputs valid SARIF JSON" do
    io = IO::Memory.new
    f = Ignorelint::SarifFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Double negation \"!!foo\"", :error, :double_negation),
    ]), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    parsed["$schema"].as_s.should contain("sarif")
    parsed["version"].as_s.should eq("2.1.0")

    runs = parsed["runs"].as_a
    runs.size.should eq(1)

    driver = runs[0]["tool"]["driver"]
    driver["name"].as_s.should eq("ignorelint")

    rules = driver["rules"].as_a
    rules.size.should eq(1)
    rules[0]["id"].as_s.should eq("IG-003")

    results = runs[0]["results"].as_a
    results.size.should eq(1)
    results[0]["ruleId"].as_s.should eq("IG-003")
    results[0]["level"].as_s.should eq("error")
    results[0]["message"]["text"].as_s.should eq("Double negation \"!!foo\"")

    loc = results[0]["locations"].as_a[0]["physicalLocation"]
    loc["artifactLocation"]["uri"].as_s.should eq(".gitignore")
    loc["region"]["startLine"].as_i.should eq(1)
  end

  it "maps severity levels correctly" do
    io = IO::Memory.new
    f = Ignorelint::SarifFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "err", :error),
      make_issue(2, "warn", :warn),
      make_issue(3, "info", :info),
    ]), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    results = parsed["runs"].as_a[0]["results"].as_a
    results[0]["level"].as_s.should eq("error")
    results[1]["level"].as_s.should eq("warning")
    results[2]["level"].as_s.should eq("note")
  end

  it "collects unique rules" do
    io = IO::Memory.new
    f = Ignorelint::SarifFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Trailing whitespace in \"foo  \"", :warn),
      make_issue(2, "Trailing whitespace in \"bar  \"", :warn),
    ]), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    rules = parsed["runs"].as_a[0]["tool"]["driver"]["rules"].as_a
    rules.size.should eq(1)
  end

  it "outputs empty results for no issues" do
    io = IO::Memory.new
    f = Ignorelint::SarifFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [] of Ignorelint::Issue), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    parsed["runs"].as_a[0]["results"].as_a.should be_empty
  end
end
