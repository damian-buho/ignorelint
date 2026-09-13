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

private def run_cli(args : Array(String)) : {Int32, String, String}
  io = IO::Memory.new
  err = IO::Memory.new
  code = Ignorelint::CLI.new(io, err).run(args)
  {code, io.to_s, err.to_s}
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
        err.should be_empty
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
end
