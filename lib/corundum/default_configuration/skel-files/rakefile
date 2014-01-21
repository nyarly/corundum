# vim: set ft=ruby :
require 'corundum/tasklibs'

module Corundum
  Corundum::register_project(__FILE__)

  core = Core.new

  core.in_namespace do
    GemspecFiles.new(core)

    #Also available: 'unfinished': TODO and XXX
    ["debug", "profanity", "ableism", "racism"].each do |type|
      QuestionableContent.new(core) do |content|
        content.type = type
      end
    end
    rspec = RSpec.new(core)
    cov = SimpleCov.new(core, rspec) do |cov|
      cov.threshold = 70
    end

    gem = GemBuilding.new(core)
    cutter = GemCutter.new(core,gem)
    email = Email.new(core)
    vc = Git.new(core) do |vc|
      vc.branch = "master"
    end

    yd = YARDoc.new(core)

    docs = DocumentationAssembly.new(core, yd, rspec, cov)

    pages = GithubPages.new(docs)
  end
end

task :default => [:release, :publish_docs]
