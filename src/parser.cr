# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The `Parser` module: converts raw file content into an array of `Pattern` values.
#
# This is the first stage of the lint pipeline:
#
#   raw file content → `Parser.parse` → `Array(Pattern)` → `Linter.lint`
#
# The parser is deliberately simple — it does not validate or interpret the
# patterns. Each line becomes a `Pattern` struct, and all the semantic analysis
# (is this a comment? is there a trailing space? is this a valid glob?) happens
# inside `Pattern`'s initialization and methods.
#
# ## Crystal note: `extend self`
#
# `extend self` makes every method in the module available as both a module
# method (`Parser.parse(...)`) and a mixin method when the module is included
# in another type. Here we use it purely as a module method — there is no
# need for a class because the parser is stateless.
require "./pattern"

module Ignorelint
  module Parser
    extend self

    # Parse the entire content of an ignore file into individual `Pattern` values.
    #
    # Each line (including blank lines and comments) becomes a `Pattern`.
    # Line numbers are 1-based (matching what editors and error messages show).
    #
    # `content.lines` splits on newlines. `map_with_index` provides both the
    # raw string and its zero-based index; `idx + 1` converts to 1-based.
    def parse(content : String) : Array(Pattern)
      content.lines.map_with_index do |raw, idx|
        Pattern.new(raw, idx + 1)
      end
    end
  end
end
