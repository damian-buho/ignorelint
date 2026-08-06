# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

require "spec"
require "../src/file_type"

describe Ignorelint::FileType do
  describe ".from_path" do
    it "detects .gitignore" do
      Ignorelint::FileType.from_path(".gitignore").should eq Ignorelint::FileType::Gitignore
    end

    it "detects nested .gitignore" do
      Ignorelint::FileType.from_path("src/.gitignore").should eq Ignorelint::FileType::Gitignore
    end

    it "detects .dockerignore" do
      Ignorelint::FileType.from_path(".dockerignore").should eq Ignorelint::FileType::Dockerignore
    end

    it "detects .npmignore" do
      Ignorelint::FileType.from_path(".npmignore").should eq Ignorelint::FileType::Npmignore
    end

    it "detects .claudeignore" do
      Ignorelint::FileType.from_path(".claudeignore").should eq Ignorelint::FileType::Claudeignore
    end

    it "detects .eslintignore" do
      Ignorelint::FileType.from_path(".eslintignore").should eq Ignorelint::FileType::Eslintignore
    end

    it "detects nested .eslintignore" do
      Ignorelint::FileType.from_path("src/.eslintignore").should eq Ignorelint::FileType::Eslintignore
    end

    it "detects .prettierignore" do
      Ignorelint::FileType.from_path(".prettierignore").should eq Ignorelint::FileType::Prettierignore
    end

    it "detects nested .prettierignore" do
      Ignorelint::FileType.from_path("src/.prettierignore").should eq Ignorelint::FileType::Prettierignore
    end

    it "detects .stylelintignore" do
      Ignorelint::FileType.from_path(".stylelintignore").should eq Ignorelint::FileType::Stylelintignore
    end

    it "detects nested .stylelintignore" do
      Ignorelint::FileType.from_path("src/.stylelintignore").should eq Ignorelint::FileType::Stylelintignore
    end

    it "detects .yarnignore" do
      Ignorelint::FileType.from_path(".yarnignore").should eq Ignorelint::FileType::Yarnignore
    end

    it "detects nested .yarnignore" do
      Ignorelint::FileType.from_path("src/.yarnignore").should eq Ignorelint::FileType::Yarnignore
    end

    it "detects .tfignore" do
      Ignorelint::FileType.from_path(".tfignore").should eq Ignorelint::FileType::Tfignore
    end

    it "detects nested .tfignore" do
      Ignorelint::FileType.from_path("src/.tfignore").should eq Ignorelint::FileType::Tfignore
    end

    it "detects .containerignore" do
      Ignorelint::FileType.from_path(".containerignore").should eq Ignorelint::FileType::Containerignore
    end

    it "detects nested .containerignore" do
      Ignorelint::FileType.from_path("src/.containerignore").should eq Ignorelint::FileType::Containerignore
    end

    it "detects .helmignore" do
      Ignorelint::FileType.from_path(".helmignore").should eq Ignorelint::FileType::Helmignore
    end

    it "detects nested .helmignore" do
      Ignorelint::FileType.from_path("src/.helmignore").should eq Ignorelint::FileType::Helmignore
    end

    it "detects .gcloudignore" do
      Ignorelint::FileType.from_path(".gcloudignore").should eq Ignorelint::FileType::Gcloudignore
    end

    it "detects nested .gcloudignore" do
      Ignorelint::FileType.from_path("src/.gcloudignore").should eq Ignorelint::FileType::Gcloudignore
    end

    it "detects .ebignore" do
      Ignorelint::FileType.from_path(".ebignore").should eq Ignorelint::FileType::Ebignore
    end

    it "detects nested .ebignore" do
      Ignorelint::FileType.from_path("src/.ebignore").should eq Ignorelint::FileType::Ebignore
    end

    it "detects .slugignore" do
      Ignorelint::FileType.from_path(".slugignore").should eq Ignorelint::FileType::Slugignore
    end

    it "detects nested .slugignore" do
      Ignorelint::FileType.from_path("src/.slugignore").should eq Ignorelint::FileType::Slugignore
    end

    it "detects .vercelignore" do
      Ignorelint::FileType.from_path(".vercelignore").should eq Ignorelint::FileType::Vercelignore
    end

    it "detects nested .vercelignore" do
      Ignorelint::FileType.from_path("src/.vercelignore").should eq Ignorelint::FileType::Vercelignore
    end

    it "detects .cfignore" do
      Ignorelint::FileType.from_path(".cfignore").should eq Ignorelint::FileType::Cfignore
    end

    it "detects nested .cfignore" do
      Ignorelint::FileType.from_path("src/.cfignore").should eq Ignorelint::FileType::Cfignore
    end

    it "detects .openapi-generator-ignore" do
      Ignorelint::FileType.from_path(".openapi-generator-ignore").should eq Ignorelint::FileType::OpenapiGeneratorIgnore
    end

    it "detects nested .openapi-generator-ignore" do
      Ignorelint::FileType.from_path("src/.openapi-generator-ignore").should eq Ignorelint::FileType::OpenapiGeneratorIgnore
    end

    it "detects .cursorignore" do
      Ignorelint::FileType.from_path(".cursorignore").should eq Ignorelint::FileType::Cursorignore
    end

    it "detects nested .cursorignore" do
      Ignorelint::FileType.from_path("src/.cursorignore").should eq Ignorelint::FileType::Cursorignore
    end

    it "detects .aiderignore" do
      Ignorelint::FileType.from_path(".aiderignore").should eq Ignorelint::FileType::Aiderignore
    end

    it "detects nested .aiderignore" do
      Ignorelint::FileType.from_path("src/.aiderignore").should eq Ignorelint::FileType::Aiderignore
    end

    it "detects .aiexclude" do
      Ignorelint::FileType.from_path(".aiexclude").should eq Ignorelint::FileType::Aiexclude
    end

    it "detects nested .aiexclude" do
      Ignorelint::FileType.from_path("src/.aiexclude").should eq Ignorelint::FileType::Aiexclude
    end

    it "detects .codeiumignore" do
      Ignorelint::FileType.from_path(".codeiumignore").should eq Ignorelint::FileType::Codeiumignore
    end

    it "detects nested .codeiumignore" do
      Ignorelint::FileType.from_path("src/.codeiumignore").should eq Ignorelint::FileType::Codeiumignore
    end

    it "detects .ignore" do
      Ignorelint::FileType.from_path(".ignore").should eq Ignorelint::FileType::Ignore
    end

    it "detects nested .ignore" do
      Ignorelint::FileType.from_path("src/.ignore").should eq Ignorelint::FileType::Ignore
    end

    it "detects .rgignore" do
      Ignorelint::FileType.from_path(".rgignore").should eq Ignorelint::FileType::Rgignore
    end

    it "detects nested .rgignore" do
      Ignorelint::FileType.from_path("src/.rgignore").should eq Ignorelint::FileType::Rgignore
    end

    it "detects .fdignore" do
      Ignorelint::FileType.from_path(".fdignore").should eq Ignorelint::FileType::Fdignore
    end

    it "detects nested .fdignore" do
      Ignorelint::FileType.from_path("src/.fdignore").should eq Ignorelint::FileType::Fdignore
    end

    it "detects .eleventyignore" do
      Ignorelint::FileType.from_path(".eleventyignore").should eq Ignorelint::FileType::Eleventyignore
    end

    it "detects nested .eleventyignore" do
      Ignorelint::FileType.from_path("src/.eleventyignore").should eq Ignorelint::FileType::Eleventyignore
    end

    it "returns Unknown for unrecognized files" do
      Ignorelint::FileType.from_path(".unknownfile").should eq Ignorelint::FileType::Unknown
    end
  end
end
