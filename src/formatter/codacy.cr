# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Codacy issue JSON keyed on the diagnostic tag in `patternId`; Codacy ranks severity itself.
require "json"

module Ignorelint
  class CodacyFormatter < BatchFormatter
    # Writes the whole array; one entry per issue.
    def finish(io : IO) : Nil
      json = JSON::Builder.new(io)
      json.indent = 2
      json.document do
        json.array do
          each_issue do |path, issue|
            json.object do
              json.field "filename", path
              json.field "patternId", issue.code.tag
              json.field "message", strip_control(issue.message)
              json.field "line", issue.line
            end
          end
        end
      end
      io << '\n'
    end
  end
end
