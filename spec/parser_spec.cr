# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "../src/parser"

describe Ignorelint::Parser do
  it "parses lines into patterns with correct line numbers" do
    patterns = Ignorelint::Parser.parse("*.log\n!important.log\n# comment\n")
    patterns.size.should eq(3)
    patterns[0].line.should eq(1)
    patterns[1].line.should eq(2)
    patterns[2].line.should eq(3)
  end

  it "handles empty content" do
    patterns = Ignorelint::Parser.parse("")
    patterns.should be_empty
  end

  it "handles single line without newline" do
    patterns = Ignorelint::Parser.parse("build/")
    patterns.size.should eq(1)
    patterns[0].directory_only?.should be_true
  end
end
