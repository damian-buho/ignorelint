# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "../src/parser"
require "../src/linter"

describe Ignorelint::Parser do
  it "parses lines into patterns" do
    patterns = Ignorelint::Parser.parse("*.log\n!important.log\n# comment\n")
    patterns.size.should eq(3)
    patterns[0].negated?.should be_false
    patterns[1].negated?.should be_true
    patterns[2].comment?.should be_true
  end

  it "detects directory-only patterns" do
    pat = Ignorelint::Pattern.new("build/", 1)
    pat.directory_only?.should be_true
    pat.body.should eq("build")
  end

  it "detects rooted patterns" do
    pat = Ignorelint::Pattern.new("/rooted", 1)
    pat.rooted?.should be_true
    pat.body.should eq("rooted")
  end

  it "handles negation" do
    pat = Ignorelint::Pattern.new("!keep.me", 1)
    pat.negated?.should be_true
    pat.body.should eq("keep.me")
  end
end

describe Ignorelint::Linter do
  it "reports trailing whitespace" do
    result = Ignorelint::Linter.lint("test.gitignore", "foo  \n")
    result.issues.any?(&.message.includes?("Trailing whitespace")).should be_true
  end

  it "reports duplicate patterns" do
    result = Ignorelint::Linter.lint("test.gitignore", "*.log\n*.log\n")
    result.issues.any?(&.message.includes?("Duplicate")).should be_true
  end

  it "reports double negation" do
    result = Ignorelint::Linter.lint("test.gitignore", "!!foo\n")
    result.issues.any?(&.message.includes?("Double negation")).should be_true
  end

  it "reports consecutive asterisks" do
    result = Ignorelint::Linter.lint("test.gitignore", "***\n")
    result.issues.any?(&.message.includes?("Consecutive")).should be_true
  end

  it "ignores comments and blank lines" do
    result = Ignorelint::Linter.lint("test.gitignore", "# comment\n\n  \n")
    result.issues.should be_empty
  end

  it "reports empty pattern" do
    result = Ignorelint::Linter.lint("test.gitignore", "/\n")
    result.issues.any?(&.message.includes?("Empty pattern")).should be_true
  end

  it "passes clean files" do
    result = Ignorelint::Linter.lint("/nonexistent/.gitignore", "!important.log\n*.log\nbuild/\n")
    result.issues.should be_empty
  end
end
