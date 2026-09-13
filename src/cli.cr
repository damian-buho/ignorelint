# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# The CLI: command-line interface, option parsing, and main orchestration loop.
#
# This is the top-level coordinator that ties together all subsystems:
#
#   1. Parse command-line flags (`--format`, `--fail-on`, `--fix`, `--verbose`)
#   2. Apply environment variable overrides (`IGNORELINT_*`, `NO_COLOR`)
#   3. Build the appropriate output `Formatter`
#   4. Discover ignore files (or use explicitly provided paths)
#   5. Lint each file via `Linter.lint`
#   6. Optionally auto-fix issues via `Fixer.apply_fixes`
#   7. Format and emit results
#   8. Return the appropriate exit code (0 = clean, 1 = issues found)
#
# ## Crystal note: `OptionParser`
#
# Crystal's standard library `OptionParser` handles flag parsing. It supports:
#   - Short flags (`-h`) and long flags (`--help`)
#   - Flags with values (`--format=json`)
#   - Positional arguments via `unknown_args` (everything not consumed by flags)
#   - Invalid option handling via `invalid_option`
#
# Unlike some CLI frameworks, `OptionParser` does not build a result object —
# it mutates state in closures as it parses.
require "option_parser"

require "./file_type"
require "./fix"
require "./fixer"
require "./formatter"
require "./linter"
require "./output_format"
require "./parser"
require "./version"

