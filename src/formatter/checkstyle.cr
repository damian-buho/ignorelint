# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Checkstyle XML output formatter.
#
# Produces XML compatible with the Checkstyle format, consumed by CI systems
# and IDE plugins that aggregate lint results from multiple tools:
#
#   ```xml
#   <?xml version="1.0" encoding="UTF-8"?>
#   <checkstyle version="10.12.0">
#     <file name=".gitignore">
#       <error line="3" severity="warning" message="Trailing whitespace" source="ignorelint.IG-001"/>
#     </file>
#   </checkstyle>
#   ```
#
# This is a batch formatter — it collects results during `format_file` and
# emits the complete XML document in `finish`.
#
# ## Crystal note: `@results : Array(FileResult)?`
#
# The instance variable `@results` is declared as a nilable type
# (`Array(FileResult)?` — meaning `Array(FileResult) | Nil`). This is because
# Crystal requires all instance variables to be initialized in the constructor,
# but `CheckstyleFormatter` has no explicit `initialize`. Instead, we use
# `@results ||= [] of FileResult` (lazy initialization) and `@results.not_nil!`
# to tell the compiler the value is definitely not nil after assignment.
#
# ## Crystal note: `XML::Builder`
#
# Crystal's `XML::Builder` provides a streaming XML API. Each `xml.element`
# call writes directly to the underlying `IO`. Block-form elements automatically
# generate opening and closing tags.
require "xml"

module Ignorelint
  class CheckstyleFormatter < Formatter
    # No-op — the XML header is written in `finish`.
    @results = [] of FileResult

    def start(io : IO) : Nil
    end

    def format_file(result : FileResult, io : IO) : Nil
      @results << result
    end

    # Write the complete Checkstyle XML document to the output stream.
    #
    # Groups issues by file, skipping files with no issues. Each issue
    # becomes an `<error>` element with `line`, `severity`, `message`,
    # and `source` attributes.
    def finish(io : IO) : Nil
      results = @results

      xml = XML::Builder.new(io)
      xml.indent = 0
      xml.document do
        xml.element("checkstyle", version: "10.12.0") do
          results.each do |result|
            errors = result.issues
            next if errors.empty?

            xml.element("file", name: result.path) do
              errors.each do |issue|
                xml.element("error",
                  line: issue.line.to_s,
                  severity: severity_to_checkstyle(issue.severity),
                  message: issue.message,
                  source: "ignorelint.#{issue.code.tag}")
              end
            end
          end
        end
      end
      io << '\n'
    end

    # Lazy-initialized collection of file results.
    # Declared nilable because Crystal requires all ivars to have a value
    # after construction, and this class has no explicit `initialize`.
    @results : Array(FileResult)

    # Map our `Severity` enum to Checkstyle severity strings.
    #
    # Checkstyle uses `"error"`, `"warning"`, and `"info"`. Both `Info` and
    # `Fixed` from our Severity map to `"info"` in Checkstyle.
    private def severity_to_checkstyle(severity : Severity) : String
      case severity
      when .error? then "error"
      when .warn?  then "warning"
      when .fixed? then "info"
      else              "info"
      end
    end
  end
end
