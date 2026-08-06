# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Human-readable terminal output formatter.
#
# Produces colored, line-oriented output suitable for interactive use:
#
#   ```
#   warn:  .gitignore:3 Trailing whitespace in "build  "
#   error: .gitignore:5 Double negation "!!dist" cancels out
#   info:  .gitignore:7 Glob "legacy/**" matches no files (dead rule)
#   ```
#
# Each line has: severity label, file path, line number, code tag, and message.
#
# ## Color support
#
# When stdout is a TTY and `NO_COLOR` is not set, severity labels are colored:
#   - `error:` → red (`\e[31m`)
#   - `warn:`  → orange (`\e[38;5;208m`)
#   - `fixed:` → green (`\e[32m`)
#   - `info:`  — no color (default terminal color)
#
# ## Crystal note: `class` for stateful types
#
# `HumanFormatter` is a `class` (not a `struct`) because it needs per-instance
# state (`@color`). It inherits from the abstract `Formatter` class and must
# implement `start`, `format_file`, and `finish`.
module Ignorelint
  class HumanFormatter < Formatter
    # Width of the severity label column (e.g. "error:" is 6 chars).
    # Used for left-alignment padding so all severity labels line up.
    private SEVERITY_WIDTH = 6

    @color : Bool

    def initialize(@color : Bool)
    end

    # No-op for human output — no header needed before file processing.
    def start(io : IO) : Nil
    end

    # Write each issue as a single line to the output stream.
    #
    # Format: `<severity> <path>:<line> [<code>] <message>`
    #
    # The severity label is left-aligned to `SEVERITY_WIDTH` characters and
    # optionally colored (when `@color` is true).
    def format_file(result : FileResult, io : IO) : Nil
      if result.issues.empty?
        check = @color ? "\e[32m✔\e[0m" : "✔"
        io << check << ' ' << result.path << " is valid\n"
        return
      end

      result.issues.each do |issue|
        label = format_severity(issue.severity)
        io << label << ' ' << result.path << ':' << issue.line << ' ' \
          << '[' << issue.code.tag << "] " << issue.message << '\n'
      end
    end

    # No-op for human output — no footer needed after file processing.
    def finish(io : IO) : Nil
    end

    # Format the severity label with optional ANSI color codes.
    #
    # The label is left-padded to `SEVERITY_WIDTH` so all lines align:
    #
    #   ```
    #   error: .gitignore:5 ...
    #   warn:  .gitignore:3 ...
    #   info:  .gitignore:7 ...
    #   ```
    #
    # ANSI escape sequences:
    #   - `\e[31m` — red (error)
    #   - `\e[38;5;208m` — 256-color orange (warn)
    #   - `\e[32m` — green (fixed)
    #   - `\e[0m` — reset to default color
    private def format_severity(severity : Severity) : String
      tag = case severity
            when .error? then "error:"
            when .warn?  then "warn:"
            when .fixed? then "fixed:"
            else              "info:"
            end

      padded = "%-#{SEVERITY_WIDTH}s" % tag

      if @color
        case severity
        when .error? then "\e[31m#{padded}\e[0m"
        when .warn?  then "\e[38;5;208m#{padded}\e[0m"
        when .fixed? then "\e[32m#{padded}\e[0m"
        else              padded
        end
      else
        padded
      end
    end
  end
end