module Ignorelint
  # The command-line interface class.
  #
  # ## Design
  #
  # The CLI is a regular class (not a struct) because it holds mutable state:
  # the parsed options (`@paths`, `@fail_on`, `@format`, `@fix`, `@verbose`).
  # A single instance is created per invocation and orchestrates the entire
  # lint run.
  #
  # ## Exit codes
  #
  # - `0`: no issues at or above the `--fail-on` threshold
  # - `1`: issues found at or above the threshold
  # - `2`: invalid CLI arguments (unknown flags, bad values)
  #
  # ## Crystal note: `private` constants
  #
  # `SEVERITY_WIDTH` is a `private` constant (uppercase = constant in Crystal).
  # It is defined on the class, not the module. Crystal's `private` on a
  # constant restricts visibility to the defining type.
  class CLI
    # Width of the severity label column in human output (e.g. "error:" is 6 chars).
    private SEVERITY_WIDTH = 6

    # Convenience entry point: create an instance and run.
    #
    # Separates construction from execution so tests can inject a custom `IO`.
    # The `io` parameter defaults to `STDOUT` but can be replaced with a
    # `StringIO` for testing.
    def self.run(args : Array(String), io : IO = STDOUT, err : IO = STDERR) : Nil
      code = new(io, err).run(args)
      exit(code) if code != 0
    end

    # Output stream for lint results (must stay machine-clean for json output).
    @io : IO

    # Output stream for diagnostics: errors, usage, file-not-found reports.
    @err : IO

    # Explicitly provided file paths (from positional CLI arguments).
    @paths = [] of String

    # Minimum severity level that triggers a non-zero exit code.
    # Default: `:error` — only errors cause failure. Use `--fail-on=warn`
    # to fail on warnings too, or `--fail-on=info` to fail on anything.
    @fail_on : Severity = :error

    # True once `--fail-on` was passed explicitly (env must not override it).
    @fail_on_set : Bool = false

    # Output format selector. Determines which `Formatter` subclass to use.
    @format : OutputFormat = :human

    # Whether `--fix` was requested (auto-fix deterministically fixable issues).
    @fix : Bool

    # Whether `--diff` was requested (preview fixes without writing).
    @diff : Bool

    # Whether `--stdin` was requested (lint piped content instead of files).
    @stdin : Bool

    # The display filename for `--stdin` mode (drives format detection).
    @stdin_file : String?

    # Whether `--verbose` was requested (show file discovery output).
    @verbose : Bool

    # Whether to search subdirectories for ignore files (vs cwd only).
    @recursive : Bool

    # Whether the output stream is a TTY (used to decide color output).
    @tty : Bool

    # Initialize the CLI with an output stream.
    #
    # Detects TTY status and reads the `IGNORELINT_VERBOSE` environment variable.
    # Crystal's `responds_to?(:tty?)` is a type-safe way to check if the `IO`
    # supports TTY detection (not all `IO` types do — `StringIO` does not).
    def initialize(@io : IO, @err : IO = STDERR)
      @tty = @io.responds_to?(:tty?) && @io.tty?
      @verbose = env_true?("IGNORELINT_VERBOSE")
      @recursive = env_true?("IGNORELINT_RECURSIVE")
      @fix = false
      @diff = false
      @stdin = false
      @stdin_file = nil
    end

    # Main execution: parse flags, discover files, lint, format.
    #
    # Returns the process exit code (0 = clean) instead of exiting, so specs
    # can assert on it; `self.run` performs the actual `exit`.
    #
    # The flow is:
    #   1. Build and parse the option parser (consumes flags from `args`)
    #   2. Apply environment variable overrides (may change `@verbose`, `@fail_on`)
    #   3. Build the output formatter
    #   4. Determine which files to lint (explicit paths or auto-discovery)
    #   5. Lint each file, collecting the exit code
    #   6. Emit formatted output
    #   7. Return non-zero if issues were found above the threshold
    def run(args : Array(String), input : IO = STDIN) : Int32
      parser = build_option_parser

      parser.parse(args)

      # --fix writes while --diff only previews; combining them is a usage error.
      if @fix && @diff
        @err << "error: --fix and --diff: use one, not both\n"
        return 2
      end

      apply_env_overrides

      formatter = build_formatter
      if @stdin
        name = stdin_name
        return 2 if name.nil?
        return lint_stdin(input, formatter, name)
      end
      paths = @paths.empty? ? find_ignore_files(formatter) : @paths
      exit_code = 0

      # Three-phase formatter lifecycle: start → format each file → finish
      formatter.start(@io)

      paths.each do |path|
        code, result = lint_file(path)
        exit_code |= code # Bitwise OR: any non-zero code makes the final code non-zero
        formatter.format_file(result, @io)
      end

      formatter.finish(@io)

      exit_code
    end

    # Apply environment variable overrides for options not set via CLI flags.
    #
    # Environment variables are lower priority than explicit CLI flags — they
    # only take effect if the flag was not already set. This allows CI systems
    # to set defaults via env vars while still overriding on the command line.
    private def apply_env_overrides : Nil
      if !@verbose
        @verbose = env_true?("IGNORELINT_VERBOSE")
      end

      if env_val = ENV["IGNORELINT_FAIL_ON"]?
        @fail_on = parse_severity(env_val) unless @fail_on_set
      end
    end

    # Build the `OptionParser` that handles all CLI flags.
    #
    # Crystal's `OptionParser` uses a DSL-style block where each `p.on` call
    # registers a handler for a flag. Unknown positional arguments (files)
    # are captured via `p.unknown_args`.
    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.banner = "Usage: ignorelint [OPTIONS] [PATH...]"
        parser.separator("")
        parser.separator("Linter for *ignore files (.gitignore, .dockerignore, .eslintignore, etc.)")
        parser.separator("")
        parser.separator("Options:")

        parser.on("-h", "--help", "Show this help") { print_help(parser, @io); exit }
        parser.on("-V", "--version", "Show version") { @io << "ignorelint " << VERSION << '\n'; exit }
        parser.on("--fail-on=LEVEL", "Exit non-zero on LEVEL or worse (error|warn|info, default: error)") do |v|
          @fail_on = parse_severity(v)
          @fail_on_set = true
        end
        parser.on("--format=FORMAT", "Output format (#{OutputFormat.valid_values}, default: human)") do |v|
          parsed = OutputFormat.parse?(v)
          unless parsed
            @err << "error: invalid --format value: #{v} (expected: #{OutputFormat.valid_values})\n"
            exit(2)
          end
          @format = parsed
        end
        parser.on("-v", "--verbose", "Show discovery output and extra diagnostics") do
          @verbose = true
        end
        parser.on("-r", "--recursive", "Search subdirectories for *ignore files (skips hidden dirs, node_modules, symlinks)") do
          @recursive = true
        end
        parser.on("--fix", "Auto-fix deterministically fixable issues (IG-001,002,003,008,015,018,022,023,024)") do
          @fix = true
        end
        parser.on("--diff", "Preview auto-fix changes without writing (cannot combine with --fix)") do
          @diff = true
        end
        parser.on("--stdin", "Lint piped content instead of files (requires --file)") do
          @stdin = true
        end
        parser.on("--file=NAME", "Filename for --stdin input (drives format detection)") do |v|
          @stdin_file = v
        end

        parser.separator("")
        parser.separator("When no PATH is given, discovers supported *ignore files in the current directory.")
        parser.separator("Color is disabled when NO_COLOR is set to a non-empty value.")
        parser.separator("")
        parser.separator("Environment variables:")
        parser.separator("  IGNORELINT_VERBOSE=1       Same as --verbose")
        parser.separator("  IGNORELINT_FAIL_ON=LEVEL   Same as --fail-on (error|warn|info)")
        parser.separator("  IGNORELINT_RECURSIVE=1     Same as --recursive")
        parser.separator("  NO_COLOR=1                 Disable colored output")

        parser.unknown_args do |remaining|
          @paths = remaining
        end

        parser.invalid_option do |flag|
          @err << "error: unknown option: #{flag}\n"
          @err << parser
          exit(2)
        end
      end
    end

    # Parse a severity level string from CLI input.
    #
    # Exits with code 2 and an error message for invalid values.
    private def parse_severity(value : String) : Severity
      case value.downcase
      when "error"
        Severity::Error
      when "warn"
        Severity::Warn
      when "info"
        Severity::Info
      else
        @err << "error: invalid --fail-on value: #{value} (expected: error|warn|info)\n"
        exit(2)
      end
    end

    # Print the help text (option parser banner + flag descriptions).
    private def print_help(parser : OptionParser, io : IO) : Nil
      io << parser << '\n'
    end

    # TTY plus empty-or-unset NO_COLOR means color.
    def self.color_enabled?(tty : Bool) : Bool
      return false unless tty
      val = ENV["NO_COLOR"]?
      val.nil? || val.empty?
    end

    # Builds the formatter for the selected output format.
    private def build_formatter : Formatter
      color = self.class.color_enabled?(@tty)

      case @format
      when .human?
        HumanFormatter.new(color)
      when .json?
        JsonFormatter.new
      when .checkstyle?
        CheckstyleFormatter.new
      when .sarif?
        SarifFormatter.new
      else
        HumanFormatter.new(color)
      end
    end

    # Validates --stdin usage; reports and returns nil on conflict.
    private def stdin_name : String?
      file = @stdin_file
      if file.nil?
        @err << "error: --stdin requires --file=NAME (e.g. --file=.gitignore)\n"
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
      result = Linter.lint(name, content)
      if @fix
        content_lines = content.lines(chomp: false)
        fixes, sort_fix = result.collect_fixes(content_lines)
        @io << Fixer.apply_fixes(content_lines, fixes, sort_fix)
        result = mark_fixed(result, fixes, sort_fix) unless fixes.empty? && sort_fix.nil?
      end
      output = @fix ? @err : @io
      formatter.start(output)
      formatter.format_file(FileResult.new(name, result.issues), output)
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
      result = Linter.lint(path, content)
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
      result.issues.any? do |issue|
        next false if issue.severity.fixed?
        issue.severity.value <= @fail_on.value
      end
    end

    # Auto-discover supported *ignore files in the current directory.
    #
    # Checks each filename in `KNOWN_FILES` for existence. Returns all found
    # files as absolute or relative paths. When `--verbose` is active and the
    # formatter is human-readable, prints a discovery list showing which files
    # were found and which were not.
    private def find_ignore_files(formatter : Formatter) : Array(String)
      return find_ignore_files_recursive(formatter) if @recursive
      found = [] of String

      Ignorelint::KNOWN_FILES.each_key do |name|
        if File.file?(name)
          found << name
        end
      end

      print_discovery_list(found) if @verbose && formatter.is_a?(HumanFormatter)

      found
    end

    # Walk the directory tree collecting known *ignore files as cwd-relative
    # paths, sorted for deterministic output. Hidden directories (`.git`),
    # `node_modules`, and symlinks are skipped: the first two are not user
    # code, the last avoids cycles and double-linting linked files.
    private def find_ignore_files_recursive(formatter : Formatter) : Array(String)
      found = [] of String
      collect_ignore_files(Dir.current, Dir.current, found)
      found.sort!

      if @verbose && formatter.is_a?(HumanFormatter)
        if found.empty?
          @io << info_label << " no *ignore files found\n\n"
        else
          found.each { |path| @io << info_label << ' ' << path << " found\n" }
          @io << '\n'
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
    # Only called when `--verbose` is active and the output format is human.
    # Each known filename is listed as either "found" or "not found".
    private def print_discovery_list(found : Array(String)) : Nil
      Ignorelint::KNOWN_FILES.each_key do |name|
        if found.includes?(name)
          @io << info_label << ' ' << name << " found\n"
        else
          @io << info_label << ' ' << name << " not found\n"
        end
      end
      @io << '\n'
    end

    # Format the "info:" label for discovery output.
    #
    # Left-aligned to `SEVERITY_WIDTH` characters so it lines up with
    # the severity labels in human output.
    private def info_label : String
      "%-#{SEVERITY_WIDTH}s" % "info:"
    end

    # Check whether an environment variable is set to a truthy value.
    #
    # Falsy: unset, empty, or `"0"`, `"false"`, `"no"`, `"n"`, `"off"`
    # (case-insensitive, surrounding whitespace ignored).
    private def env_true?(key : String) : Bool
      val = ENV[key]?
      return false if val.nil?
      !{"", "0", "false", "no", "n", "off"}.includes?(val.strip.downcase)
    end
  end
end
