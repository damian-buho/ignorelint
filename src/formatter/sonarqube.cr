# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# SonarQube external-issue JSON; `severity` is ours mapped onto the Sonar vocabulary.
require "json"

module Ignorelint
  class SonarqubeFormatter < BatchFormatter
    # The engine id SonarQube attributes every imported issue to.
    ENGINE_ID = "ignorelint"

    # Writes the whole envelope; one entry per issue.
    def finish(io : IO) : Nil
      json = JSON::Builder.new(io)
      json.indent = 2
      json.document do
        json.object do
          json.field "issues" do
            json.array do
              each_issue do |path, issue|
                json.object do
                  json.field "engineId", ENGINE_ID
                  json.field "ruleId", issue.code.tag
                  json.field "severity", severity_to_sonar(issue.severity)
                  json.field "type", issue.severity.error? ? "BUG" : "CODE_SMELL"
                  json.field "primaryLocation" do
                    json.object do
                      json.field "message", strip_control(issue.message)
                      json.field "filePath", path
                      json.field "textRange" do
                        json.object do
                          json.field "startLine", issue.line
                          json.field "endLine", issue.line
                          json.field "startColumn", 0
                          json.field "endColumn", 1
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

    # Maps our severities onto the closed SonarQube vocabulary.
    private def severity_to_sonar(severity : Severity) : String
      case severity
      when .error? then "CRITICAL"
      when .warn?  then "MAJOR"
      when .fixed? then "INFO"
      else              "MINOR"
      end
    end
  end
end
