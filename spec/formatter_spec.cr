# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "json"
require "xml"
require "./support/golden_fixture"

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

    it "parses gnu" do
      Ignorelint::OutputFormat.parse?("gnu").should eq(Ignorelint::OutputFormat::Gnu)
    end

    it "parses junit" do
      Ignorelint::OutputFormat.parse?("junit").should eq(Ignorelint::OutputFormat::Junit)
    end

    it "parses gitlab_codeclimate" do
      Ignorelint::OutputFormat.parse?("gitlab_codeclimate").should eq(Ignorelint::OutputFormat::GitlabCodeclimate)
    end

    it "parses codacy" do
      Ignorelint::OutputFormat.parse?("codacy").should eq(Ignorelint::OutputFormat::Codacy)
    end

    it "parses sonarqube" do
      Ignorelint::OutputFormat.parse?("sonarqube").should eq(Ignorelint::OutputFormat::Sonarqube)
    end

    it "accepts tty as an alias of human" do
      Ignorelint::OutputFormat.parse?("tty").should eq(Ignorelint::OutputFormat::Human)
      Ignorelint::OutputFormat.parse?("TTY").should eq(Ignorelint::OutputFormat::Human)
    end

    it "lists every format it parses in valid_values" do
      parsed = Ignorelint::OutputFormat.valid_values.split("|")
      %w[human tty gnu json checkstyle junit gitlab_codeclimate codacy sonarqube sarif].each do |name|
        parsed.includes?(name).should be_true
      end
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

  it "strips control characters from hostile input" do
    io = IO::Memory.new
    f = Ignorelint::HumanFormatter.new(false)
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Bad \e[31mred\ninjection", :warn, :trailing_whitespace),
    ]), io)
    f.finish(io)
    output = io.to_s
    output.should_not contain("\e")
    output.should_not contain("\n\n")
    output.should contain("Bad [31mredinjection")
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
    issues[1]["severity"].as_s.should eq("warning")
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

  it "escapes XML special characters" do
    io = IO::Memory.new
    f = Ignorelint::CheckstyleFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Bad <tag> & \"quotes\"", :error),
    ]), io)
    f.finish(io)

    doc = XML.parse(io.to_s)
    errors = doc.xpath_nodes("//file/error")
    errors[0]["message"].should eq("Bad <tag> & \"quotes\"")
  end
end

describe Ignorelint::GnuFormatter do
  it "renders one record per issue" do
    io = IO::Memory.new
    f = Ignorelint::GnuFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(3, "Trailing whitespace in \"build  \"", :warn, :trailing_whitespace),
    ]), io)
    f.finish(io)
    io.to_s.should eq(".gitignore:3: warning: IG-001 Trailing whitespace in \"build  \"\n")
  end

  it "renders every severity" do
    io = IO::Memory.new
    f = Ignorelint::GnuFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "e", :error),
      make_issue(2, "w", :warn),
      make_issue(3, "i", :info),
      make_issue(4, "f", :fixed),
    ]), io)
    f.finish(io)
    io.to_s.should eq(
      ".gitignore:1: error: IG-001 e\n" \
      ".gitignore:2: warning: IG-001 w\n" \
      ".gitignore:3: info: IG-001 i\n" \
      ".gitignore:4: fixed: IG-001 f\n"
    )
  end

  it "prints nothing for a clean file" do
    io = IO::Memory.new
    f = Ignorelint::GnuFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [] of Ignorelint::Issue), io)
    f.finish(io)
    io.to_s.should be_empty
  end

  it "strips control characters so a record stays one line" do
    io = IO::Memory.new
    f = Ignorelint::GnuFormatter.new
    f.start(io)
    f.format_file(make_result(".gitig\nnore", [
      make_issue(1, "bad \e[31mred", :error),
    ]), io)
    f.finish(io)
    output = io.to_s
    output.should_not contain("\e[")
    output.lines.size.should eq(1)
  end
