require 'corundum/cli/skelfiles'

describe Corundum::CLI::Skelfiles do
  let :argv do
    ["-p", "test-name"]
  end

  subject :skelfiles do
    Corundum::CLI::Skelfiles.new(argv).tap do |sf|
      sf.parse_args
    end
  end

  it "should set up the scope with project name" do
    expect(skelfiles.scope.project_name).to eq("test-name")
  end

  it "should set up target files correctly" do
    expect(skelfiles.skelfiles.map(&:target)).to contain_exactly("Rakefile", "test-name.gemspec", "Gemfile", ".simplecov", ".travis.yml")
  end
end
