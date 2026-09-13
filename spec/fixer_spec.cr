# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "../src/fixer"
require "../src/linter"
require "../src/parser"

private def lint_and_collect(content : String, path : String = "test.gitignore")
  result = Ignorelint::Linter.lint(path, content)
  lines = content.lines(chomp: false)
  result.collect_fixes(lines)
end

private def apply(content : String, fixes : Array(Ignorelint::Fix),
                  sort_fix : Ignorelint::Fixer::SortFix?) : String
  Ignorelint::Fixer.apply_fixes(content.lines(chomp: false), fixes, sort_fix)
end

describe Ignorelint::Fixer do
  describe ".fixable?" do
    it "returns true for IG-001 (trailing whitespace)" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::TrailingWhitespace).should be_true
    end

    it "returns true for IG-002 (unescaped hash)" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::UnescapedHash).should be_true
    end

    it "returns true for IG-003 (double negation)" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::DoubleNegation).should be_true
    end

    it "returns true for IG-008 (duplicate rule)" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::DuplicateRule).should be_true
    end

    it "returns true for IG-022 (double slash)" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::DoubleSlash).should be_true
    end

    it "returns true for IG-023 (unsorted rule)" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::UnsortedRule).should be_true
    end

    it "returns true for IG-024 (leading whitespace)" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::LeadingWhitespace).should be_true
    end

    it "returns true for IG-015 (slash no effect)" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::SlashNoEffect).should be_true
    end

    it "returns true for IG-018 (redundant builtin exclude)" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::RedundantBuiltinExclude).should be_true
    end

    it "returns false for non-fixable codes" do
      Ignorelint::Fixer.fixable?(Ignorelint::Code::EmptyPattern).should be_false
      Ignorelint::Fixer.fixable?(Ignorelint::Code::ConsecutiveStar).should be_false
      Ignorelint::Fixer.fixable?(Ignorelint::Code::MalformedBrackets).should be_false
    end
  end

  describe "IG-001: trailing whitespace" do
    it "strips trailing spaces" do
      fixes, sort = lint_and_collect("foo  \n")
      sort.should be_nil
      fixes.size.should eq(1)
      fixes[0].code.should eq(Ignorelint::Code::TrailingWhitespace)
      fixes[0].replacement.should eq("foo")
    end

    it "produces correct output" do
      fixes, sort = lint_and_collect("bar  \n")
      result = apply("bar  \n", fixes, sort)
      result.should eq("bar\n")
    end
  end

  describe "IG-002: unescaped hash" do
    it "escapes # in pattern body" do
      fixes, _ = lint_and_collect("file#name\n")
      fixes.size.should be >= 1
      hash_fix = fixes.find(&.code.unescaped_hash?).as(Ignorelint::Fix)
      hash_fix.replacement.should eq("file\\#name")
    end
  end

  describe "IG-003: double negation" do
    it "removes leading !!" do
      fixes, _ = lint_and_collect("!!foo\n")
      fixes.size.should be >= 1
      dn_fix = fixes.find(&.code.double_negation?).as(Ignorelint::Fix)
      dn_fix.replacement.should eq("foo")
    end
  end

  describe "IG-008: duplicate rule" do
    it "deletes duplicate line" do
      fixes, _ = lint_and_collect("foo\nfoo\n")
      dup_fixes = fixes.select(&.code.duplicate_rule?)
      dup_fixes.size.should eq(1)
      dup_fixes[0].deletion?.should be_true
    end

    it "produces correct output with duplicate removed" do
      fixes, sort = lint_and_collect("foo\nfoo\n")
      result = apply("foo\nfoo\n", fixes, sort)
      result.should eq("foo\n")
    end
  end

  describe "IG-022: double slash" do
    it "collapses // to /" do
      fixes, _ = lint_and_collect("foo//bar\n")
      fixes.size.should be >= 1
      ds_fix = fixes.find(&.code.double_slash?).as(Ignorelint::Fix)
      ds_fix.replacement.should eq("foo/bar")
    end
  end

  describe "IG-024: leading whitespace" do
    it "strips leading spaces" do
      fixes, sort = lint_and_collect(" foo\n")
      sort.should be_nil
      lw_fix = fixes.find(&.code.leading_whitespace?).as(Ignorelint::Fix)
      lw_fix.replacement.should eq("foo")
    end

    it "strips leading tabs" do
      fixes, _ = lint_and_collect("\tfoo\n")
      lw_fix = fixes.find(&.code.leading_whitespace?).as(Ignorelint::Fix)
      lw_fix.replacement.should eq("foo")
    end
  end

  describe "IG-023: unsorted rules" do
    it "produces a sort fix when rules are unsorted" do
      _fixes, sort = lint_and_collect("zoo\nbar\nfoo\n")
      sort.should_not be_nil
      sort.as(Ignorelint::Fixer::SortFix).needed?.should be_true
    end

    it "produces no sort fix when rules are sorted" do
      _fixes, sort = lint_and_collect("bar\nfoo\nzoo\n")
      sort.should be_nil
    end

    it "sorts active lines correctly" do
      content = "zoo\nbar\nfoo\n"
      fixes, sort = lint_and_collect(content)
      result = apply(content, fixes, sort)
      lines = result.split('\n', remove_empty: true)
      lines.should eq(["bar", "foo", "zoo"])
    end

    it "preserves comments and blanks during sorting" do
      content = "# header\nzoo\n\nbar\n"
      fixes, sort = lint_and_collect(content)
      result = apply(content, fixes, sort)
      lines = result.lines(chomp: true)
      lines[0].should eq("# header")
      lines.size.should be >= 4
      sorted_active = lines.reject { |line| line.strip.empty? || line.strip.starts_with?('#') }
      sorted_active.should eq(["bar", "zoo"])
    end

    it "produces no sort fix when a negation is present" do
      _fixes, sort = lint_and_collect("*.log\n!keep.log\n")
      sort.should be_nil
    end

    it "leaves negation order untouched when sorting" do
      content = "zoo\n!keep.log\nbar\n"
      fixes, sort = lint_and_collect(content)
      sort.should be_nil
      result = apply(content, fixes, sort)
      result.should eq(content)
    end
  end

  describe "IG-015: slash no effect (dockerignore)" do
    it "strips leading / from single-segment dockerignore pattern" do
      fixes, _ = lint_and_collect("/build\n", ".dockerignore")
      sn_fix = fixes.find(&.code.slash_no_effect?).as(Ignorelint::Fix)
      sn_fix.replacement.should eq("build")
    end

    it "strips trailing / from single-segment dockerignore pattern" do
      fixes, _ = lint_and_collect("build/\n", ".dockerignore")
      sn_fix = fixes.find(&.code.slash_no_effect?).as(Ignorelint::Fix)
      sn_fix.replacement.should eq("build")
    end

    it "strips both leading and trailing /" do
      fixes, _ = lint_and_collect("/build/\n", ".dockerignore")
      sn_fix = fixes.find(&.code.slash_no_effect?).as(Ignorelint::Fix)
      sn_fix.replacement.should eq("build")
    end
  end

  describe "IG-018: redundant builtin exclude" do
    it "deletes .git from .npmignore" do
      fixes, _ = lint_and_collect(".git\n", ".npmignore")
      rb_fix = fixes.find(&.code.redundant_builtin_exclude?).as(Ignorelint::Fix)
      rb_fix.deletion?.should be_true
    end

    it "deletes node_modules from .prettierignore" do
      fixes, _ = lint_and_collect("node_modules\n", ".prettierignore")
      rb_fix = fixes.find(&.code.redundant_builtin_exclude?).as(Ignorelint::Fix)
      rb_fix.deletion?.should be_true
    end
  end

  describe "apply_fixes: combined fixes" do
    it "fixes trailing whitespace + duplicate + sorts" do
      content = "zoo  \nbar\nzoo\n"
      fixes, sort = lint_and_collect(content)
      result = apply(content, fixes, sort)
      lines = result.split('\n', remove_empty: true)
      lines.size.should eq(2)
      lines.should eq(["bar", "zoo"])
    end

    it "returns original content when no fixes needed" do
      content = "bar\nfoo\n"
      fixes, sort = lint_and_collect(content)
      result = apply(content, fixes, sort)
      result.should eq("bar\nfoo\n")
    end

    it "composes same-line fixes in one pass" do
      content = "foo//bar  \n"
      fixes, sort = lint_and_collect(content)
      result = apply(content, fixes, sort)
      result.should eq("foo/bar\n")
    end

    it "composes leading, trailing and slash fixes in one pass" do
      content = "  foo//bar  \n"
      fixes, sort = lint_and_collect(content)
      result = apply(content, fixes, sort)
      result.should eq("foo/bar\n")
    end

    it "collapses triple slashes fully" do
      content = "a///b\n"
      fixes, sort = lint_and_collect(content)
      result = apply(content, fixes, sort)
      result.should eq("a/b\n")
    end

    it "strips repeated double negations fully" do
      content = "!!!!x\n"
      fixes, sort = lint_and_collect(content)
      result = apply(content, fixes, sort)
      result.should eq("x\n")
    end

    it "preserves CRLF line endings" do
      content = "bar\r\nfoo  \r\n"
      fixes, sort = lint_and_collect(content)
      result = apply(content, fixes, sort)
      result.should eq("bar\r\nfoo\r\n")
    end

    it "is stable when applied twice" do
      content = "  zoo//a  \nbar\n"
      fixes, sort = lint_and_collect(content)
      once = apply(content, fixes, sort)
      fixes2, sort2 = lint_and_collect(once)
      twice = apply(once, fixes2, sort2)
      twice.should eq(once)
    end
  end
end
