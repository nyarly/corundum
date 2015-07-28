require 'corundum/version_control/git.rb'

describe Corundum::Git do
  let :gemspec do
    double("gemspec").tap do |gs|
      allow(gs).to receive(:name).and_return("test-gem")
      allow(gs).to receive(:version).and_return("1.2.3")
    end
  end

  let :toolkit do
    double("toolkit").tap do |tk|
      allow(tk).to receive(:gemspec).and_return(gemspec)
      allow(tk).to receive_message_chain(:build_file, :abspath).and_return("doesnt/matter")
      allow(tk).to receive_message_chain(:files, :code).and_return(%w"doesnt/matter")
      allow(tk).to receive_message_chain(:files, :test).and_return(%w"doesnt/matter")
    end
  end

  describe "tag formats" do
    describe "default" do
      subject :git_tasklib do
        Corundum::Git.new(toolkit)
      end

      it "should be configured with a formatted tag" do
        expect(git_tasklib.tag).to eq("test-gem-1.2.3")
      end
    end

    describe "custom" do
      subject :git_tasklib do
        Corundum::Git.new(toolkit) do |git|
          git.tag_format = "Test<<%= name %>>V<<%= version %>>"
        end
      end

      it "should be configured with a formatted tag" do
        expect(git_tasklib.tag).to eq("Test<test-gem>V<1.2.3>")
      end
    end
  end
end
