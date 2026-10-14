# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Pins `FIXABLE_CODES`, the `--fix` help text and the rules table to the same fixable set.
require "spec"
require "../src/cli"
require "../src/fixer"

private RULES_DOC = File.join(__DIR__, "..", "docs", "how-to", "rules.md")

# The rendered option block of `--help`, unwrapped and undecorated.
private def help_text : String
  io = IO::Memory.new
  Ignorelint::CLI.new(io, IO::Memory.new, IO::Memory.new).main(["--help"] of String)
  io.to_s.gsub(/\e\[[\d;]*m/, "").gsub(/\s*\n\s*/, " ")
end

# The codes the rules table marks fixable in its autofix column.
private def documented_fixable : Set(String)
  codes = Set(String).new
  File.read_lines(RULES_DOC).each do |row|
    cells = row.split('|').map(&.strip) # a "| a | b |" row keeps an empty cell at each end
    next if cells.size < 5 || !cells[1].starts_with?("IG-")
    codes << cells[1] if cells[-2].starts_with?("✓")
  end
  codes
end

describe "the fixable rule set" do
  it "is what the --fix help text names" do
    listed = help_text[/Auto-fix deterministically fixable issues \(([^)]*)\)/, 1]
    listed.should_not be_nil
    listed.to_s.split(',').map { |code| code.starts_with?("IG-") ? code : "IG-#{code}" }.to_set
      .should eq(Ignorelint::FIXABLE_CODES.map(&.tag).to_set)
  end

  it "is what the rules table marks fixable" do
    documented_fixable.should eq(Ignorelint::FIXABLE_CODES.map(&.tag).to_set)
  end

  it "is rendered by Fixer.fixable_tags in the sorted help order" do
    Ignorelint::Fixer.fixable_tags.should eq("IG-001,003,008,015,018,022,023,024")
  end
end
