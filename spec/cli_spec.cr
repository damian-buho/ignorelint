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

private def run_cli(args : Array(String)) : {Int32, String}
  io = IO::Memory.new
  code = Ignorelint::CLI.new(io).run(args)
  {code, io.to_s}
end

describe Ignorelint::CLI do
  describe "--fail-on vs IGNORELINT_FAIL_ON precedence" do
    it "defaults to fail on error" do
      with_ignore_file("foo  \n") do |path|
        with_env("IGNORELINT_FAIL_ON", nil) do
          code, _ = run_cli([path] of String)
          code.should eq(0)
        end
      end
    end

    it "fails on info when the env requests it" do
      with_ignore_file("foo  \n") do |path|
        with_env("IGNORELINT_FAIL_ON", "info") do
          code, _ = run_cli([path] of String)
          code.should eq(1)
        end
      end
    end

    it "prefers the explicit flag over the env" do
      with_ignore_file("foo  \n") do |path|
        with_env("IGNORELINT_FAIL_ON", "info") do
          code, _ = run_cli(["--fail-on=error", path] of String)
          code.should eq(0)
        end
      end
    end

    it "fails on info when the flag requests it" do
      with_ignore_file("foo  \n") do |path|
        with_env("IGNORELINT_FAIL_ON", nil) do
          code, _ = run_cli(["--fail-on=info", path] of String)
          code.should eq(1)
        end
      end
    end
  end
end
