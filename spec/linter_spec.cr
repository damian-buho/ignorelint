# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "../src/linter"

describe Ignorelint::Linter do
  # -- Universal rules ----------------------------------------------------

  describe "universal: trailing whitespace" do
    it "reports trailing spaces" do
      result = Ignorelint::Linter.lint("test.gitignore", "foo  \n")
      result.issues.any?(&.message.includes?("Trailing whitespace")).should be_true
    end
  end

  describe "universal: duplicates" do
    it "reports duplicate patterns" do
      result = Ignorelint::Linter.lint("test.gitignore", "*.log\n*.log\n")
      result.issues.any?(&.message.includes?("Duplicate")).should be_true
    end
  end

  describe "universal: double negation" do
    it "reports !!" do
      result = Ignorelint::Linter.lint("test.gitignore", "!!foo\n")
      result.issues.any?(&.message.includes?("Double negation")).should be_true
    end
  end

  describe "universal: empty pattern" do
    it "reports lone /" do
      result = Ignorelint::Linter.lint("test.gitignore", "/\n")
      result.issues.any?(&.message.includes?("Empty pattern")).should be_true
    end

    it "reports bare !" do
      result = Ignorelint::Linter.lint("test.gitignore", "!\n")
      result.issues.any?(&.message.includes?("Empty pattern")).should be_true
    end
  end

  describe "universal: malformed brackets" do
    it "reports unclosed [" do
      result = Ignorelint::Linter.lint("test.gitignore", "[abc\n")
      result.issues.any?(&.message.includes?("Malformed bracket")).should be_true
    end

    it "reports empty []" do
      result = Ignorelint::Linter.lint("test.gitignore", "[]\n")
      result.issues.any?(&.message.includes?("Malformed bracket")).should be_true
    end
  end

  describe "universal: unescaped #" do
    it "reports # in pattern body" do
      result = Ignorelint::Linter.lint("test.gitignore", "file#name\n")
      result.issues.any?(&.message.includes?("Unescaped")).should be_true
    end

    it "allows escaped \\#" do
      result = Ignorelint::Linter.lint("test.gitignore", "file\\#name\n")
      result.issues.any?(&.message.includes?("Unescaped")).should be_false
    end
  end

  describe "universal: comments and blank lines" do
    it "ignores comments" do
      result = Ignorelint::Linter.lint("test.gitignore", "# this is fine\n")
      result.issues.should be_empty
    end

    it "ignores blank lines" do
      result = Ignorelint::Linter.lint("test.gitignore", "\n\n  \n")
      result.issues.should be_empty
    end
  end

  describe "universal: consecutive asterisks" do
    it "reports ***" do
      result = Ignorelint::Linter.lint("test.gitignore", "***\n")
      result.issues.any?(&.message.includes?("Consecutive")).should be_true
    end
  end

  describe "universal: double slash" do
    it "reports //" do
      result = Ignorelint::Linter.lint("test.gitignore", "foo//bar\n")
      result.issues.any?(&.message.includes?("Double slash")).should be_true
    end

    it "allows single /" do
      result = Ignorelint::Linter.lint("test.gitignore", "foo/bar\n")
      result.issues.any?(&.message.includes?("Double slash")).should be_false
    end
  end

  describe "universal: leading whitespace" do
    it "reports leading spaces" do
      result = Ignorelint::Linter.lint("test.gitignore", " foo\n")
      result.issues.any?(&.message.includes?("Leading whitespace")).should be_true
    end

    it "reports leading tabs" do
      result = Ignorelint::Linter.lint("test.gitignore", "\tfoo\n")
      result.issues.any?(&.message.includes?("Leading whitespace")).should be_true
    end

    it "allows patterns without leading whitespace" do
      result = Ignorelint::Linter.lint("test.gitignore", "foo\n")
      result.issues.any?(&.message.includes?("Leading whitespace")).should be_false
    end
  end

  describe "universal: unsorted rules" do
    it "reports unsorted rules" do
      result = Ignorelint::Linter.lint("test.gitignore", "zoo\nbar\nfoo\n")
      result.issues.any?(&.message.includes?("Unsorted")).should be_true
    end

    it "does not report sorted rules" do
      result = Ignorelint::Linter.lint("test.gitignore", "bar\nfoo\nzoo\n")
      result.issues.any?(&.message.includes?("Unsorted")).should be_false
    end

    it "ignores comments and blanks for sorting" do
      content = <<-GITIGNORE
        # header
        bar

        foo
        GITIGNORE
      result = Ignorelint::Linter.lint("test.gitignore", content)
      result.issues.any?(&.message.includes?("Unsorted")).should be_false
    end

    it "skips the sort check when a negation is present" do
      result = Ignorelint::Linter.lint("test.gitignore", "zoo\n!keep.log\nbar\n")
      result.issues.select(&.code.unsorted_rule?).should be_empty
    end
  end

  # -- .gitignore-specific rules ------------------------------------------

  describe "gitignore: negated rooted pattern" do
    it "reports !/ pattern" do
      result = Ignorelint::Linter.lint(".gitignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_true
    end
  end

  describe "gitignore: invalid **" do
    it "reports a**b" do
      result = Ignorelint::Linter.lint(".gitignore", "a**b\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_true
    end

    it "allows foo/**/bar" do
      result = Ignorelint::Linter.lint(".gitignore", "foo/**/bar\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_false
    end
  end

  describe "gitignore: rooted shallow" do
    it "reports /build (no subdirs)" do
      result = Ignorelint::Linter.lint(".gitignore", "/build\n")
      result.issues.any?(&.message.includes?("Rooted pattern")).should be_true
    end

    it "allows /src/build/ (has subdirs)" do
      result = Ignorelint::Linter.lint(".gitignore", "/src/build/\n")
      result.issues.any?(&.message.includes?("Rooted pattern")).should be_false
    end
  end

  describe "gitignore: redundant ignore/negation pair" do
    it "reports immediate cancel pair" do
      result = Ignorelint::Linter.lint(".gitignore", "foo\n!foo\n")
      result.issues.any?(&.message.includes?("Redundant pair")).should be_true
    end

    it "does not flag separated ignore/negation" do
      result = Ignorelint::Linter.lint(".gitignore", "*.log\n!important.log\n")
      result.issues.any?(&.message.includes?("Redundant pair")).should be_false
    end
  end

  # -- Clean file (no issues) ---------------------------------------------

  describe "clean files" do
    it "passes a valid .gitignore" do
      content = <<-GITIGNORE
        *.log
        *.o
        .DS_Store
        Thumbs.db
        build/
        dist/
        node_modules/
        vendor/
        GITIGNORE
      result = Ignorelint::Linter.lint("/nonexistent/.gitignore", content)
      result.issues.should be_empty
    end
  end

  # -- .dockerignore-specific rules ------------------------------------------

  describe "dockerignore: invalid **" do
    it "reports a**b" do
      result = Ignorelint::Linter.lint(".dockerignore", "a**b\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_true
    end

    it "allows foo/**/bar" do
      result = Ignorelint::Linter.lint(".dockerignore", "foo/**/bar\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_false
    end
  end

  describe "dockerignore: rooted shallow" do
    it "does not report Rooted pattern (dockerignore strips slashes)" do
      result = Ignorelint::Linter.lint(".dockerignore", "/build\n")
      result.issues.any?(&.message.includes?("Rooted pattern")).should be_false
    end

    it "reports that leading / has no effect in dockerignore" do
      result = Ignorelint::Linter.lint(".dockerignore", "/build\n")
      result.issues.any?(&.message.includes?("has no effect")).should be_true
    end

    it "reports that trailing / has no effect in dockerignore" do
      result = Ignorelint::Linter.lint(".dockerignore", "build/\n")
      result.issues.any?(&.message.includes?("has no effect")).should be_true
    end

    it "does not report slash warning for multi-segment paths" do
      result = Ignorelint::Linter.lint(".dockerignore", "/src/build/\n")
      result.issues.any?(&.message.includes?("has no effect")).should be_false
    end
  end

  describe "dockerignore: path traversal" do
    it "reports ../ in pattern" do
      result = Ignorelint::Linter.lint(".dockerignore", "../secrets\n")
      result.issues.any?(&.message.includes?("Path traversal")).should be_true
    end

    it "allows normal patterns" do
      result = Ignorelint::Linter.lint(".dockerignore", "secrets\n")
      result.issues.any?(&.message.includes?("Path traversal")).should be_false
    end
  end

  describe "dockerignore: redundant ignore/negation pair" do
    it "reports immediate cancel pair" do
      result = Ignorelint::Linter.lint(".dockerignore", "foo\n!foo\n")
      result.issues.any?(&.message.includes?("Redundant pair")).should be_true
    end

    it "does not flag separated ignore/negation" do
      result = Ignorelint::Linter.lint(".dockerignore", "*.log\n!important.log\n")
      result.issues.any?(&.message.includes?("Redundant pair")).should be_false
    end
  end

  describe "dockerignore: negated rooted" do
    it "does not report !/ pattern (anchoring IS meaningful in dockerignore)" do
      result = Ignorelint::Linter.lint(".dockerignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_false
    end
  end

  describe "dockerignore: clean file" do
    it "passes a valid .dockerignore (no single-segment slash patterns)" do
      content = <<-DOCKERIGNORE
        # Build artifacts
        *.o
        .git
        build
        dist

        # Dependencies
        node_modules
        vendor
        DOCKERIGNORE
      result = Ignorelint::Linter.lint("/nonexistent/.dockerignore", content)
      result.issues.should be_empty
    end
  end

  # -- .npmignore (gitignore-style rules) ------------------------------------

  describe "npmignore: gitignore-style rules" do
    it "reports negated rooted pattern" do
      result = Ignorelint::Linter.lint(".npmignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_true
    end

    it "reports redundant ignore/negation pair" do
      result = Ignorelint::Linter.lint(".npmignore", "foo\n!foo\n")
      result.issues.any?(&.message.includes?("Redundant pair")).should be_true
    end

    it "reports invalid **" do
      result = Ignorelint::Linter.lint(".npmignore", "a**b\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_true
    end

    it "warns on redundant built-in exclude (.git)" do
      result = Ignorelint::Linter.lint(".npmignore", ".git\n")
      result.issues.any?(&.message.includes?("already excluded by default")).should be_true
    end

    it "warns on redundant built-in exclude (node_modules)" do
      result = Ignorelint::Linter.lint(".npmignore", "node_modules\n")
      result.issues.any?(&.message.includes?("already excluded by default")).should be_true
    end

    it "warns on negation of built-in include (package.json)" do
      result = Ignorelint::Linter.lint(".npmignore", "!package.json\n")
      result.issues.any?(&.message.includes?("can never be excluded")).should be_true
    end

    it "warns on negation of built-in include (README*)" do
      result = Ignorelint::Linter.lint(".npmignore", "!README.md\n")
      result.issues.any?(&.message.includes?("can never be excluded")).should be_true
    end

    it "passes a clean file" do
      content = <<-NPMIGNORE
        # Build output
        *.tgz
        build/
        dist/

        # Custom excludes
        secrets/
        NPMIGNORE
      result = Ignorelint::Linter.lint("/nonexistent/.npmignore", content)
      result.issues.should be_empty
    end
  end

  # -- .claudeignore (gitignore-style rules) ---------------------------------

  describe "claudeignore: gitignore-style rules" do
    it "reports negated rooted pattern" do
      result = Ignorelint::Linter.lint(".claudeignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_true
    end

    it "reports redundant ignore/negation pair" do
      result = Ignorelint::Linter.lint(".claudeignore", "foo\n!foo\n")
      result.issues.any?(&.message.includes?("Redundant pair")).should be_true
    end

    it "reports invalid **" do
      result = Ignorelint::Linter.lint(".claudeignore", "a**b\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_true
    end
  end

  # -- .containerignore (dockerignore-style rules) ---------------------------

  describe "containerignore:" do
    it "reports path traversal ../" do
      result = Ignorelint::Linter.lint(".containerignore", "../secrets\n")
      result.issues.any?(&.message.includes?("Path traversal")).should be_true
    end

    it "allows normal patterns" do
      result = Ignorelint::Linter.lint(".containerignore", "secrets\n")
      result.issues.any?(&.message.includes?("Path traversal")).should be_false
    end

    it "does not report negated rooted (anchoring IS meaningful)" do
      result = Ignorelint::Linter.lint(".containerignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_false
    end

    it "clean file" do
      content = <<-CONTAINERIGNORE
        # Build artifacts
        *.o
        .git
        build
        dist

        # Dependencies
        node_modules
        vendor
        CONTAINERIGNORE
      result = Ignorelint::Linter.lint("/nonexistent/.containerignore", content)
      result.issues.should be_empty
    end
  end

  # -- .slugignore (slugignore-style rules) ----------------------------------

  describe "slugignore:" do
    it "reports ! negation" do
      result = Ignorelint::Linter.lint(".slugignore", "!keep\n")
      result.issues.any?(&.message.includes?("Negation not supported")).should be_true
    end

    it "allows normal patterns" do
      result = Ignorelint::Linter.lint(".slugignore", "build/\n")
      result.issues.any?(&.message.includes?("Negation")).should be_false
    end

    it "reports invalid **" do
      result = Ignorelint::Linter.lint(".slugignore", "a**b\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_true
    end

    it "does not report redundant pair (no conflict detection)" do
      result = Ignorelint::Linter.lint(".slugignore", "foo\n!foo\n")
      result.issues.any?(&.message.includes?("Redundant pair")).should be_false
    end

    it "clean file" do
      content = <<-SLUGIGNORE
        # Build artifacts
        *.o
        build/
        dist/

        # Dependencies
        node_modules/
        SLUGIGNORE
      result = Ignorelint::Linter.lint("/nonexistent/.slugignore", content)
      result.issues.should be_empty
    end
  end

  # -- .eslintignore (gitignore-style rules) ---------------------------------

  describe "eslintignore:" do
    it "reports negated rooted pattern" do
      result = Ignorelint::Linter.lint(".eslintignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_true
    end

    it "reports invalid **" do
      result = Ignorelint::Linter.lint(".eslintignore", "a**b\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_true
    end

    it "warns on unrooted pattern (non-recursive in eslintignore)" do
      result = Ignorelint::Linter.lint(".eslintignore", ".config\n")
      result.issues.any?(&.message.includes?("same-directory only")).should be_true
    end

    it "does not warn on rooted pattern" do
      result = Ignorelint::Linter.lint(".eslintignore", "/.config\n")
      result.issues.any?(&.message.includes?("same-directory only")).should be_false
    end

    it "does not warn on pattern with **" do
      result = Ignorelint::Linter.lint(".eslintignore", "**/.config\n")
      result.issues.any?(&.message.includes?("same-directory only")).should be_false
    end

    it "clean file" do
      content = <<-ESLINTIGNORE
        # Build output
        /build/
        /coverage/
        /dist/

        # Dependencies
        /node_modules/
        ESLINTIGNORE
      result = Ignorelint::Linter.lint("/nonexistent/.eslintignore", content)
      result.issues.select(&.code.unsorted_rule?).should be_empty
    end
  end

  # -- .prettierignore (gitignore-style rules) -------------------------------

  describe "prettierignore:" do
    it "reports negated rooted pattern" do
      result = Ignorelint::Linter.lint(".prettierignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_true
    end

    it "reports invalid **" do
      result = Ignorelint::Linter.lint(".prettierignore", "a**b\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_true
    end

    it "warns on redundant built-in exclude (node_modules)" do
      result = Ignorelint::Linter.lint(".prettierignore", "node_modules\n")
      result.issues.any?(&.message.includes?("already excluded by default")).should be_true
    end

    it "warns on redundant built-in exclude (.git)" do
      result = Ignorelint::Linter.lint(".prettierignore", ".git\n")
      result.issues.any?(&.message.includes?("already excluded by default")).should be_true
    end

    it "clean file" do
      content = <<-PRETTIERIGNORE
        # Build output
        build/
        coverage/
        dist/

        # Custom
        generated/
        PRETTIERIGNORE
      result = Ignorelint::Linter.lint("/nonexistent/.prettierignore", content)
      result.issues.should be_empty
    end
  end

  # -- Other gitignore-style formats (batch) ---------------------------------

  describe "other gitignore-style formats" do
    it "applies gitignore rules to .stylelintignore" do
      result = Ignorelint::Linter.lint(".stylelintignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .yarnignore" do
      result = Ignorelint::Linter.lint(".yarnignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies helmignore-specific rules to .helmignore (reports ** as undocumented)" do
      result = Ignorelint::Linter.lint(".helmignore", "foo/**/bar\n")
      result.issues.any?(&.message.includes?("not documented")).should be_true
    end

    it "does not report negated rooted for .helmignore (uses helmignore-specific rules)" do
      result = Ignorelint::Linter.lint(".helmignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_false
    end

    it "applies gitignore rules to .gcloudignore" do
      result = Ignorelint::Linter.lint(".gcloudignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .vercelignore" do
      result = Ignorelint::Linter.lint(".vercelignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies cfignore-specific rules (redundant built-in exclude)" do
      result = Ignorelint::Linter.lint(".cfignore", ".git\n")
      result.issues.any?(&.message.includes?("already excluded by default")).should be_true
    end

    it "applies gitignore rules to .cfignore for basic patterns" do
      result = Ignorelint::Linter.lint(".cfignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .cursorignore" do
      result = Ignorelint::Linter.lint(".cursorignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .aiderignore" do
      result = Ignorelint::Linter.lint(".aiderignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .aiexclude" do
      result = Ignorelint::Linter.lint(".aiexclude", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .codeiumignore" do
      result = Ignorelint::Linter.lint(".codeiumignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .ignore" do
      result = Ignorelint::Linter.lint(".ignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .rgignore" do
      result = Ignorelint::Linter.lint(".rgignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .fdignore" do
      result = Ignorelint::Linter.lint(".fdignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .eleventyignore" do
      result = Ignorelint::Linter.lint(".eleventyignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .tfignore" do
      result = Ignorelint::Linter.lint(".tfignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .ebignore" do
      result = Ignorelint::Linter.lint(".ebignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies gitignore rules to .openapi-generator-ignore" do
      result = Ignorelint::Linter.lint(".openapi-generator-ignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end
  end

  # -- File type detection in lint ----------------------------------------

  describe "file type detection" do
    it "applies gitignore rules to .gitignore" do
      result = Ignorelint::Linter.lint(".gitignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_true
    end

    it "applies dockerignore rules to .dockerignore" do
      result = Ignorelint::Linter.lint(".dockerignore", "a**b\n")
      result.issues.any?(&.message.includes?("Invalid **")).should be_true
    end

    it "does not apply format-specific rules to unknown types" do
      result = Ignorelint::Linter.lint(".unknownfile", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring")).should be_false
    end

    it "does not apply gitignore-only rules to .dockerignore" do
      result = Ignorelint::Linter.lint(".dockerignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_false
    end

    it "applies gitignore-style rules to .npmignore" do
      result = Ignorelint::Linter.lint(".npmignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_true
    end

    it "applies gitignore-style rules to .claudeignore" do
      result = Ignorelint::Linter.lint(".claudeignore", "!/keep\n")
      result.issues.any?(&.message.includes?("anchoring has no effect")).should be_true
    end

    it "applies dockerignore-style rules to .containerignore" do
      result = Ignorelint::Linter.lint(".containerignore", "../secrets\n")
      result.issues.any?(&.message.includes?("Path traversal")).should be_true
    end

    it "applies slugignore-style rules to .slugignore" do
      result = Ignorelint::Linter.lint(".slugignore", "!keep\n")
      result.issues.any?(&.message.includes?("Negation not supported")).should be_true
    end
  end

  # -- Error codes --------------------------------------------------------

  describe "error codes" do
    it "assigns IG-001 to trailing whitespace" do
      result = Ignorelint::Linter.lint("test.gitignore", "foo  \n")
      issue = result.issues.find(&.code.trailing_whitespace?).as(Ignorelint::Issue)
      issue.code.tag.should eq("IG-001")
    end

    it "assigns IG-003 to double negation" do
      result = Ignorelint::Linter.lint("test.gitignore", "!!foo\n")
      issue = result.issues.find(&.code.double_negation?).as(Ignorelint::Issue)
      issue.code.tag.should eq("IG-003")
    end

    it "assigns IG-008 to duplicate rule" do
      result = Ignorelint::Linter.lint("test.gitignore", "*.log\n*.log\n")
      issue = result.issues.find(&.code.duplicate_rule?).as(Ignorelint::Issue)
      issue.code.tag.should eq("IG-008")
    end

    it "assigns IG-011 to negated rooted (gitignore)" do
      result = Ignorelint::Linter.lint(".gitignore", "!/keep\n")
      issue = result.issues.find(&.code.negated_rooted?).as(Ignorelint::Issue)
      issue.code.tag.should eq("IG-011")
    end

    it "assigns IG-014 to path traversal (dockerignore)" do
      result = Ignorelint::Linter.lint(".dockerignore", "../secrets\n")
      issue = result.issues.find(&.code.path_traversal?).as(Ignorelint::Issue)
      issue.code.tag.should eq("IG-014")
    end

    it "assigns IG-022 to double slash" do
      result = Ignorelint::Linter.lint("test.gitignore", "foo//bar\n")
      issue = result.issues.find(&.code.double_slash?).as(Ignorelint::Issue)
      issue.code.tag.should eq("IG-022")
    end

    it "assigns IG-023 to unsorted rule" do
      result = Ignorelint::Linter.lint("test.gitignore", "zoo\nbar\n")
      issue = result.issues.find(&.code.unsorted_rule?).as(Ignorelint::Issue)
      issue.code.tag.should eq("IG-023")
    end

    it "assigns IG-024 to leading whitespace" do
      result = Ignorelint::Linter.lint("test.gitignore", " foo\n")
      issue = result.issues.find(&.code.leading_whitespace?).as(Ignorelint::Issue)
      issue.code.tag.should eq("IG-024")
    end
  end

  # -- Severity levels ----------------------------------------------------

  describe "severity levels" do
    it "assigns error to structural issues" do
      result = Ignorelint::Linter.lint("test.gitignore", "!!foo\n")
      issue = result.issues.find(&.message.includes?("Double negation")).as(Ignorelint::Issue)
      issue.severity.should eq(Ignorelint::Severity::Error)
    end

    it "assigns warning to style issues" do
      result = Ignorelint::Linter.lint("test.gitignore", "foo  \n")
      issue = result.issues.find(&.message.includes?("Trailing whitespace")).as(Ignorelint::Issue)
      issue.severity.should eq(Ignorelint::Severity::Warn)
    end

    it "assigns info to non-existent path checks" do
      result = Ignorelint::Linter.lint("test.gitignore", "nonexistent_dir/\n")
      issue = result.issues.find(&.message.includes?("does not exist")).as(Ignorelint::Issue)
      issue.severity.should eq(Ignorelint::Severity::Info)
    end
  end
end
