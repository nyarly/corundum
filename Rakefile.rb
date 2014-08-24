require 'corundum/tasklibs'
require 'corundum/documentation'
require 'mattock/yard_extensions'

include Corundum
Corundum::register_project(__FILE__)

file 'bin/corundum-skel'

namespace :corundum do
  core = Core.new do |core|
    core.gemspec_path = "corundum.gemspec"
    core.file_lists.project = [__FILE__]
  end

  core.in_namespace do
    GemspecFiles.new(core) do |files|
      files.extra_files = Rake::FileList[
        "lib/corundum/default_configuration/preferences.yaml",
        "lib/corundum/default_configuration/skel-files/**,*"
      ]
    end

    QuestionableContent.all_sets(core)

    rspec = RSpec.new(core)
    cov = SimpleCov.new(core, rspec) do |cov|
      cov.threshold = 58
    end
    gem = GemBuilding.new(core)
    cutter = GemCutter.new(core,gem)
    email = Email.new(core)
    vc = Git.new(core) do |vc|
      vc.branch = "master"
    end
    yd = YARDoc.new(core) do |yd|
      yd.extra_files = ["Rakefile.rb"]
      yd.readme = "doc/README"
      yd.options = %w[--exclude corundum/default_configuration]
    end
    all_docs = DocumentationAssembly.new(core, yd, rspec, cov) do |da|
      da.external_docs["The Wiki"] = "https://github.com/nyarly/corundum/wiki"
    end
    pages = GithubPages.new(all_docs)
  end
end

namespace 'corundum-docs' do
  docs = Core.new do |docs|
    docs.gemspec_path = "corundum-docs.gemspec"
  end

  docs.in_namespace do
    GemspecFiles.new(docs) do |files|
      files.extra_files = Rake::FileList["lib/corundum/default_configuration/templates/**/*"]
    end

    QuestionableContent.all_sets(docs)

    rspec = RSpec.new(docs)
    cov = SimpleCov.new(docs, rspec) do |cov|
      cov.threshold = 58
    end
    gem = GemBuilding.new(docs)
    cutter = GemCutter.new(docs,gem)
    email = Email.new(docs)
    vc = Git.new(docs) do |vc|
      vc.branch = "master"
    end
    yd = YARDoc.new(docs) do |yd|
      yd.extra_files = ["Rakefile.rb"]
      yd.readme = "doc/README"
      yd.options = %w[--exclude corundum/default_configuration]
    end
    all_docs = DocumentationAssembly.new(docs, yd, rspec, cov) do |da|
      da.external_docs["The Wiki"] = "https://github.com/nyarly/corundum/wiki"
    end
    pages = GithubPages.new(all_docs)
  end
end


task :default => ['corundum:qa', 'corundum-docs:qa']

desc "Release all gems in the corundum cluster"
task 'release-all' => ['corundum:release', 'corundum-docs:release']