end

describe Ignorelint::JunitFormatter do
  it "emits one suite per file with counts" do
    io = IO::Memory.new
    f = Ignorelint::JunitFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "e", :error),
      make_issue(2, "f", :fixed),
    ]), io)
    f.finish(io)

    doc = XML.parse(io.to_s)
    suites = doc.xpath_nodes("//testsuite")
    suites.size.should eq(1)
    suites[0]["name"].should eq(".gitignore")
    suites[0]["tests"].should eq("2")
    suites[0]["failures"].should eq("1")

    root = doc.xpath_nodes("//testsuites")[0]
    root["skipped"].should eq("1")
    root["errors"].should eq("0")
  end

  it "marks a fixed issue as skipped rather than a failure" do
    io = IO::Memory.new
    f = Ignorelint::JunitFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(2, "Fixed", :fixed, :trailing_whitespace),
    ]), io)
    f.finish(io)

    doc = XML.parse(io.to_s)
    doc.xpath_nodes("//failure").should be_empty
    skipped = doc.xpath_nodes("//skipped")
    skipped.size.should eq(1)
    skipped[0]["message"].should eq("Fixed")
  end

  it "names each case with its rule and location" do
    io = IO::Memory.new
    f = Ignorelint::JunitFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(7, "e", :error, :double_negation),
    ]), io)
    f.finish(io)

    doc = XML.parse(io.to_s)
    kase = doc.xpath_nodes("//testcase")[0]
    kase["name"].should eq("IG-003 .gitignore:7")
    kase["classname"].should eq("ignorelint.IG-003")
    doc.xpath_nodes("//failure")[0]["type"].should eq("error")
  end

  it "escapes XML special characters" do
    io = IO::Memory.new
    f = Ignorelint::JunitFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Bad <tag> & \"quotes\"", :error),
    ]), io)
    f.finish(io)

    doc = XML.parse(io.to_s)
    doc.xpath_nodes("//failure")[0]["message"].should eq("Bad <tag> & \"quotes\"")
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

  it "uses rule titles instead of message fragments" do
    io = IO::Memory.new
    f = Ignorelint::SarifFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Trailing whitespace in \"foo  \"", :warn, :trailing_whitespace),
    ]), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    rules = parsed["runs"].as_a[0]["tool"]["driver"]["rules"].as_a
    rules[0]["shortDescription"]["text"].as_s.should eq("Trailing whitespace")
  end

  it "uri-encodes paths with spaces" do
    io = IO::Memory.new
    f = Ignorelint::SarifFormatter.new
    f.start(io)
    f.format_file(make_result("my dir/.gitignore", [make_issue(1, "err")]), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    loc = parsed["runs"].as_a[0]["results"].as_a[0]["locations"].as_a[0]["physicalLocation"]
    loc["artifactLocation"]["uri"].as_s.should eq("my%20dir/.gitignore")
  end

  it "emits no non-standard kind for fixed issues" do
    io = IO::Memory.new
    f = Ignorelint::SarifFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "Fixed", :fixed, :trailing_whitespace),
    ]), io)
    f.finish(io)

    parsed = JSON.parse(io.to_s)
    result = parsed["runs"].as_a[0]["results"].as_a[0]
    result["level"].as_s.should eq("note")
    result.as_h.has_key?("kind").should be_false
  end
end

