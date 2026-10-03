# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The CLI: command-line interface, option parsing, and main orchestration loop.
#
# This is the top-level coordinator that ties together all subsystems:
#
#   1. Parse command-line flags (`--format`, `--fail-on`, `--fix`, `--verbose`)
#   2. Load policy from the projectfile subtree via pf-cli, then env overrides (`IGNORELINT_*`)
#   3. Build the appropriate output `Formatter`
#   4. Discover ignore files (or use explicitly provided paths)
#   5. Lint each file via `Linter.lint`
#   6. Optionally auto-fix issues via `Fixer.apply_fixes`
#   7. Format and emit results
#   8. Return the appropriate exit code (0 = clean, 1 = issues found, 2 = usage error)
require "athena-console"

require "./file_type"
require "./fix"
require "./fixer"
require "./formatter"
require "./linter"
require "./output_format"
require "./parser"
require "./projectfile_policy"
require "./version"

module Ignorelint
  # Single-command console application; reports usage errors as `error:` lines with exit 2.
  class Application < ACON::Application
    # Athena raises usage errors with code 0, which would exit as success.
    protected def do_run(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
      super
    rescue ex : ACON::Exception
      raise ex unless ex.code.zero?
      raise ACON::Exception::InvalidArgument.new(ex.message.to_s, code: ACON::Command::Status::INVALID.value)
    end

    # Prints one plain `error:` line plus the synopsis instead of Athena’s banner block.
    protected def render_exception(ex : ::Exception, output : ACON::Output::Interface) : Nil
      output = output.error_output if output.is_a?(ACON::Output::ConsoleOutputInterface)
      output.puts "error: #{ex.message.to_s.strip}", :quiet, :raw
      output.puts "usage: #{get(name).synopsis(short: true)} (see --help)", :quiet, :raw
    end
  end

  # The lint command: one instance per invocation, holding the parsed options as mutable state.
  #
  # Exit codes: `0` clean, `1` issues at or above `--fail-on`, `2` invalid arguments.
  class CLI < ACON::Command
    # Width of the severity label column in human output (e.g. "error:" is 6 chars).
    private SEVERITY_WIDTH = 6

    # Process entry point: runs `args` and exits with the resulting code.
    def self.run(args : Array(String)) : Nil
      code = new.main(args)
      exit(code) if code != 0
    end

    # Output stream for lint results (must stay machine-clean for json output).
    @io : IO

    # Output stream for diagnostics: errors, usage, file-not-found reports.
    @err : IO

    # Piped input read by `--stdin`.
    @input : IO

    # Whether human output is colored, as decided by Athena (`--ansi`, `NO_COLOR`, TTY).
    @color : Bool = false

    # Explicitly provided file paths (from positional CLI arguments).
    @paths = [] of String

    # Minimum severity level that triggers a non-zero exit code.
    # Default: `:error` — only errors cause failure. Use `--fail-on=warn`
    # to fail on warnings too, or `--fail-on=info` to fail on anything.
    # Nil means `none`: findings are reported but never fail the run.
    @fail_on : Severity? = :error

    # True once `--fail-on` was passed explicitly (env must not override it).
    @fail_on_set : Bool = false

    # Whether `--no-fail` was requested; beats every `--fail-on` source.
    @no_fail : Bool = false

    # True once `--no-fail` was passed explicitly (env must not override it).
    @no_fail_set : Bool = false

    # Whether `--plain` was requested (undecorated one-record-per-line human output).
    @plain : Bool = false

    # Whether `--quiet` was requested (issues only, no notices or valid-file lines).
    @quiet : Bool = false

    # Path recorded in machine-readable reports instead of the linted one.
    @report_path : String? = nil

    # Whether `--disable-ignore-pragma` was requested (directives parsed, never applied).
    @no_pragmas : Bool = false

    # True once `--disable-ignore-pragma` was passed explicitly (env and file must not override it).
    @no_pragmas_set : Bool = false

    # Output format selector. Determines which `Formatter` subclass to use.
    @format : OutputFormat = :human

    # True once `--format` was passed explicitly (env and file must not override it).
    @format_set : Bool = false

    # Whether `--fix` was requested (auto-fix deterministically fixable issues).
    @fix : Bool

    # True once `--fix` was passed explicitly (env and file must not override it).
    @fix_set : Bool = false

    # Whether `--diff` was requested (preview fixes without writing).
    @diff : Bool

    # Whether `--stdin` was requested (lint piped content instead of files).
    @stdin : Bool

    # The display filename for `--stdin` mode (drives format detection).
    @stdin_file : String?

    # Disabled rule tags (e.g. IG-001); these issues never surface.
    @disabled : Set(String)

    # True once `--disabled-rules` was passed explicitly (env must not override it).
    @disabled_set : Bool = false

    # Per-code severity set via flags; merged last so flags beat env and file.
    @flag_overrides : Hash(String, Severity)

    # Effective per-code severity after merging file, env, then flags.
    @overrides : Hash(String, Severity)

    # Whether `-v` was requested (show file discovery output).
    @verbose : Bool

    # True once `-v` or `SHELL_VERBOSITY` raised verbosity (the projectfile must not override it).
    @verbose_set : Bool = false

    # Whether to search subdirectories for ignore files (vs cwd only).
    @recursive : Bool

    # True once `--recursive` was passed explicitly (env and file must not override it).
    @recursive_set : Bool = false

    # Explicit projectfile path from `--config` (empty means undiscovered).
    @config_path : String?

    # Streams are injectable so specs can capture them; option defaults resolve in `execute`.
    def initialize(@io : IO = STDOUT, @err : IO = STDERR, @input : IO = STDIN)
      @verbose = false
      @recursive = false
      @fix = false
      @diff = false
      @stdin = false
      @stdin_file = nil
      @config_path = nil
      @disabled = Set(String).new
      @flag_overrides = {} of String => Severity
      @overrides = {} of String => Severity
      super("ignorelint")
    end

    # Runs `args` through a single-command Athena application and returns the exit code.
    def main(args : Array(String)) : Int32
      drop_invalid_shell_verbosity
      app = Application.new("ignorelint", VERSION)
      app.add(self)
      app.default_command(name, true)
      app.auto_exit = false
      output = ACON::Output::ConsoleOutput.new(decorated: ACON::Output::IO.new(@io).decorated?)
      output.io = @io
      output.error_output = ACON::Output::IO.new(@err, decorated: output.decorated?)
      app.run(ACON::Input::ARGV.new(args), output).value
    end

    # Athena crashes on a non-integer SHELL_VERBOSITY, so warn and unset it instead.
    private def drop_invalid_shell_verbosity : Nil
      raw = ENV["SHELL_VERBOSITY"]?
      return if raw.nil? || raw.to_i?
      @err << "warning: ignoring non-integer SHELL_VERBOSITY=" << raw << '\n'
      ENV.delete("SHELL_VERBOSITY")
    end

    protected def configure : Nil
      description("Linter for *ignore files (.gitignore, .dockerignore, .eslintignore, etc.)")
        .argument("paths", :is_array, "Files to lint; none discovers them in the current directory, a lone - reads stdin")
        .option("fail-on", value_mode: :required, description: "Exit non-zero at this severity or worse (error|warn|info|none, default: error)")
        .option("no-fail", description: "Report every finding but always exit 0 (beats --fail-on)")
        .option("plain", description: "Human output as one undecorated path:line [CODE] severity: message record per line")
        .option("file-path-in-report", value_mode: :required, description: "Record this path instead of the linted one in machine-readable reports")
        .option("format", value_mode: :required, description: "Output format (#{OutputFormat.valid_values}, default: human)")
        .option("recursive", "r", description: "Search subdirectories for *ignore files (skips hidden dirs, node_modules, symlinks)")
        .option("fix", description: "Auto-fix deterministically fixable issues (IG-001,002,003,008,015,018,022,023,024)")
        .option("diff", description: "Preview auto-fix changes without writing (cannot combine with --fix)")
        .option("stdin", description: "Lint piped content instead of files (requires --file; a lone - path does the same)")
        .option("file", value_mode: :required, description: "Filename for --stdin input (drives format detection)")
        .option("disabled-rules", value_mode: ACON::Input::Option::Value[:required, :is_array], description: "Skip rules entirely (comma-separated tags, e.g. IG-001,IG-020)")
        .option("error", value_mode: ACON::Input::Option::Value[:required, :is_array], description: "Promote rules to error severity (comma-separated tags, e.g. IG-020)")
        .option("warning", value_mode: ACON::Input::Option::Value[:required, :is_array], description: "Set rules to warning severity (comma-separated tags)")
        .option("info", value_mode: ACON::Input::Option::Value[:required, :is_array], description: "Demote rules to info severity (comma-separated tags; applied last)")
        .option("disable-ignore-pragma", description: "Parse suppression directives but apply none; IG-026 still lists them")
        .option("config", value_mode: :required, description: "Projectfile read via pf-cli for the org.ignorelint policy subtree (default: ./projectfile.*)")
        .help(HELP)
    end

    # Help epilogue: stream contract and environment variables.
    private HELP = <<-TEXT
      When no path is given, discovers supported *ignore files in the current directory.
      Discovery and diagnostics go to stderr; stdout carries only the report.

      Environment variables:
        SHELL_VERBOSITY=1          Same as -v (-1 same as -q)
        IGNORELINT_FAIL_ON=LEVEL   Same as --fail-on (error|warn|info|none)
        IGNORELINT_NOFAIL=1        Same as --no-fail
        IGNORELINT_FORMAT=FORMAT   Same as --format
        IGNORELINT_FIX=1           Same as --fix
        IGNORELINT_RECURSIVE=1     Same as --recursive
        IGNORELINT_DISABLED_RULES=CODES Same as --disabled-rules
        IGNORELINT_OVERRIDE_ERROR=CODES Same as --error
        IGNORELINT_OVERRIDE_WARNING=CODES Same as --warning
        IGNORELINT_OVERRIDE_INFO=CODES Same as --info
        IGNORELINT_CONFIG=PATH     Same as --config
        IGNORELINT_DISABLE_IGNORE_PRAGMA=1 Same as --disable-ignore-pragma
        IGNORELINT_FILE_PATH_IN_REPORT=PATH Same as --file-path-in-report
        NO_COLOR=1                 Disable colored output (also TERM=dumb)
        FORCE_COLOR=1              Color even when piped (--ansi and --no-ansi beat both)
      TEXT

    # Reads the options Athena parsed, then lints with flags beating env beating the projectfile.
    protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
      read_options(input, output)
      ACON::Command::Status.new(lint_all)
    end

    # Lints stdin, the given paths or the discovered files; returns the exit code.
    private def lint_all : Int32
      return 2 unless claim_stdin_dash

      # --fix writes while --diff only previews; combining them is a usage error.
      if @fix && @diff
        @err << "error: --fix and --diff: use one, not both\n"
        return 2
      end

      policy = load_policy
      return 2 if policy.nil?
      apply_file_settings(policy)
      env_code = apply_env_overrides
      return env_code if env_code != 0

      formatter = build_formatter
      if @stdin
        name = stdin_name
        return 2 if name.nil?
        return lint_stdin(@input, formatter, name)
      end
      paths = @paths.empty? ? find_ignore_files : @paths
      exit_code = 0

      # Three-phase formatter lifecycle: start → format each file → finish
      formatter.start(@io)

      paths.each do |path|
        code, result = lint_file(path)
        exit_code |= code # Bitwise OR: any non-zero code makes the final code non-zero
        formatter.format_file(for_report(result, formatter), @io)
      end

      formatter.finish(@io)

      exit_code
    end

    # Turns a lone `-` path into stdin mode; false (after reporting) when mixed with paths.
    private def claim_stdin_dash : Bool
      return true unless @paths.includes?("-")
      if @paths.size > 1
        @err << "error: - (stdin) cannot be combined with PATH arguments\n"
        return false
      end
      @paths.clear
      @stdin = true
    end

    # Resolve lint policy: an explicitly named projectfile, else cwd discovery.
    #
    # Returns nil (after reporting) when an explicitly named file cannot be used.
    # A discovered file is best-effort: problems warn and fall back to defaults.
    private def load_policy : PolicySettings?
      explicit = @config_path
      if explicit.nil?
        explicit = ENV["IGNORELINT_CONFIG"]?
        explicit = nil if explicit.try(&.empty?)
      end
      unless explicit.nil?
        unless File.file?(explicit)
          @err << "error: config file not found: #{explicit}\n"
          return
        end
        return ProjectfilePolicy.fetch(explicit, @err, explicit: true, quiet: @quiet)
      end
      if found = ProjectfilePolicy.discover
        return ProjectfilePolicy.fetch(found, @err, explicit: false, quiet: @quiet)
      end
      PolicySettings.new
    end

    # Apply projectfile-subtree values for options no explicit flag set.
    #
    # Environment overrides these later in `apply_env_overrides`, so the final
    # precedence is flags, then environment, then the projectfile subtree.
    private def apply_file_settings(policy : PolicySettings) : Nil
      adopt_unset(@fail_on_set, policy.fail_on) { |fail_on| @fail_on = fail_on }
      adopt_unset(@fail_on_set, policy.no_fail) { |no_fail| @fail_on = nil if no_fail }
      adopt_unset(@format_set, policy.format) { |format| @format = format }
      adopt_unset(@fix_set, policy.fix) { |fix| @fix = fix }
      adopt_unset(@recursive_set, policy.recursive) { |recursive| @recursive = recursive }
      adopt_unset(@verbose_set, policy.verbose) { |verbose| @verbose = verbose }
      adopt_unset(@no_pragmas_set, policy.disable_ignore_pragma) { |off| @no_pragmas = off }
      adopt_unset(@disabled_set, policy.disabled) { |disabled| @disabled = disabled }
      apply_config_overrides(policy)
    end

    # Assigns a projectfile value to an option no explicit flag claimed.
    private def adopt_unset(was_set : Bool, value : T?, & : T -> Nil) : Nil forall T
      yield value unless was_set || value.nil?
    end

    # Merges the config override buckets; info applied last wins on duplicates.
    private def apply_config_overrides(policy : PolicySettings) : Nil
      if tags = policy.override_error
        tags.each { |tag| @overrides[tag] = Severity::Error }
      end
      if tags = policy.override_warning
        tags.each { |tag| @overrides[tag] = Severity::Warn }
      end
      if tags = policy.override_info
        tags.each { |tag| @overrides[tag] = Severity::Info }
      end
    end

    # Apply environment variable overrides for options not set via CLI flags.
    #
    # Environment variables are lower priority than explicit CLI flags — they
    # only take effect if the flag was not already set. This allows CI systems
    # to set defaults via env vars while still overriding on the command line.
    #
    # Returns 0 on success, 2 when an env value is invalid (reported on stderr).
    private def apply_env_overrides : Int32
      apply_env_switch("IGNORELINT_RECURSIVE", @recursive_set) { |v| @recursive = v }
      apply_env_switch("IGNORELINT_FIX", @fix_set) { |v| @fix = v }
      apply_env_switch("IGNORELINT_NOFAIL", @no_fail_set) { |v| @no_fail = v }
      apply_env_switch("IGNORELINT_DISABLE_IGNORE_PRAGMA", @no_pragmas_set) { |v| @no_pragmas = v }

      if !@format_set && (env_val = ENV["IGNORELINT_FORMAT"]?)
        parsed = OutputFormat.parse?(env_val)
        unless parsed
          @err << "error: invalid IGNORELINT_FORMAT value: #{env_val} (expected: #{OutputFormat.valid_values})\n"
          return 2
        end
        @format = parsed
      end

      if env_val = ENV["IGNORELINT_FAIL_ON"]?
        @fail_on = parse_severity(env_val) unless @fail_on_set
      end

      if env_val = ENV["IGNORELINT_DISABLED_RULES"]?
        @disabled = parse_disabled_rules(env_val) unless @disabled_set
      end
      apply_env_override("IGNORELINT_OVERRIDE_ERROR", Severity::Error)
      apply_env_override("IGNORELINT_OVERRIDE_WARNING", Severity::Warn)
      apply_env_override("IGNORELINT_OVERRIDE_INFO", Severity::Info)
      @report_path ||= ENV["IGNORELINT_FILE_PATH_IN_REPORT"]?.presence
      @verbose = false if @quiet
      @overrides.merge!(@flag_overrides)
      0
    end

    # Applies a boolean env switch unless a flag claimed the option.
    private def apply_env_switch(key : String, was_set : Bool, & : Bool -> Nil) : Nil
      if !was_set && (raw = ENV[key]?)
        yield self.class.env_bool?(raw)
      end
    end

    # Splits comma/space-separated rule tags, normalized for comparison.
    private def parse_disabled_rules(value : String) : Set(String)
      split_tags(value).to_set
    end

    # Splits comma/space-separated tags into normalized upper-case codes.
    private def split_tags(value : String) : Array(String)
      value.split(/[\s,]+/).map(&.strip.upcase).reject(&.empty?)
    end

    # Records one env override bucket; unknown codes warn and match nothing.
    private def apply_env_override(key : String, severity : Severity) : Nil
      raw = ENV[key]?
      return if raw.nil?
      split_tags(raw).each do |tag|
        unless VALID_TAGS.includes?(tag)
          @err << "warning: unknown severity override code: #{tag}\n"
          next
        end
        @overrides[tag] = severity
      end
    end

    # Records one flag override bucket; last mention of a code wins.
    private def assign_flag_override(value : String, severity : Severity) : Nil
      split_tags(value).each do |tag|
        unless VALID_TAGS.includes?(tag)
          @err << "warning: unknown severity override code: #{tag}\n"
          next
        end
        @flag_overrides[tag] = severity
      end
    end

    # Rewrites issue severities from the merged override map.
    private def with_overrides(result : LintResult) : LintResult
      return result if @overrides.empty?
      issues = result.issues.map do |issue|
        if severity = @overrides[issue.code.tag]?
          Issue.new(issue.line, issue.message, severity, issue.code)
        else
          issue
        end
      end
      LintResult.new(issues: issues, patterns: result.patterns)
    end

    # Drops disabled-rule issues; patterns are kept for downstream fixing.
    private def without_disabled(result : LintResult) : LintResult
      return result if @disabled.empty?
      kept = result.issues.reject { |issue| @disabled.includes?(issue.code.tag) }
      LintResult.new(issues: kept, patterns: result.patterns)
    end

    # Copies the options Athena parsed into the CLI state; `_set` marks values env and file must not override.
    private def read_options(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
      @paths = input.argument("paths", Array(String))
      @quiet = output.verbosity.value < 0
      @verbose = @verbose_set = output.verbosity.value > 0
      @color = output.decorated?
      if level = input.option("fail-on")
        @fail_on = parse_severity(level)
        @fail_on_set = true
      end
      @no_fail = @no_fail_set = input.option("no-fail", Bool)
      @plain = input.option("plain", Bool)
      @report_path = input.option("file-path-in-report")
      if value = input.option("format")
        @format = OutputFormat.parse?(value) || raise ACON::Exception::InvalidOption.new("invalid --format value: #{value} (expected: #{OutputFormat.valid_values})")
        @format_set = true
      end
      @recursive = @recursive_set = input.option("recursive", Bool)
      @fix = @fix_set = input.option("fix", Bool)
      @diff = input.option("diff", Bool)
      @stdin = input.option("stdin", Bool)
      @stdin_file = input.option("file")
      input.option("disabled-rules", Array(String)).each { |codes| @disabled.concat(parse_disabled_rules(codes)) }
      @disabled_set = !@disabled.empty?
      input.option("error", Array(String)).each { |codes| assign_flag_override(codes, Severity::Error) }
      input.option("warning", Array(String)).each { |codes| assign_flag_override(codes, Severity::Warn) }
      input.option("info", Array(String)).each { |codes| assign_flag_override(codes, Severity::Info) }
      @no_pragmas = @no_pragmas_set = input.option("disable-ignore-pragma", Bool)
      @config_path = input.option("config")
    end

    # Parses a severity level; an invalid value raises a usage error (exit 2).
    private def parse_severity(value : String) : Severity?
      case value.downcase
      when "error"
        Severity::Error
      when "warn", "warning"
        Severity::Warn
      when "info"
        Severity::Info
      when "none"
        nil
      else
        raise ACON::Exception::InvalidOption.new("invalid --fail-on value: #{value} (expected: error|warn|info|none)")
      end
    end

    # Builds the formatter for the selected output format.
    private def build_formatter : Formatter
      color = @color

      case @format
      when .human?
        HumanFormatter.new(color, @plain, @quiet)
      when .gnu?
        GnuFormatter.new
      when .json?
        JsonFormatter.new
      when .checkstyle?
        CheckstyleFormatter.new
      when .junit?
        JunitFormatter.new
      when .gitlab_codeclimate?
        GitlabCodeclimateFormatter.new
      when .codacy?
        CodacyFormatter.new
      when .sonarqube?
        SonarqubeFormatter.new
      when .sarif?
        SarifFormatter.new
      else
        HumanFormatter.new(color, @plain, @quiet)
      end
    end

    # Swaps in `--file-path-in-report` for every machine-readable format; human output keeps the real path.
    private def for_report(result : FileResult, formatter : Formatter) : FileResult
      path = @report_path
      return result if path.nil? || formatter.is_a?(HumanFormatter)
      FileResult.new(path, result.issues)
    end

    # Validates --stdin usage; reports and returns nil on conflict.
    private def stdin_name : String?
      file = @stdin_file
      if file.nil?
        @err << "error: stdin input (--stdin or -) requires --file=NAME (e.g. --file=.gitignore)\n"
        return
      end
      if !@paths.empty?
        @err << "error: --stdin cannot be combined with PATH arguments\n"
        return
      end
      file
    end

    # Lints piped content under the --file name; discovery is skipped.
    private def lint_stdin(input : IO, formatter : Formatter, name : String) : Int32
      content = read_input(input)
      result = Linter.lint(name, content, honor_pragmas: !@no_pragmas)
      result = without_disabled(result)
      result = with_overrides(result)
      if @fix
        content_lines = content.lines(chomp: false)
        fixes, sort_fix = result.collect_fixes(content_lines)
        @io << Fixer.apply_fixes(content_lines, fixes, sort_fix)
        result = mark_fixed(result, fixes, sort_fix) unless fixes.empty? && sort_fix.nil?
      end
      output = @fix ? @err : @io
      formatter.start(output)
      formatter.format_file(for_report(FileResult.new(name, result.issues), formatter), output)
      formatter.finish(output)
      should_fail?(result) ? 1 : 0
    end

    # Reads piped input fully; the parameter is a seam for specs.
    private def read_input(input : IO) : String
      input.gets_to_end
    end

    # Lint a single file and optionally auto-fix issues.
    #
    # Returns a tuple of `{exit_code, FileResult}`:
    #   - `exit_code`: 1 if issues at or above `@fail_on` severity, 0 otherwise
    #   - `FileResult`: the path and all issues found (including fixed ones)
    #
    # When `--fix` is active:
    #   1. Read the file content and split into lines
    #   2. Collect all applicable fixes from the lint result
    #   3. Apply fixes and write the new content back to disk
    #   4. Re-label fixed issues with severity `:fixed`
    private def lint_file(path : String) : {Int32, FileResult}
      if Dir.exists?(path)
        @err << "error: " << path << ": is a directory\n"
        return {1, FileResult.new(path, [] of Issue)}
      end

      unless File.file?(path)
        @err << "error: " << path << ": file not found\n"
        return {1, FileResult.new(path, [] of Issue)}
      end

      content = File.read(path)
      result = Linter.lint(path, content, honor_pragmas: !@no_pragmas)
      result = without_disabled(result)
      result = with_overrides(result)
      result = handle_fixes(path, content, result) if @fix || @diff

      {should_fail?(result) ? 1 : 0, FileResult.new(path, result.issues)}
    rescue ex : Exception
      # Catch-all for unexpected errors (permission denied, encoding issues, etc.)
      @err << "error: " << path << ": " << ex.message << '\n'
      {1, FileResult.new(path, [] of Issue)}
    end

    # Collects fixes once; writes them with --fix, previews them with --diff.
    private def handle_fixes(path : String, content : String, result : LintResult) : LintResult
      # Never rewrite through a symlink (target may live outside the repo).
      if @fix && File.symlink?(path)
        @err << "error: " << path << ": refusing --fix on symlink\n"
        return result
      end
      content_lines = content.lines(chomp: false)
      fixes, sort_fix = result.collect_fixes(content_lines)
      return result if fixes.empty? && sort_fix.nil?
      if @diff
        print_diff_preview(path, fixes, sort_fix)
        result
      else
        new_content = Fixer.apply_fixes(content_lines, fixes, sort_fix)
        atomic_write(path, new_content)
        mark_fixed(result, fixes, sort_fix)
      end
    end

    # Prints collected fixes as a reviewable listing; writes nothing.
    private def print_diff_preview(path : String, fixes : Array(Fix), sort_fix : Fixer::SortFix?) : Nil
      @io << "would fix " << path << ":\n"
      fixes.each do |fix|
        @io << "line " << fix.line_number << ": " << preview_fix(fix) << '\n'
      end
      @io << "would reorder " << sort_fix.sorted_values.size << " lines\n" if sort_fix
    end

    # Renders one fix as `"old" → "new"`, or `delete "old"` for deletions.
    private def preview_fix(fix : Fix) : String
      old_text = preview_text(fix.original)
      return "delete \"#{old_text}\"" if fix.deletion?
      "\"#{old_text}\" → \"#{preview_text(fix.replacement)}\""
    end

    # Strips control characters so preview lines stay one-per-line and injection-free.
    private def preview_text(text : String) : String
      text.gsub(/[\x00-\x1F\x7F]/, "")
    end

    # Write fixed content atomically: temp file in the same directory plus
    # rename, so a crash never leaves a truncated ignore file behind.
    private def atomic_write(path : String, content : String) : Nil
      perms = File.info(path).permissions
      tmp_path = "#{path}.ignorelint-tmp"
      begin
        File.write(tmp_path, content)
        File.chmod(tmp_path, perms)
        File.rename(tmp_path, path)
      rescue ex
        File.delete(tmp_path) if File.exists?(tmp_path)
        raise ex
      end
    end

    # Re-label issues that were auto-fixed with severity `:fixed`.
    #
    # Creates new `Issue` instances (does not mutate the originals) for every
    # issue whose line was modified by a fix and whose code is in the fixable set.
    # The `LintResult` is rebuilt with the updated issues list.
    #
    # Individual fixes (replacements/deletions) are tracked by line number.
    # SortFixes are bulk operations — when present, all `UnsortedRule` issues
    # are marked as fixed (the SortFix reorders all active lines at once).
    private def mark_fixed(result : LintResult, fixes : Array(Fix),
                           sort_fix : Fixer::SortFix?) : LintResult
      fixed_lines = fixes.map(&.line_number).to_set
      has_sort_fix = !sort_fix.nil?

      issues = result.issues.map do |issue|
        if fixed_lines.includes?(issue.line) && Fixer.fixable?(issue.code)
          Issue.new(issue.line, issue.message, :fixed, issue.code)
        elsif has_sort_fix && issue.code.unsorted_rule?
          Issue.new(issue.line, issue.message, :fixed, issue.code)
        else
          issue
        end
      end
      LintResult.new(issues: issues, patterns: result.patterns)
    end

    # Determine whether the lint result should cause a non-zero exit.
    #
    # True when any issue's severity is at or above the `@fail_on` threshold.
    # The comparison uses the enum's integer values: `Error` (0) is more severe
    # than `Warn` (1), which is more severe than `Info` (2). So
    # `severity.value <= @fail_on.value` means "this issue is at least as bad
    # as the threshold."
    #
    # Fixed issues are excluded from this check — they were already corrected.
    private def should_fail?(result : LintResult) : Bool
      threshold = @fail_on
      return false if @no_fail || threshold.nil?
      result.issues.any? do |issue|
        next false if issue.severity.fixed?
        issue.severity.value <= threshold.value
      end
    end

    # Auto-discover supported *ignore files in the current directory.
    #
    # Checks each filename in `KNOWN_FILES` for existence. Returns all found
    # files as absolute or relative paths. With `--verbose`, prints a discovery
    # list to stderr showing which files were found and which were not.
    private def find_ignore_files : Array(String)
      return find_ignore_files_recursive if @recursive
      found = [] of String

      Ignorelint::KNOWN_FILES.each_key do |name|
        if File.file?(name)
          found << name
        end
      end

      print_discovery_list(found) if @verbose

      found
    end

    # Walk the directory tree collecting known *ignore files as cwd-relative
    # paths, sorted for deterministic output. Hidden directories (`.git`),
    # `node_modules`, and symlinks are skipped: the first two are not user
    # code, the last avoids cycles and double-linting linked files.
    private def find_ignore_files_recursive : Array(String)
      found = [] of String
      collect_ignore_files(Dir.current, Dir.current, found)
      found.sort!

      if @verbose
        if found.empty?
          @err << info_label << " no *ignore files found\n\n"
        else
          found.each { |path| @err << info_label << ' ' << path << " found\n" }
          @err << '\n'
        end
      end

      found
    end

    # Recursively collect known files under `dir`, recording paths relative
    # to `root`. Unreadable directories yield no children, never fatal.
    private def collect_ignore_files(root : String, dir : String, found : Array(String)) : Nil
      children = begin
        Dir.children(dir)
      rescue Exception
        [] of String
      end
      children.each do |entry|
        full = File.join(dir, entry)
        next if File.symlink?(full)
        if Dir.exists?(full)
          next if entry.starts_with?('.') || entry == "node_modules"
          collect_ignore_files(root, full, found)
        elsif File.file?(full) && Ignorelint::KNOWN_FILES.has_key?(entry)
          found << Path[full].relative_to(root).to_s
        end
      end
    end

    # Print a verbose discovery report showing which *ignore files were found.
    #
    # Only called when `--verbose` is active; writes to stderr in every format.
    # Each known filename is listed as either "found" or "not found".
    private def print_discovery_list(found : Array(String)) : Nil
      Ignorelint::KNOWN_FILES.each_key do |name|
        if found.includes?(name)
          @err << info_label << ' ' << name << " found\n"
        else
          @err << info_label << ' ' << name << " not found\n"
        end
      end
      @err << '\n'
    end

    # Format the "info:" label for discovery output.
    #
    # Left-aligned to `SEVERITY_WIDTH` characters so it lines up with
    # the severity labels in human output.
    private def info_label : String
      "%-#{SEVERITY_WIDTH}s" % "info:"
    end

    # Check whether an environment value is truthy.
    #
    # Falsy: empty, or `"0"`, `"false"`, `"no"`, `"n"`, `"off"`
    # (case-insensitive, surrounding whitespace ignored).
    def self.env_bool?(value : String) : Bool
      !{"", "0", "false", "no", "n", "off"}.includes?(value.strip.downcase)
    end
  end
end
