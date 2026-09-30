# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# GitLab `codequality` Code Climate JSON; `fingerprint` is a SHA1 of rule, path and line.
require "digest/sha1"
require "json"

module Ignorelint
  class GitlabCodeclimateFormatter < BatchFormatter
    # Code Climate accepts this fixed category set; ours is a linter hygiene class.
    CATEGORIES = ["Bug Risk"]

    # Writes the whole array; one entry per issue.
    def finish(io : IO) : Nil
      json = JSON::Builder.new(io)
      json.indent = 2
      json.document do
        json.array do
          each_issue do |path, issue|
            json.object do
              json.field "type", "issue"
              json.field "check_name", issue.code.tag
              json.field "description", strip_control(issue.message)
              json.field "categories", CATEGORIES
              json.field "severity", severity_to_impact(issue.severity)
              json.field "fingerprint", fingerprint(path, issue)
              json.field "location" do
                json.object do
                  json.field "path", path
                  json.field "lines" do
                    json.object do
                      json.field "begin", issue.line
                      json.field "end", issue.line
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

    # Stable identity for one finding: rule plus location, message excluded.
    private def fingerprint(path : String, issue : Issue) : String
      Digest::SHA1.hexdigest("#{issue.code.tag}\n#{path}\n#{issue.line}")
    end

    # Maps our severities onto the closed Code Climate vocabulary.
    private def severity_to_impact(severity : Severity) : String
      case severity
      when .error? then "critical"
      when .warn?  then "major"
      when .fixed? then "info"
      else              "minor"
      end
    end
  end
end
