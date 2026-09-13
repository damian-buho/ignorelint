# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# SARIF (Static Analysis Results Interchange Format) output formatter.
#
# Produces SARIF 2.1.0 JSON, the standard format for static analysis tools
# consumed by GitHub Advanced Security, Azure DevOps, and other platforms.
#
# The output structure follows the SARIF specification:
#
#   - `$schema`: points to the official SARIF 2.1.0 JSON schema
#   - `version`: SARIF version (`"2.1.0"`)
#   - `runs[].tool.driver`: describes ignorelint (name, version, rules)
#   - `runs[].results[]`: each lint issue with location, severity, and rule ID
#
# ## Why SARIF?
#
# SARIF is the de-facto standard for integrating static analysis results into
# GitHub code scanning alerts. By supporting SARIF output, ignorelint can
# upload results directly to GitHub's Security tab via
# `github/codeql-action/upload-sarif`.
#
# ## Crystal note: JSON::Builder depth
#
# The SARIF structure is deeply nested. Crystal's `JSON::Builder` handles
# this naturally — each `json.object` and `json.array` block adds a nesting
# level, and the closing brace/bracket is generated automatically when the
# block exits.
require "json"
require "uri"
require "../version"

module Ignorelint
  class SarifFormatter < Formatter
    # Collected results from all processed files. Emitted in `finish`.
    @results = [] of FileResult

    # No-op — the SARIF document is written in `finish`.
    def start(io : IO) : Nil
    end

    # Collect the file result for later emission in `finish`.
    def format_file(result : FileResult, io : IO) : Nil
      @results << result
    end

    # Write the complete SARIF 2.1.0 JSON document to the output stream.
    #
    # The document has two main sections:
    #
    #   1. **rules**: deduplicated list of all rule IDs encountered, each with
    #      a short description derived from the diagnostic code name.
    #
    #   2. **results**: every issue with its location (file URI + line number),
    #      severity level, rule ID, and message.
    #
    # Fixed issues map to level `"note"`; no non-standard `kind` is emitted.
    def finish(io : IO) : Nil
      # First pass: collect unique rules and all result locations.
      # `rules` is a Hash keyed by rule ID — duplicates are automatically
      # merged via the `||=` operator.
      rules = {} of String => {id: String, desc: String}
      locations = [] of {file: String, line: Int32, message: String, severity: Severity, rule_id: String}

      @results.each do |file_result|
        file_result.issues.each do |issue|
          rule_id = issue.code.tag
          rules[rule_id] ||= {id: rule_id, desc: short_desc(issue)}
          locations << {file: file_result.path, line: issue.line, message: issue.message, severity: issue.severity, rule_id: rule_id}
        end
      end

      # Second pass: build the SARIF JSON structure.
      json = JSON::Builder.new(io)
      json.indent = 2
      json.document do
        json.object do
          json.field "$schema", "https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/schemas/sarif-schema-2.1.0.json"
          json.field "version", "2.1.0"
          json.field "runs" do
            json.array do
              json.object do
                # Tool description: name, version, documentation URI, and all rules
                json.field "tool" do
                  json.object do
                    json.field "driver" do
                      json.object do
                        json.field "name", "ignorelint"
                        json.field "version", VERSION
                        json.field "informationUri", "https://github.com/damian-buho/d9t-ignorelint"
                        json.field "rules" do
                          json.array do
                            rules.each_value do |rule|
                              json.object do
                                json.field "id", rule[:id]
                                json.field "shortDescription" do
                                  json.object do
                                    json.field "text", rule[:desc]
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
                # All results (one per issue)
                json.field "results" do
                  json.array do
                    locations.each do |loc|
                      json.object do
                        json.field "ruleId", loc[:rule_id]
                        json.field "level", severity_to_sarif(loc[:severity])
                        json.field "message" do
                          json.object do
                            json.field "text", loc[:message]
                          end
                        end
                        json.field "locations" do
                          json.array do
                            json.object do
                              json.field "physicalLocation" do
                                json.object do
                                  json.field "artifactLocation" do
                                    json.object do
                                      json.field "uri", URI.encode_path(loc[:file])
                                    end
                                  end
                                  json.field "region" do
                                    json.object do
                                      json.field "startLine", loc[:line]
                                    end
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      io << '\n'
    end

    # Stable rule title from the diagnostic code (survives message rewording).
    private def short_desc(issue : Issue) : String
      issue.code.title
    end

    # Map our `Severity` enum to SARIF severity levels.
    #
    # SARIF uses `"error"`, `"warning"`, and `"note"`. Both `Info` and `Fixed`
    # from our Severity map to `"note"`.
    private def severity_to_sarif(severity : Severity) : String
      case severity
      when .error? then "error"
      when .warn?  then "warning"
      when .fixed? then "note"
      else              "note"
      end
    end
  end
end
