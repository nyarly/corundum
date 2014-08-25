require 'corundum'
require 'corundum/tasklibs'

module Corundum
  describe "A fairly complete Rakefile" do
    before :each do
      tk = Toolkit.new do |tk|
        tk.gemspec_path = "corundum.gemspec"
      end

      tk.in_namespace do
        rspec = RSpec.new(tk)
        cov = SimpleCov.new(tk, rspec)
        gem = GemBuilding.new(tk)
        cutter = GemCutter.new(tk, gem)
        vc = Git.new(tk)
      end
    end

    it "should have some tasks" do
      true.should be_true
    end
  end
end
