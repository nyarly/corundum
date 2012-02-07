require 'corundum/tasklibs'
require 'mattock/yard_extensions'

module Corundum
  register_project(__FILE__)

  tk = Toolkit.new do |tk|
    tk.file_lists.project = [__FILE__]
  end

  tk.in_namespace do
    sanity = GemspecSanity.new(tk)
    rspec = RSpec.new(tk)
    cov = SimpleCov.new(tk, rspec) do |cov|
      cov.threshold = 55
    end
    gem = GemBuilding.new(tk)
    cutter = GemCutter.new(tk,gem)
    email = Email.new(tk)
    vc = Git.new(tk) do |vc|
      vc.branch = "master"
    end
    task tk.finished_files.build => vc["is_checked_in"]
    yd = YARDoc.new(tk) do |yd|
      yd.extra_files = ["Rakefile.rb"]
    end
    all_docs = DocumentationAssembly.new(tk, yd, rspec, cov)
    pages = GithubPages.new(all_docs)
  end
end

task :default => [:release, :publish_docs]
