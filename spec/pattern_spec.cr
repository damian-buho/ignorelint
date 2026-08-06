# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "../src/pattern"

describe Ignorelint::Pattern do
  describe "classification" do
    it "detects negation" do
      pat = Ignorelint::Pattern.new("!keep.me", 1)
      pat.negated?.should be_true
      pat.body.should eq("keep.me")
    end

    it "detects directory-only" do
      pat = Ignorelint::Pattern.new("build/", 1)
      pat.directory_only?.should be_true
      pat.body.should eq("build")
    end

    it "detects rooted" do
      pat = Ignorelint::Pattern.new("/rooted", 1)
      pat.rooted?.should be_true
      pat.body.should eq("rooted")
    end

    it "detects negated + rooted" do
      pat = Ignorelint::Pattern.new("!/keep", 1)
      pat.negated?.should be_true
      pat.rooted?.should be_true
      pat.negated_rooted?.should be_true
    end

    it "detects blank lines" do
      Ignorelint::Pattern.new("", 1).blank?.should be_true
      Ignorelint::Pattern.new("   ", 1).blank?.should be_true
      Ignorelint::Pattern.new("\t", 1).blank?.should be_true
    end

    it "detects comments" do
      Ignorelint::Pattern.new("# comment", 1).comment?.should be_true
      Ignorelint::Pattern.new("  # indented comment", 1).comment?.should be_true
      Ignorelint::Pattern.new("not#comment", 1).comment?.should be_false
    end

    it "strips escape backslashes in body" do
      pat = Ignorelint::Pattern.new("\\#notacomment", 1)
      pat.comment?.should be_false
      pat.body.should eq("#notacomment")
    end
  end

  describe "trailing whitespace" do
    it "detects trailing spaces" do
      Ignorelint::Pattern.new("foo  ", 1).has_trailing_whitespace?.should be_true
    end

    it "detects trailing tabs" do
      Ignorelint::Pattern.new("foo\t", 1).has_trailing_whitespace?.should be_true
    end

    it "allows escaped trailing space" do
      Ignorelint::Pattern.new("foo\\ ", 1).has_trailing_whitespace?.should be_false
    end
  end

  describe "unescaped hash" do
    it "detects # in middle of pattern" do
      Ignorelint::Pattern.new("file#name", 1).has_unescaped_hash?.should be_true
    end

    it "allows escaped #" do
      Ignorelint::Pattern.new("file\\#name", 1).has_unescaped_hash?.should be_false
    end

    it "allows # at start (comment)" do
      Ignorelint::Pattern.new("#comment", 1).has_unescaped_hash?.should be_false
    end
  end

  describe "double negation" do
    it "detects !!" do
      Ignorelint::Pattern.new("!!foo", 1).double_negation?.should be_true
    end

    it "single ! is not double negation" do
      Ignorelint::Pattern.new("!foo", 1).double_negation?.should be_false
    end
  end

  describe "empty pattern" do
    it "detects bare !" do
      Ignorelint::Pattern.new("!", 1).empty_pattern?.should be_false # negated, not empty
    end

    it "detects lone /" do
      Ignorelint::Pattern.new("/", 1).empty_pattern?.should be_true
    end
  end

  describe "consecutive asterisks" do
    it "detects ***" do
      Ignorelint::Pattern.new("***", 1).consecutive_asterisks?.should be_true
    end

    it "allows **" do
      Ignorelint::Pattern.new("**", 1).consecutive_asterisks?.should be_false
    end

    it "allows *" do
      Ignorelint::Pattern.new("*.log", 1).consecutive_asterisks?.should be_false
    end
  end

  describe "malformed brackets" do
    it "detects unclosed [" do
      Ignorelint::Pattern.new("[abc", 1).malformed_brackets?.should be_true
    end

    it "detects empty []" do
      Ignorelint::Pattern.new("[]", 1).malformed_brackets?.should be_true
    end

    it "detects nested [[ " do
      Ignorelint::Pattern.new("[[a]]", 1).malformed_brackets?.should be_true
    end

    it "allows valid brackets" do
      Ignorelint::Pattern.new("[abc]", 1).malformed_brackets?.should be_false
    end

    it "allows negation brackets" do
      Ignorelint::Pattern.new("[!abc]", 1).malformed_brackets?.should be_false
    end
  end

  describe "invalid doublestar" do
    it "allows **/ prefix" do
      Ignorelint::Pattern.new("**/foo", 1).invalid_doublestar?.should be_false
    end

    it "allows /**/ suffix" do
      Ignorelint::Pattern.new("foo/**", 1).invalid_doublestar?.should be_false
    end

    it "allows /**/ in middle" do
      Ignorelint::Pattern.new("foo/**/bar", 1).invalid_doublestar?.should be_false
    end

    it "rejects a**b (not a full segment)" do
      Ignorelint::Pattern.new("a**b", 1).invalid_doublestar?.should be_true
    end

    it "rejects ** mixed with text" do
      Ignorelint::Pattern.new("**foo", 1).invalid_doublestar?.should be_true
    end
  end

  describe "gitignore-specific" do
    it "detects rooted shallow pattern" do
      Ignorelint::Pattern.new("/build", 1).rooted_shallow?.should be_true
    end

    it "rooted with subdirs is not shallow" do
      Ignorelint::Pattern.new("/src/build/", 1).rooted_shallow?.should be_false
    end

    it "detects negated rooted" do
      Ignorelint::Pattern.new("!/keep", 1).negated_rooted?.should be_true
    end
  end

  describe "conflict detection" do
    it "detects matching ignore/negation pair" do
      pat = Ignorelint::Pattern.new("*.log", 1)
      neg = Ignorelint::Pattern.new("!important.log", 2)
      # These don't conflict because *.log != important.log
      pat.conflicts_with?(neg).should be_false
    end

    it "detects identical ignore/negation pair" do
      pat = Ignorelint::Pattern.new("foo", 1)
      neg = Ignorelint::Pattern.new("!foo", 2)
      pat.conflicts_with?(neg).should be_true
    end
  end

  describe "leading whitespace" do
    it "detects leading spaces" do
      Ignorelint::Pattern.new(" foo", 1).has_leading_whitespace?.should be_true
    end

    it "detects leading tabs" do
      Ignorelint::Pattern.new("\tfoo", 1).has_leading_whitespace?.should be_true
    end

    it "allows no leading whitespace" do
      Ignorelint::Pattern.new("foo", 1).has_leading_whitespace?.should be_false
    end

    it "does not flag comments" do
      Ignorelint::Pattern.new("  # comment", 1).has_leading_whitespace?.should be_false
    end

    it "does not flag blank lines" do
      Ignorelint::Pattern.new("  ", 1).has_leading_whitespace?.should be_false
    end
  end

  describe "double slash" do
    it "detects //" do
      Ignorelint::Pattern.new("foo//bar", 1).has_double_slash?.should be_true
    end

    it "allows single /" do
      Ignorelint::Pattern.new("foo/bar", 1).has_double_slash?.should be_false
    end

    it "does not flag comments" do
      Ignorelint::Pattern.new("# foo//bar", 1).has_double_slash?.should be_false
    end

    it "does not flag blank lines" do
      Ignorelint::Pattern.new("", 1).has_double_slash?.should be_false
    end
  end
end
