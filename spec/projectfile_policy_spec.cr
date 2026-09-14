# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "file_utils"
require "../src/issue"
require "../src/output_format"
require "../src/projectfile_policy"

private def with_pf_doc(name : String, content : String, & : String -> T) : T forall T
  dir = File.join("/tmp", "ignorelint-policy-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
  Dir.mkdir_p(dir)
  begin
    path = File.join(dir, name)
    File.write(path, content)
    yield path
  ensure
    FileUtils.rm_rf(dir)
  end
end

private def with_fake_pf_cli(body : String, & : String -> T) : T forall T
  dir = File.join("/tmp", "ignorelint-fakebin-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
  Dir.mkdir_p(dir)
  begin
    path = File.join(dir, "pf-cli")
    File.write(path, "#!/bin/sh\n#{body}\n")
    File.chmod(path, 0o755)
    yield dir
  ensure
    FileUtils.rm_rf(dir)
  end
end

private def with_fake_path(body : String, & : -> T) : T forall T
  with_fake_pf_cli(body) do |bin|
    old = ENV["PATH"]?
    ENV["PATH"] = "#{bin}:#{old}"
    begin
      yield
    ensure
      if old.nil?
        ENV.delete("PATH")
      else
        ENV["PATH"] = old
      end
    end
  end
end

describe Ignorelint::ProjectfilePolicy do
  describe ".discover" do
    it "finds nothing in an empty directory" do
      dir = File.join("/tmp", "ignorelint-discover-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
      Dir.mkdir_p(dir)
      begin
        old = Dir.current
        begin
          Dir.cd(dir)
          Ignorelint::ProjectfilePolicy.discover.should be_nil
        ensure
          Dir.cd(old)
        end
      ensure
        FileUtils.rm_rf(dir)
      end
    end

    it "prefers yaml over toml over json" do
      dir = File.join("/tmp", "ignorelint-discover-order-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
      Dir.mkdir_p(dir)
      begin
        File.write(File.join(dir, "projectfile.json"), "{}\n")
        File.write(File.join(dir, "projectfile.toml"), "x = 1\n")
        old = Dir.current
        begin
          Dir.cd(dir)
          Ignorelint::ProjectfilePolicy.discover.should eq("projectfile.toml")
          File.write(File.join(dir, "projectfile.yaml"), "x: 1\n")
          Ignorelint::ProjectfilePolicy.discover.should eq("projectfile.yaml")
        ensure
          Dir.cd(old)
        end
      ensure
        FileUtils.rm_rf(dir)
      end
    end
  end

  describe ".fetch" do
    it "reads every known key from the fetched JSON" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo '{"fail-on": "warn", "format": "json", "fix": true, "recursive": true, "verbose": true, "disabled-rules": ["IG-001", "ig-020"]}')) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: true)
          err.to_s.should be_empty
          settings.should_not be_nil
          settings = settings.as(Ignorelint::PolicySettings)
          settings.fail_on.should eq(Ignorelint::Severity::Warn)
          settings.format.should eq(Ignorelint::OutputFormat::Json)
          settings.fix.should be_true
          settings.recursive.should be_true
          settings.verbose.should be_true
          settings.disabled.should eq(Set{"IG-001", "IG-020"})
        end
      end
    end

    it "accepts snake_case spellings and a flat disabled-rules string" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo '{"fail_on": "error", "disabled_rules": "IG-001, ig-003"}')) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: true).as(Ignorelint::PolicySettings)
          err.to_s.should be_empty
          settings.fail_on.should eq(Ignorelint::Severity::Error)
          settings.disabled.should eq(Set{"IG-001", "IG-003"})
        end
      end
    end

    it "reads the override map into severity buckets" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo '{"override": {"error": ["IG-020"], "warning": ["ig-001"], "info": "IG-021, IG-023"}}')) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: true).as(Ignorelint::PolicySettings)
          err.to_s.should be_empty
          settings.override_error.should eq(Set{"IG-020"})
          settings.override_warning.should eq(Set{"IG-001"})
          settings.override_info.should eq(Set{"IG-021", "IG-023"})
        end
      end
    end

    it "accepts warn as an alias of warning" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo '{"override": {"warn": ["IG-001"]}}')) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: true).as(Ignorelint::PolicySettings)
          err.to_s.should be_empty
          settings.override_warning.should eq(Set{"IG-001"})
        end
      end
    end

    it "warns on unknown override severities, codes, and bad shapes" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo '{"override": {"critical": ["IG-001"], "error": ["BOGUS", "IG-020"], "info": 42}}')) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: true).as(Ignorelint::PolicySettings)
          err.to_s.should contain("unknown override severity: critical")
          err.to_s.should contain("unknown override code: BOGUS")
          err.to_s.should contain("ignoring override.info value")
          settings.override_error.should eq(Set{"IG-020"})
          settings.override_info.should be_nil
        end
      end
    end

    it "warns on a non-mapping override value" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo '{"override": ["IG-001"]}')) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: true).as(Ignorelint::PolicySettings)
          err.to_s.should contain("ignoring override value")
          settings.override_error.should be_nil
        end
      end
    end

    it "treats null as an absent subtree without diagnostics" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo 'null'; exit 1)) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: false).as(Ignorelint::PolicySettings)
          err.to_s.should be_empty
          settings.empty?.should be_true
        end
      end
    end

    it "warns on unknown keys and skips bad values without failing" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo '{"fail-on": "bogus", "format": "bogus", "fix": "maybe", "disabled-rules": 42, "future-key": true}')) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: true).as(Ignorelint::PolicySettings)
          err.to_s.should contain("fail-on")
          err.to_s.should contain("format")
          err.to_s.should contain("fix")
          err.to_s.should contain("disabled-rules")
          err.to_s.should contain("unknown ignorelint policy key: future-key")
          settings.empty?.should be_true
        end
      end
    end

    it "warns on a non-mapping subtree" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo 'false')) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: true).as(Ignorelint::PolicySettings)
          err.to_s.should contain("expected a mapping")
          settings.empty?.should be_true
        end
      end
    end

    it "returns nil for an unreadable explicit document" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo 'Error: parse boom' >&2; exit 1)) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: true)
          settings.should be_nil
          err.to_s.should contain("cannot read policy")
          err.to_s.should contain("parse boom")
        end
      end
    end

    it "returns empty settings with a warning for an unreadable discovered document" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        with_fake_path(%q(echo 'Error: parse boom' >&2; exit 1)) do
          err = IO::Memory.new
          settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: false).as(Ignorelint::PolicySettings)
          settings.empty?.should be_true
          err.to_s.should contain("policy unreadable")
        end
      end
    end

    it "informs and continues when pf-cli is not on PATH" do
      with_pf_doc("projectfile.yaml", "x: 1\n") do |doc|
        dir = File.join("/tmp", "ignorelint-emptybin-spec-#{Process.pid}-#{Random.rand(1_000_000)}")
        Dir.mkdir_p(dir)
        begin
          old = ENV["PATH"]?
          ENV["PATH"] = dir
          begin
            err = IO::Memory.new
            settings = Ignorelint::ProjectfilePolicy.fetch(doc, err, explicit: false).as(Ignorelint::PolicySettings)
            settings.empty?.should be_true
            err.to_s.should contain("pf-cli not found")
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
    end
  end
end
