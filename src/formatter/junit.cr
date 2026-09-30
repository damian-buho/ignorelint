# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# JUnit XML: one testsuite per file, one testcase per issue; fixed findings are `skipped`.
require "xml"

module Ignorelint
  class JunitFormatter < BatchFormatter
    # Writes the whole document; per-file suites carry the counts they need.
    def finish(io : IO) : Nil
      xml = XML::Builder.new(io)
      xml.indent = 0
      xml.document do
        xml.element("testsuites",
          name: "ignorelint",
          tests: issue_count.to_s,
          failures: failing_count.to_s,
          skipped: fixed_count.to_s,
          errors: "0") do
          @results.each do |result|
            write_suite(xml, result)
          end
        end
      end
      io << '\n'
    end

    # One suite per file, omitted when the file is clean.
    private def write_suite(xml : XML::Builder, result : FileResult) : Nil
      return if result.issues.empty?

      xml.element("testsuite",
        name: result.path,
        tests: result.issues.size.to_s,
        failures: result.issues.count { |issue| !issue.severity.fixed? }.to_s) do
        result.issues.each { |issue| write_case(xml, result.path, issue) }
      end
    end

    # One case per issue: a failure, or a skip when autofix already resolved it.
    private def write_case(xml : XML::Builder, path : String, issue : Issue) : Nil
      xml.element("testcase",
        name: "#{issue.code.tag} #{path}:#{issue.line}",
        classname: "ignorelint.#{issue.code.tag}") do
        if issue.severity.fixed?
          xml.element("skipped", message: strip_control(issue.message))
        else
          xml.element("failure",
            type: severity_word(issue.severity),
            message: strip_control(issue.message)) do
            xml.text "#{path}:#{issue.line}: #{issue.code.tag} #{strip_control(issue.message)}"
          end
        end
      end
    end

    # Issues that still describe a problem, i.e. everything not fixed.
    private def failing_count : Int32
      @results.sum { |result| result.issues.count { |issue| !issue.severity.fixed? } }
    end

    # Issues autofix already resolved, reported as skipped cases.
    private def fixed_count : Int32
      @results.sum { |result| result.issues.count(&.severity.fixed?) }
    end
  end
end
