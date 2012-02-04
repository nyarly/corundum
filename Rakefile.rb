require 'corundum/tasklibs'

module Corundum
  tk = Toolkit.new do |tk|
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
    docs = YARDoc.new(tk) do |yd|
      yd.extra_files = ["Rakefile"]
    end
    pages = GithubPages.new(docs)
    task pages[:assemble_docs] => docs.entry_point
  end
end
