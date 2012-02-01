Gem::Specification.new do |spec|
  spec.name		= "corundum"
  spec.version		= "0.0.8"
  author_list = {
    "Judson Lester" => "nyarly@gmail.com"
  }
  spec.authors		= author_list.keys
  spec.email		= spec.authors.map {|name| author_list[name]}
  spec.summary		= "Tools for making ruby gems"
  spec.description	= <<-EndDescription
  A Corundum is a synthetic gemstone - including synthetic rubies.  Ergo: a tool for synthesizing gems.
  EndDescription

  spec.rubyforge_project= spec.name.downcase
  spec.homepage        = "http://#{spec.rubyforge_project}.rubyforge.org/"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f
  spec.files		= %w[
    lib/corundum/browser-task.rb
    lib/corundum/github-pages.rb
    lib/corundum/rspec.rb
    lib/corundum/email.rb
    lib/corundum/gemspec_sanity.rb
    lib/corundum/gemcutter.rb
    lib/corundum/tasklib.rb
    lib/corundum/yardoc.rb
    lib/corundum/gem_building.rb
    lib/corundum/tasklibs.rb
    lib/corundum/simplecov.rb
    lib/corundum/rubyforge.rb
    lib/corundum/version_control.rb
    lib/corundum/version_control/monotone.rb
    lib/corundum/version_control/git.rb
    lib/corundum/configuration_store.rb
    lib/corundum/default_configuration/preferences.yaml
    lib/corundum.rb
    README.md
    spec/smoking_spec.rb
    spec_help/spec_helper.rb
    spec_help/gem_test_suite.rb
    spec_help/ungemmer.rb
    spec_help/file-sandbox.rb
  ]

  spec.test_file        = "spec_help/gem_test_suite.rb"
  spec.licenses = ["MIT"]
  spec.require_paths = %w[lib/]
  spec.rubygems_version = "1.3.5"

  if spec.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    spec.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      spec.add_development_dependency "corundum", "~> 0.0.1"
    else
      spec.add_development_dependency "corundum", "~> 0.0.1"
    end
  else
    spec.add_development_dependency "corundum", "~> 0.0.1"
  end

  spec.has_rdoc		= true
  spec.extra_rdoc_files = Dir.glob("doc/**/*")
  spec.rdoc_options	= %w{--inline-source }
  spec.rdoc_options	+= %w{--main doc/README }
  spec.rdoc_options	+= ["--title", "#{spec.name}-#{spec.version} RDoc"]

  spec.add_dependency "rake-rubygems", ">= 0.2.0"
  #spec.add_dependency "hanna", "~> 0.1.0"
  spec.add_dependency "rdoc", ">= 0"
  spec.add_dependency "yard", ">= 0"
  spec.add_dependency "mailfactory", "~> 1.4.0"
  spec.add_dependency "rspec", ">= 2.0"
  spec.add_dependency "simplecov", ">= 0.5.4"
  spec.add_dependency "bundler", "~> 1.0.0"
  spec.add_dependency "nokogiri"
  spec.add_dependency "mattock", ">= 0.1"

  spec.post_install_message = "Another tidy package brought to you by Judson"
end
