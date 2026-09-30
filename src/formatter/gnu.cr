# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# GNU-style line output: one record per issue, `file:line` first, then severity, tag, message.
module Ignorelint
  class GnuFormatter < Formatter
    # No-op — a gnu record needs no header before the first issue.
    def start(io : IO) : Nil
    end

    # Writes one record per issue, in the order the linter reported them.
    def format_file(result : FileResult, io : IO) : Nil
      result.issues.each do |issue|
        io << strip_control(result.path) << ':' << issue.line << ": " \
                                                                  << severity_word(issue.severity) << ": " \
                                                                                                       << issue.code.tag << ' ' << strip_control(issue.message) << '\n'
      end
    end

    # No-op — a gnu record needs no trailer after the last issue.
    def finish(io : IO) : Nil
    end
  end
end
