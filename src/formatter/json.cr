# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# JSON output formatter.
#
# Produces a single JSON document with all issues after all files are processed.
# The output structure is:
#
#   ```json
#   {
#     "version": "1.0",
#     "issues": [
#       {
#         "file": ".gitignore",
#         "line": 3,
#         "severity": "warning",
#         "code": "IG-001",
#         "message": "Trailing whitespace in \"build  \""
#       }
#     ],
#     "total": 1
#   }
#   ```
#
# This is a batch formatter — it collects all `FileResult` values during
# `format_file` and emits the complete JSON in `finish`. This is necessary
# because valid JSON requires a single root object with a closing `}`.
#
# ## Crystal note: `JSON::Builder`
#
# Crystal's `JSON::Builder` provides a streaming JSON API. Each `json.object`
# and `json.field` call writes directly to the underlying `IO`. The
# `json.document` block wraps everything in the JSON document envelope.
# `json.indent = 2` adds pretty-printing.
require "json"

module Ignorelint
  class JsonFormatter < Formatter
    # Collected results from all processed files. Emitted in `finish`.
    @results = [] of FileResult

    # No-op — the JSON header is written in `finish`.
    def start(io : IO) : Nil
    end

    # Collect the file result for later emission in `finish`.
    #
    # Does NOT write to `io` immediately — the complete JSON structure is
    # built in `finish` so the `"total"` count is accurate.
    def format_file(result : FileResult, io : IO) : Nil
      @results << result
    end

    # Convert the severity enum to a JSON string value.
    #
    # Uses `"warning"` (not `"warn"`) to match the checkstyle and SARIF
    # formatters and the SARIF `level` vocabulary.
    private def severity_to_json(severity : Severity) : String
      case severity
      when .error? then "error"
      when .warn?  then "warning"
      when .fixed? then "fixed"
      else              "info"
      end
    end

    # Write the complete JSON document to the output stream.
    #
    # Builds the entire structure at once so the `"total"` field (sum of all
    # issue counts across all files) is accurate.
    def finish(io : IO) : Nil
      json = JSON::Builder.new(io)
      json.indent = 2
      json.document do
        json.object do
          json.field "version", "1.0"
          json.field "issues" do
            json.array do
              @results.each do |result|
                result.issues.each do |issue|
                  json.object do
                    json.field "file", result.path
                    json.field "line", issue.line
                    json.field "severity", severity_to_json(issue.severity)
                    json.field "code", issue.code.tag
                    json.field "message", issue.message
                  end
                end
              end
            end
          end
          # Total count of all issues across all files.
          # `sum(&.issues.size)` is Crystal's shorthand for
          # `results.reduce(0) { |acc, r| acc + r.issues.size }`.
          json.field "total", @results.sum(&.issues.size)
        end
      end
      io << '\n'
    end
  end
end