describe Ignorelint::GitlabCodeclimateFormatter do
  it "emits the fields GitLab requires" do
    io = IO::Memory.new
    f = Ignorelint::GitlabCodeclimateFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(5, "Double negation \"!!foo\"", :error, :double_negation),
    ]), io)
    f.finish(io)

    issue = JSON.parse(io.to_s).as_a[0]
    issue["type"].as_s.should eq("issue")
    issue["description"].as_s.should eq("Double negation \"!!foo\"")
    issue["check_name"].as_s.should eq("IG-003")
    issue["fingerprint"].as_s.should match(/\A[0-9a-f]{40}\z/)
    issue["location"]["path"].as_s.should eq(".gitignore")
    issue["location"]["lines"]["begin"].as_i.should eq(5)
  end

  it "fingerprints by rule and location, not by wording" do
    render_one = ->(path : String, line : Int32, message : String) do
      io = IO::Memory.new
      f = Ignorelint::GitlabCodeclimateFormatter.new
      f.start(io)
      f.format_file(make_result(path, [make_issue(line, message, :error)]), io)
      f.finish(io)
      JSON.parse(io.to_s).as_a[0]["fingerprint"].as_s
    end

    first = render_one.call(".gitignore", 5, "One wording")
    render_one.call(".gitignore", 5, "Another wording").should eq(first)
    render_one.call(".gitignore", 6, "One wording").should_not eq(first)
    render_one.call(".npmignore", 5, "One wording").should_not eq(first)
  end

  it "maps severity onto the Code Climate vocabulary" do
    io = IO::Memory.new
    f = Ignorelint::GitlabCodeclimateFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "e", :error),
      make_issue(2, "w", :warn),
      make_issue(3, "i", :info),
      make_issue(4, "f", :fixed),
    ]), io)
    f.finish(io)

    issues = JSON.parse(io.to_s).as_a
    issues.map(&.as_h["severity"].as_s).should eq(["critical", "major", "minor", "info"])
  end
end

describe Ignorelint::CodacyFormatter do
  it "keys each issue on its pattern id" do
    io = IO::Memory.new
    f = Ignorelint::CodacyFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(3, "Trailing whitespace in \"build  \"", :warn, :trailing_whitespace),
    ]), io)
    f.finish(io)

    issue = JSON.parse(io.to_s).as_a[0]
    issue["filename"].as_s.should eq(".gitignore")
    issue["patternId"].as_s.should eq("IG-001")
    issue["message"].as_s.should eq("Trailing whitespace in \"build  \"")
    issue["line"].as_i.should eq(3)
  end
end

describe Ignorelint::SonarqubeFormatter do
  it "wraps issues with an engine id and a primary location" do
    io = IO::Memory.new
    f = Ignorelint::SonarqubeFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(5, "Double negation \"!!foo\"", :error, :double_negation),
    ]), io)
    f.finish(io)

    issue = JSON.parse(io.to_s)["issues"].as_a[0]
    issue["engineId"].as_s.should eq("ignorelint")
    issue["ruleId"].as_s.should eq("IG-003")
    issue["severity"].as_s.should eq("CRITICAL")
    issue["type"].as_s.should eq("BUG")
    issue["primaryLocation"]["filePath"].as_s.should eq(".gitignore")
    issue["primaryLocation"]["textRange"]["startLine"].as_i.should eq(5)
  end

  it "maps severity and type onto the SonarQube vocabulary" do
    io = IO::Memory.new
    f = Ignorelint::SonarqubeFormatter.new
    f.start(io)
    f.format_file(make_result(".gitignore", [
      make_issue(1, "e", :error),
      make_issue(2, "w", :warn),
      make_issue(3, "i", :info),
      make_issue(4, "f", :fixed),
    ]), io)
    f.finish(io)

    issues = JSON.parse(io.to_s)["issues"].as_a
    issues.map(&.as_h["severity"].as_s).should eq(["CRITICAL", "MAJOR", "MINOR", "INFO"])
    issues.map(&.as_h["type"].as_s).should eq(["BUG", "CODE_SMELL", "CODE_SMELL", "CODE_SMELL"])
  end
end

describe "golden files" do
  GOLDEN_TARGETS.each do |filename, make_formatter|
    it "matches #{filename} (refresh with `make regen-goldens`)" do
      render_golden(make_formatter.call).should eq(File.read(File.join(GOLDEN_DIR, filename)))
    end
  end
end
