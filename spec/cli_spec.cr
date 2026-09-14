# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "file_utils"
require "../src/cli"

private def with_ignore_file(content : String, & : String -> T) : T forall T
  dir = File.join("/tmp", "ignorelint-cli-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
  Dir.mkdir_p(dir)
  begin
    path = File.join(dir, ".gitignore")
    File.write(path, content)
    yield path
  ensure
    FileUtils.rm_rf(dir)
  end
end

private def with_env(key : String, value : String?, & : -> T) : T forall T
  old = ENV[key]?
  if value.nil?
    ENV.delete(key)
  else
    ENV[key] = value
  end
  begin
    yield
  ensure
    if old.nil?
      ENV.delete(key)
    else
      ENV[key] = old
    end
  end
end

private def run_cli(args : Array(String), input : String = "") : {Int32, String, String}
  io = IO::Memory.new
  err = IO::Memory.new
  code = Ignorelint::CLI.new(io, err).run(args, IO::Memory.new(input))
  {code, io.to_s, err.to_s}
end

# A temp dir holding a projectfile.yaml plus a .gitignore; runs the block there.
private def with_policy_dir(ignore_content : String, & : -> T) : T forall T
  dir = File.join("/tmp", "ignorelint-policy-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
  Dir.mkdir_p(dir)
  begin
    File.write(File.join(dir, "projectfile.yaml"), "$schema: https://projectfile.org/schema/v1.json\n")
    File.write(File.join(dir, ".gitignore"), ignore_content)
    old = Dir.current
    begin
      Dir.cd(dir)
      yield
    ensure
      Dir.cd(old)
    end
  ensure
    FileUtils.rm_rf(dir)
  end
end

# A bare projectfile.yaml at an arbitrary path for --config tests.
private def with_config_file(& : String -> T) : T forall T
  dir = File.join("/tmp", "ignorelint-config-file-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
  Dir.mkdir_p(dir)
  begin
    path = File.join(dir, "projectfile.yaml")
    File.write(path, "$schema: https://projectfile.org/schema/v1.json\n")
    yield path
  ensure
    FileUtils.rm_rf(dir)
  end
end

# A fake pf-cli on a private PATH; the body answers every invocation.
private def with_fake_cli(body : String, & : -> T) : T forall T
  dir = File.join("/tmp", "ignorelint-fakecli-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
  Dir.mkdir_p(dir)
  begin
    path = File.join(dir, "pf-cli")
    File.write(path, "#!/bin/sh\n#{body}\n")
    File.chmod(path, 0o755)
    old = ENV["PATH"]?
    ENV["PATH"] = "#{dir}:#{old}"
    begin
      yield
    ensure
      if old.nil?
        ENV.delete("PATH")
      else
        ENV["PATH"] = old
      end
    end
  ensure
    FileUtils.rm_rf(dir)
  end
end

# True when pf-cli resolves on PATH; stderr assertions depend on it.
private def pf_cli_available? : Bool
  !Process.find_executable("pf-cli").nil?
end

# A PATH with no binaries at all, so pf-cli resolves as missing.
private def without_any_cli(& : -> T) : T forall T
  dir = File.join("/tmp", "ignorelint-nocli-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
  Dir.mkdir_p(dir)
  begin
    old = ENV["PATH"]?
    ENV["PATH"] = dir
    begin
      yield
    ensure
      if old.nil?
        ENV.delete("PATH")
      else
        ENV["PATH"] = old
      end
    end
  ensure
    FileUtils.rm_rf(dir)
  end
end

describe Ignorelint::CLI do
  describe "--fail-on vs IGNORELINT_FAIL_ON precedence" do
    it "defaults to fail on error" do
      with_ignore_file("foo  \n") do |path|
        with_env("IGNORELINT_FAIL_ON", nil) do
          code, _, _ = run_cli([path] of String)
          code.should eq(0)
        end
      end
    end

    it "fails on info when the env requests it" do
      with_ignore_file("foo  \n") do |path|
        with_env("IGNORELINT_FAIL_ON", "info") do
          code, _, _ = run_cli([path] of String)
          code.should eq(1)
        end
      end
    end

    it "prefers the explicit flag over the env" do
      with_ignore_file("foo  \n") do |path|
        with_env("IGNORELINT_FAIL_ON", "info") do
          code, _, _ = run_cli(["--fail-on=error", path] of String)
          code.should eq(0)
        end
      end
    end

    it "fails on info when the flag requests it" do
      with_ignore_file("foo  \n") do |path|
        with_env("IGNORELINT_FAIL_ON", nil) do
          code, _, _ = run_cli(["--fail-on=info", path] of String)
          code.should eq(1)
        end
      end
    end
  end

  describe "diagnostic streams" do
    it "sends file-not-found to stderr, keeping json stdout clean" do
      code, out, err = run_cli(["--format=json", "/nonexistent/.gitignore"] of String)
      code.should eq(1)
      out.should_not contain("error")
      err.should contain("file not found")
    end

    it "names directories instead of claiming file not found" do
      code, _, err = run_cli(["/tmp"] of String)
      code.should eq(1)
      err.should contain("is a directory")
    end

    it "leaves stderr empty on a clean human run" do
      with_ignore_file("# just a comment\n") do |path|
        code, _, err = run_cli([path] of String)
        code.should eq(0)
        if pf_cli_available?
          err.should be_empty
        else
          (err.empty? || err.includes?("pf-cli not found")).should be_true
        end
      end
    end
  end

  describe "--fix file handling" do
    it "writes fixes atomically with no temp file left behind" do
      with_ignore_file("foo  \n") do |path|
        code, _, _ = run_cli(["--fix", path] of String)
        code.should eq(0)
        File.read(path).should eq("foo\n")
        Dir.glob("#{path}.ignorelint-tmp").should be_empty
      end
    end

    it "refuses --fix on a symlink and leaves the target untouched" do
      dir = File.join("/tmp", "ignorelint-symlink-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
      Dir.mkdir_p(dir)
      begin
        target = File.join(dir, "target")
        File.write(target, "foo  \n")
        link = File.join(dir, ".gitignore")
        File.symlink(target, link)
        code, _, err = run_cli(["--fix", link] of String)
        code.should eq(0)
        err.should contain("symlink")
        File.read(target).should eq("foo  \n")
      ensure
        FileUtils.rm_rf(dir)
      end
    end
  end

  describe "--diff preview" do
    it "lists replacements, writes nothing, exits per unfixed issues" do
      with_ignore_file("!!foo\n") do |path|
        code, out, _ = run_cli(["--diff", path] of String)
        code.should eq(1)
        out.should contain("would fix #{path}:")
        out.should contain("line 1: \"!!foo\" → \"foo\"")
        File.read(path).should eq("!!foo\n")
      end
    end

    it "lists deletions" do
      with_ignore_file("*.log\n*.log\n") do |path|
        code, out, _ = run_cli(["--diff", path] of String)
        code.should eq(0)
        out.should contain("would fix #{path}:")
        out.should contain("line 2: delete \"*.log\"")
        File.read(path).should eq("*.log\n*.log\n")
      end
    end

    it "reports the reorder count for unsorted files" do
      with_ignore_file("zebra\nalpha\n") do |path|
        code, out, _ = run_cli(["--diff", path] of String)
        code.should eq(0)
        out.should contain("would fix #{path}:")
        out.should contain("would reorder 2 lines")
        File.read(path).should eq("zebra\nalpha\n")
      end
    end

    it "rejects --fix --diff together" do
      with_ignore_file("!!foo\n") do |path|
        code, _, err = run_cli(["--fix", "--diff", path] of String)
        code.should eq(2)
        err.should contain("use one, not both")
        File.read(path).should eq("!!foo\n")
      end
    end

    it "prints no listing for clean files" do
      with_ignore_file("# just a comment\n") do |path|
        code, out, _ = run_cli(["--diff", path] of String)
        code.should eq(0)
        out.should_not contain("would fix")
      end
    end
  end

  describe "--stdin mode" do
    it "lints piped content under the given name" do
      code, out, err = run_cli(["--stdin", "--file=.gitignore"] of String, "!!foo\n")
      code.should eq(1)
      out.should contain(".gitignore:1")
      out.should contain("Double negation")
      if pf_cli_available?
        err.should be_empty
      else
        (err.empty? || err.includes?("pf-cli not found")).should be_true
      end
    end

    it "reports clean piped content as valid" do
      code, out, _ = run_cli(["--stdin", "--file=.gitignore"] of String, "# just a comment\n")
      code.should eq(0)
      out.should contain(".gitignore is valid")
    end

    it "prints fixed content to stdout with the report on stderr" do
      code, out, err = run_cli(["--stdin", "--file=.gitignore", "--fix"] of String, "!!foo\n")
      code.should eq(0)
      out.should eq("foo\n")
      err.should contain("fixed:")
    end

    it "passes clean content through stdout with --fix" do
      code, out, err = run_cli(["--stdin", "--file=.gitignore", "--fix"] of String, "# just a comment\n")
      code.should eq(0)
      out.should eq("# just a comment\n")
      err.should contain("is valid")
    end

    it "requires --file with --stdin" do
      code, _, err = run_cli(["--stdin"] of String, "!!foo\n")
      code.should eq(2)
      err.should contain("--file")
    end

    it "rejects PATH arguments with --stdin" do
      with_ignore_file("!!foo\n") do |path|
        code, _, err = run_cli(["--stdin", "--file=.gitignore", path] of String, "!!foo\n")
        code.should eq(2)
        err.should contain("PATH")
      end
    end
  end

  describe "--disabled-rules" do
    it "drops matching issues entirely" do
      with_ignore_file("!!foo\n") do |path|
        code, out, _ = run_cli(["--disabled-rules=IG-003", path] of String)
        code.should eq(0)
        out.should contain("is valid")
      end
    end

    it "takes comma-separated tags case-insensitively" do
      with_ignore_file("!!foo\nfoo  \n") do |path|
        code, out, _ = run_cli(["--disabled-rules=ig-001,IG-003", path] of String)
        code.should eq(0)
        out.should_not contain("Double negation")
        out.should_not contain("Trailing whitespace")
        out.should contain("Space in pattern")
      end
    end

    it "reads IGNORELINT_DISABLED_RULES" do
      with_ignore_file("!!foo\n") do |path|
        with_env("IGNORELINT_DISABLED_RULES", "IG-003") do
          code, out, _ = run_cli([path] of String)
          code.should eq(0)
          out.should contain("is valid")
        end
      end
    end

    it "prefers the explicit flag over the env" do
      with_ignore_file("!!foo\nfoo  \n") do |path|
        with_env("IGNORELINT_DISABLED_RULES", "IG-003") do
          code, out, _ = run_cli(["--disabled-rules=IG-001", path] of String)
          code.should eq(1)
          out.should contain("Double negation")
          out.should_not contain("Trailing whitespace")
        end
      end
    end

    it "ignores unknown codes safely" do
      with_ignore_file("!!foo\n") do |path|
        code, out, _ = run_cli(["--disabled-rules=BOGUS", path] of String)
        code.should eq(1)
        out.should contain("Double negation")
      end
    end

    it "keeps disabled issues out of --fix" do
      with_ignore_file("foo  \n") do |path|
        code, _, _ = run_cli(["--fix", "--disabled-rules=IG-001", path] of String)
        code.should eq(0)
        File.read(path).should eq("foo  \n")
      end
    end
  end

  describe "IGNORLINT_VERBOSE parsing" do
    it "treats no/off as false" do
      dir = File.join("/tmp", "ignorelint-verbose-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
      Dir.mkdir_p(dir)
      begin
        File.write(File.join(dir, ".gitignore"), "# clean\n")
        old = Dir.current
        begin
          Dir.cd(dir)
          {"no", "off", "0", "false"}.each do |value|
            with_env("IGNORELINT_VERBOSE", value) do
              code, out, _ = run_cli([] of String)
              code.should eq(0)
              out.should_not contain("found")
            end
          end
          with_env("IGNORELINT_VERBOSE", "1") do
            code, out, _ = run_cli([] of String)
            code.should eq(0)
            out.should contain("found")
          end
        ensure
          Dir.cd(old)
        end
      ensure
        FileUtils.rm_rf(dir)
      end
    end
  end

  describe "--recursive discovery" do
    it "finds nested files, skipping .git, node_modules and symlinks" do
      dir = File.join("/tmp", "ignorelint-recursive-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
      Dir.mkdir_p(File.join(dir, "sub", "nested"))
      Dir.mkdir_p(File.join(dir, ".git"))
      Dir.mkdir_p(File.join(dir, "node_modules"))
      begin
        File.write(File.join(dir, "sub", ".gitignore"), "foo  \n")
        File.write(File.join(dir, "sub", "nested", ".dockerignore"), "# clean\n")
        File.write(File.join(dir, ".git", ".gitignore"), "evil  \n")
        File.write(File.join(dir, "node_modules", ".gitignore"), "evil2  \n")
        File.symlink(dir, File.join(dir, "loop"))
        old = Dir.current
        begin
          Dir.cd(dir)
          code, out, _ = run_cli(["--recursive"] of String)
          code.should eq(0)
          out.should contain("sub/.gitignore")
          out.should contain("sub/nested/.dockerignore")
          out.should_not contain(".git/.gitignore")
          out.should_not contain("node_modules")
          out.should_not contain("loop")
        ensure
          Dir.cd(old)
        end
      ensure
        FileUtils.rm_rf(dir)
      end
    end

    it "stays in the top directory without the flag" do
      dir = File.join("/tmp", "ignorelint-nonrecursive-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
      Dir.mkdir_p(File.join(dir, "sub"))
      begin
        File.write(File.join(dir, "sub", ".gitignore"), "foo  \n")
        old = Dir.current
        begin
          Dir.cd(dir)
          code, out, _ = run_cli([] of String)
          code.should eq(0)
          out.should be_empty
        ensure
          Dir.cd(old)
        end
      ensure
        FileUtils.rm_rf(dir)
      end
    end

    it "honours IGNORELINT_RECURSIVE" do
      dir = File.join("/tmp", "ignorelint-recursive-env-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
      Dir.mkdir_p(File.join(dir, "sub"))
      begin
        File.write(File.join(dir, "sub", ".gitignore"), "foo  \n")
        old = Dir.current
        begin
          Dir.cd(dir)
          with_env("IGNORELINT_RECURSIVE", "1") do
            code, out, _ = run_cli([] of String)
            code.should eq(0)
            out.should contain("sub/.gitignore")
          end
        ensure
          Dir.cd(old)
        end
      ensure
        FileUtils.rm_rf(dir)
      end
    end
  end

  describe "projectfile policy via pf-cli (org.ignorelint)" do
    it "applies fail-on from the discovered projectfile" do
      with_fake_cli(%q(echo '{"fail-on": "info"}')) do
        with_policy_dir("foo  \n") do
          code, _, _ = run_cli([".gitignore"] of String)
          code.should eq(1)
        end
      end
    end

    it "falls back to defaults when the subtree is absent" do
      with_fake_cli(%q(echo 'null'; exit 1)) do
        with_policy_dir("foo  \n") do
          code, _, err = run_cli([".gitignore"] of String)
          code.should eq(0)
          err.should be_empty
        end
      end
    end

    it "prefers the explicit flag over the projectfile" do
      with_fake_cli(%q(echo '{"fail-on": "info"}')) do
        with_policy_dir("foo  \n") do
          code, _, _ = run_cli(["--fail-on=error", ".gitignore"] of String)
          code.should eq(0)
        end
      end
    end

    it "prefers the env over the projectfile" do
      with_fake_cli(%q(echo '{"fail-on": "error"}')) do
        with_policy_dir("foo  \n") do
          with_env("IGNORELINT_FAIL_ON", "info") do
            code, _, _ = run_cli([".gitignore"] of String)
            code.should eq(1)
          end
        end
      end
    end

    it "applies disabled-rules from the projectfile" do
      with_fake_cli(%q(echo '{"disabled-rules": ["IG-003"]}')) do
        with_policy_dir("!!foo\n") do
          code, out, _ = run_cli([".gitignore"] of String)
          code.should eq(0)
          out.should contain("is valid")
        end
      end
    end

    it "reads an explicit --config outside the working directory" do
      with_fake_cli(%q(echo '{"fail-on": "info"}')) do
        with_config_file do |config|
          with_ignore_file("foo  \n") do |path|
            code, _, _ = run_cli(["--config=#{config}", path] of String)
            code.should eq(1)
          end
        end
      end
    end

    it "exits 2 for a missing --config file" do
      with_ignore_file("foo  \n") do |path|
        code, _, err = run_cli(["--config=/nonexistent/pf.yaml", path] of String)
        code.should eq(2)
        err.should contain("not found")
      end
    end

    it "exits 2 for an unreadable explicit document" do
      with_fake_cli(%q(echo 'Error: parse boom' >&2; exit 1)) do
        with_config_file do |config|
          with_ignore_file("foo  \n") do |path|
            code, _, err = run_cli(["--config=#{config}", path] of String)
            code.should eq(2)
            err.should contain("cannot read policy")
          end
        end
      end
    end

    it "warns and continues for an unreadable discovered document" do
      with_fake_cli(%q(echo 'Error: parse boom' >&2; exit 1)) do
        with_policy_dir("!!foo\n") do
          code, out, err = run_cli([".gitignore"] of String)
          code.should eq(1)
          err.should contain("policy unreadable")
          out.should contain("Double negation")
        end
      end
    end

    it "honours IGNORELINT_CONFIG" do
      with_fake_cli(%q(echo '{"fail-on": "info"}')) do
        with_config_file do |config|
          with_ignore_file("foo  \n") do |path|
            with_env("IGNORELINT_CONFIG", config) do
              code, _, _ = run_cli([path] of String)
              code.should eq(1)
            end
          end
        end
      end
    end

    it "honours IGNORELINT_FORMAT" do
      with_ignore_file("!!foo\n") do |path|
        with_env("IGNORELINT_FORMAT", "json") do
          code, out, _ = run_cli([path] of String)
          code.should eq(1)
          out.should contain("\"IG-003\"")
        end
      end
    end

    it "exits 2 for an invalid IGNORELINT_FORMAT" do
      with_ignore_file("!!foo\n") do |path|
        with_env("IGNORELINT_FORMAT", "bogus") do
          code, _, err = run_cli([path] of String)
          code.should eq(2)
          err.should contain("invalid IGNORELINT_FORMAT")
        end
      end
    end

    it "honours IGNORELINT_FIX" do
      with_ignore_file("foo  \n") do |path|
        with_env("IGNORELINT_FIX", "1") do
          code, _, _ = run_cli([path] of String)
          code.should eq(0)
          File.read(path).should eq("foo\n")
        end
      end
    end

    it "informs and keeps going when pf-cli is missing" do
      without_any_cli do
        with_policy_dir("foo  \n") do
          code, _, err = run_cli(["--fail-on=error", ".gitignore"] of String)
          code.should eq(0)
          err.should contain("pf-cli not found")
        end
      end
    end

    it "warns on unknown policy keys but still lints" do
      with_fake_cli(%q(echo '{"future-key": true}')) do
        with_policy_dir("!!foo\n") do
          code, out, err = run_cli([".gitignore"] of String)
          code.should eq(1)
          err.should contain("unknown ignorelint policy key")
          out.should contain("Double negation")
        end
      end
    end
  end

  describe "--error/--warning/--info severity overrides" do
    it "promotes IG-020 to error so the default fail-on exits 1" do
      with_ignore_file("nonexistent-dir-xyz/\n") do |path|
        code, out, _ = run_cli(["--error=IG-020", path] of String)
        code.should eq(1)
        out.should contain("error:")
        out.should contain("[IG-020]")
      end
    end

    it "demotes IG-003 to info: still reported but exits 0" do
      with_ignore_file("!!foo\n") do |path|
        code, out, _ = run_cli(["--info=IG-003", path] of String)
        code.should eq(0)
        out.should contain("info:")
        out.should contain("Double negation")
      end
    end

    it "lets the last mention of a code win" do
      with_ignore_file("nonexistent-dir-xyz/\n") do |path|
        code, out, _ = run_cli(["--error=IG-020", "--warning=IG-020", path] of String)
        code.should eq(0)
        out.should contain("warn:")
        code, out, _ = run_cli(["--warning=IG-020", "--error=IG-020", path] of String)
        code.should eq(1)
        out.should contain("error:")
      end
    end

    it "takes comma/space separated tags case-insensitively and repeatably" do
      with_ignore_file("!!foo\nnonexistent-dir-xyz/\n") do |path|
        code, out, _ = run_cli(["--error=ig-020 ig-003", path] of String)
        code.should eq(1)
        out.should contain("[IG-020]")
        out.should contain("[IG-003]")
        code, _, _ = run_cli(["--error=IG-020", "--error=IG-003", path] of String)
        code.should eq(1)
      end
    end

    it "warns on unknown codes without exiting 2" do
      with_ignore_file("!!foo\n") do |path|
        code, out, err = run_cli(["--error=BOGUS", path] of String)
        code.should eq(1)
        err.should contain("unknown severity override code: BOGUS")
        out.should contain("Double negation")
      end
    end

    it "reads IGNORELINT_OVERRIDE_ERROR" do
      with_ignore_file("nonexistent-dir-xyz/\n") do |path|
        with_env("IGNORELINT_OVERRIDE_ERROR", "IG-020") do
          code, out, _ = run_cli([path] of String)
          code.should eq(1)
          out.should contain("error:")
        end
      end
    end

    it "reads IGNORELINT_OVERRIDE_WARNING and IGNORELINT_OVERRIDE_INFO" do
      with_ignore_file("!!foo\n") do |path|
        with_env("IGNORELINT_OVERRIDE_WARNING", "IG-003") do
          code, out, _ = run_cli([path] of String)
          code.should eq(0)
          out.should contain("warn:")
        end
        with_env("IGNORELINT_OVERRIDE_INFO", "ig-003") do
          code, out, _ = run_cli([path] of String)
          code.should eq(0)
          out.should contain("info:")
        end
      end
    end

    it "prefers the flag over the environment per code" do
      with_ignore_file("nonexistent-dir-xyz/\n") do |path|
        with_env("IGNORELINT_OVERRIDE_ERROR", "IG-020") do
          code, out, _ = run_cli(["--info=IG-020", path] of String)
          code.should eq(0)
          out.should contain("info:")
        end
      end
    end

    it "warns on unknown env codes without exiting 2" do
      with_ignore_file("!!foo\n") do |path|
        with_env("IGNORELINT_OVERRIDE_ERROR", "BOGUS") do
          code, out, err = run_cli([path] of String)
          code.should eq(1)
          err.should contain("unknown severity override code: BOGUS")
          out.should contain("Double negation")
        end
      end
    end

    it "applies the projectfile override map" do
      with_fake_cli(%q(echo '{"override": {"error": ["IG-020"]}}')) do
        with_policy_dir("nonexistent-dir-xyz/\n") do
          code, out, _ = run_cli([".gitignore"] of String)
          code.should eq(1)
          out.should contain("error:")
        end
      end
    end

    it "prefers the env over the projectfile per code" do
      with_fake_cli(%q(echo '{"override": {"error": ["IG-020"]}}')) do
        with_policy_dir("nonexistent-dir-xyz/\n") do
          with_env("IGNORELINT_OVERRIDE_INFO", "IG-020") do
            code, out, _ = run_cli([".gitignore"] of String)
            code.should eq(0)
            out.should contain("info:")
          end
        end
      end
    end

    it "prefers the flag over the projectfile" do
      with_fake_cli(%q(echo '{"override": {"error": ["IG-020"]}}')) do
        with_policy_dir("nonexistent-dir-xyz/\n") do
          code, out, _ = run_cli(["--info=IG-020", ".gitignore"] of String)
          code.should eq(0)
          out.should contain("info:")
        end
      end
    end

    it "renders the overridden severity in every output format" do
      with_ignore_file("nonexistent-dir-xyz/\n") do |path|
        _, out, _ = run_cli(["--error=IG-020", "--format=json", path] of String)
        out.should contain("\"severity\": \"error\"")
        _, out, _ = run_cli(["--error=IG-020", "--format=checkstyle", path] of String)
        out.should contain("severity=\"error\"")
        _, out, _ = run_cli(["--error=IG-020", "--format=sarif", path] of String)
        out.should contain("\"level\": \"error\"")
      end
      with_ignore_file("!!foo\n") do |path|
        _, out, _ = run_cli(["--info=IG-003", "--format=json", path] of String)
        out.should contain("\"severity\": \"info\"")
        _, out, _ = run_cli(["--info=IG-003", "--format=checkstyle", path] of String)
        out.should contain("severity=\"info\"")
        _, out, _ = run_cli(["--info=IG-003", "--format=sarif", path] of String)
        out.should contain("\"level\": \"note\"")
      end
    end

    it "renders the overridden severity in human output" do
      with_ignore_file("nonexistent-dir-xyz/\n") do |path|
        _, out, _ = run_cli(["--error=IG-020", path] of String)
        out.should contain("error:")
        out.should contain("[IG-020]")
      end
    end
  end

  describe ".color_enabled?" do
    it "is false without a TTY" do
      with_env("NO_COLOR", nil) do
        Ignorelint::CLI.color_enabled?(false).should be_false
      end
    end

    it "is true on a TTY with NO_COLOR unset" do
      with_env("NO_COLOR", nil) do
        Ignorelint::CLI.color_enabled?(true).should be_true
      end
    end

    it "treats empty NO_COLOR as color allowed" do
      with_env("NO_COLOR", "") do
        Ignorelint::CLI.color_enabled?(true).should be_true
      end
    end

    it "disables color on non-empty NO_COLOR" do
      with_env("NO_COLOR", "1") do
        Ignorelint::CLI.color_enabled?(true).should be_false
      end
    end
  end
end
