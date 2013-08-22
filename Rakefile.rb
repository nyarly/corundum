require 'corundum/tasklibs'
require 'mattock/yard_extensions'

include Corundum
Corundum::register_project(__FILE__)

file 'bin/corundum-skel'

tk = Toolkit.new do |tk|
  tk.file_lists.project = [__FILE__]
end

tk.in_namespace do
  sanity = GemspecSanity.new(tk)
  QuestionableContent.new(tk) do |dbg|
    dbg.words = %w{p debugger}
  end
  QuestionableContent.new(tk) do |swear|
    swear.type = :swearing
    swear.words = %w{fuck shit}
  end
  rspec = RSpec.new(tk)
  cov = SimpleCov.new(tk, rspec) do |cov|
    cov.threshold = 60
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
