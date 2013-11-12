require 'corundum/tasklibs'
require 'mattock/yard_extensions'

include Corundum
Corundum::register_project(__FILE__)

file 'bin/corundum-skel'

tk = Toolkit.new do |tk|
  tk.file_lists.project = [__FILE__]
end

tk.in_namespace do
  GemspecFiles.new(tk)
  ["debug", "profanity", "ableism", "racism"].each do |type|
    QuestionableContent.new(tk) do |content|
      content.type = type
    end
  end

  rspec = RSpec.new(tk)
  cov = SimpleCov.new(tk, rspec) do |cov|
    cov.threshold = 59
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
    yd.readme = "doc/README"
    yd.options = %w[--exclude corundum/default_configuration]
  end
  all_docs = DocumentationAssembly.new(tk, yd, rspec, cov) do |da|
    da.external_docs["The Wiki"] = "https://github.com/nyarly/corundum/wiki"
  end
  pages = GithubPages.new(all_docs)
end


task :default => [:release, :publish_docs]
