# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Projectfile-native policy: lint settings from the `org.ignorelint` subtree.
require "json"

module Ignorelint
  # Policy values read from a projectfile document; nil means unset.
  struct PolicySettings
    property fail_on : Severity?
    property format : OutputFormat?
    property fix : Bool?
    property recursive : Bool?
    property verbose : Bool?
    property disabled : Set(String)?

    def initialize(@fail_on = nil, @format = nil, @fix = nil,
                   @recursive = nil, @verbose = nil, @disabled = nil)
    end

    def empty? : Bool
      @fail_on.nil? && @format.nil? && @fix.nil? &&
        @recursive.nil? && @verbose.nil? && @disabled.nil?
    end
  end

  # Reads lint policy by delegating document parsing to pf-cli.
  module ProjectfilePolicy
    # Address of the policy subtree inside the document.
    POLICY_PATH = "org.ignorelint"

    # Candidate filenames for working-directory discovery, in probe order.
    DISCOVER_NAMES = {"projectfile.yaml", "projectfile.toml", "projectfile.json"}

    # First candidate projectfile present in the working directory, if any.
    def self.discover : String?
      DISCOVER_NAMES.each do |name|
        return name if File.file?(name)
      end
      nil
    end

    # Fetches the policy subtree via `pf-cli get -f document org.ignorelint`.
    #
    # Never raises: an absent pf-cli yields an info notice plus empty settings,
    # an absent subtree is silently empty, and an unreadable document returns
    # nil after reporting (exit 2 for explicit files, warning for discovered).
    def self.fetch(document : String, err : IO, explicit : Bool) : PolicySettings?
      fetched = IO::Memory.new
      capture = IO::Memory.new
      status = run_pf_cli(document, fetched, capture)
      if status.nil?
        err << "info: pf-cli not found, skipping projectfile policy\n"
        return PolicySettings.new
      end
      if status.success?
        err << capture.to_s unless capture.empty?
        return extract_json(fetched.to_s, document, err)
      end
      return PolicySettings.new if fetched.to_s.strip == "null"
      report_unusable(document, capture.to_s, err, explicit)
      explicit ? nil : PolicySettings.new
    end

    # Runs pf-cli; nil when the binary is not on PATH.
    private def self.run_pf_cli(document : String, fetched : IO, capture : IO) : Process::Status?
      Process.run("pf-cli", {"get", "-f", document, POLICY_PATH, "--format", "json"},
        output: fetched, error: capture)
    rescue File::NotFoundError
      nil
    end

    # Parses the fetched JSON value into settings.
    private def self.extract_json(raw : String, document : String, err : IO) : PolicySettings
      node = JSON.parse(raw)
      return PolicySettings.new if node.raw.nil?
      unless hash = node.as_h?
        err << "warning: #{document}: ignoring org.ignorelint: expected a mapping\n"
        return PolicySettings.new
      end
      extract(hash, document, err)
    rescue JSON::ParseException
      err << "warning: #{document}: ignoring org.ignorelint: pf-cli returned invalid JSON\n"
      PolicySettings.new
    end

    # Reads known keys out of the subtree; unknown keys warn, bad values are skipped.
    private def self.extract(node : Hash(String, JSON::Any), document : String, err : IO) : PolicySettings
      settings = PolicySettings.new
      node.each do |name, value|
        case name.tr("_", "-")
        when "fail-on"        then settings.fail_on = parse_severity(value, document, err)
        when "format"         then settings.format = parse_format(value, document, err)
        when "fix"            then settings.fix = parse_bool(value, document, err, name)
        when "recursive"      then settings.recursive = parse_bool(value, document, err, name)
        when "verbose"        then settings.verbose = parse_bool(value, document, err, name)
        when "disabled-rules" then settings.disabled = parse_disabled(value, document, err)
        else
          err << "warning: #{document}: unknown ignorelint policy key: #{name}\n"
        end
      end
      settings
    end

    # Maps error|warn|info to Severity; anything else warns and yields nil.
    private def self.parse_severity(value : JSON::Any, document : String, err : IO) : Severity?
      case value.as_s?.try(&.downcase)
      when "error" then Severity::Error
      when "warn"  then Severity::Warn
      when "info"  then Severity::Info
      else
        err << "warning: #{document}: ignoring fail-on value (expected: error|warn|info)\n"
        nil
      end
    end

    # Maps a format name via OutputFormat; unknown names warn and yield nil.
    private def self.parse_format(value : JSON::Any, document : String, err : IO) : OutputFormat?
      parsed = value.as_s?.try { |name| OutputFormat.parse?(name) }
      if parsed.nil?
        err << "warning: #{document}: ignoring format value (expected: #{OutputFormat.valid_values})\n"
      end
      parsed
    end

    # Accepts bools plus common spellings; anything else warns and yields nil.
    private def self.parse_bool(value : JSON::Any, document : String, err : IO, name : String) : Bool?
      raw = value.as_bool?
      return raw unless raw.nil?
      case value.as_s?.try(&.strip.downcase)
      when "1", "true", "yes", "y", "on"  then true
      when "0", "false", "no", "n", "off" then false
      else
        err << "warning: #{document}: ignoring #{name} value (expected a boolean)\n"
        nil
      end
    end

    # Accepts a sequence of tags or one comma/space separated string.
    private def self.parse_disabled(value : JSON::Any, document : String, err : IO) : Set(String)?
      if list = value.as_a?
        tags = list.map { |entry| entry.as_s? || entry.to_s }
        return tags.map(&.strip.upcase).reject(&.empty?).to_set
      end
      if str = value.as_s?
        return str.split(/[\s,]+/).map(&.strip.upcase).reject(&.empty?).to_set
      end
      err << "warning: #{document}: ignoring disabled-rules value (expected a list of tags)\n"
      nil
    end

    # Reports an unreadable document; explicit files fail closed, discovered warn.
    private def self.report_unusable(document : String, detail : String, err : IO, explicit : Bool) : Nil
      if explicit
        err << "error: cannot read policy from #{document}\n"
      else
        err << "warning: ignoring #{document}: policy unreadable\n"
      end
      err << detail unless detail.empty?
    end
  end
end
