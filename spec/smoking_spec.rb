require 'corundum'
require 'corundum/tasklibs'

require 'corundum/rubyforge'

module Corundum
  describe "A fairly complete Rakefile" do
    before :each do
      tk = Toolkit.new do |tk|
      end

      tk.in_namespace do
        rspec = RSpec.new(tk)
        cov = SimpleCov.new(tk, rspec)
        gem = GemBuilding.new(tk)
        cutter = GemCutter.new(tk, gem)
        email = Email.new(tk)
        vc = Monotone.new(tk)
        docs = YARDoc.new(tk)
      end
    end

    it "should have some tasks" do
      true.should be_true
    end
  end
end
