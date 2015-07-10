Gem::Specification.new do |spec|
  spec.name		= "corundum"
  #{MAJOR: incompatible}.{MINOR added feature}.{PATCH bugfix}-{LABEL}
  spec.version		= "0.4.1"
  author_list = {
    "Judson Lester" => "nyarly@gmail.com"
  }
  spec.authors		= author_list.keys
  spec.email		= spec.authors.map {|name| author_list[name]}
  spec.summary		= "Tools for synthesizing rubygems"
  spec.description	= <<-EndDescription
  A corundum is a synthetic gemstone - including synthetic rubies.  Ergo: a
  tool for synthesizing gems.

  Corundum starts with the outlook that gemspecs are relatively easy to work
  with, and that the opinion of the RubyGems team is that they should be
  treated as a configuration file, not a code file.  Furthermore, Rake is a
  powerful, easy to use tool, and does admit the use of Ruby code to get the
  job done.

  The hard part about publishing gems is getting them into a state you'll be
  proud of.  There's dozens of fiddly steps to putting together a gem fit for
  public consumption, and it's very easy to get some of them wrong.

  Corundum is a collection of Rake tasklibs, therefore, that will perform the
  entire process of releasing gems, including QA steps up front through
  packaging and releasing the gem
  EndDescription

  spec.rubyforge_project= spec.name.downcase
  spec.homepage        = "http://nyarly.github.com/corundum/"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f
  spec.files		= %w[
    bin/corundum-skel
    lib/corundum.rb
    lib/corundum/cli/skelfiles.rb
    lib/corundum/configuration-store.rb
    lib/corundum/core.rb
    lib/corundum/qa-report.rb
    lib/corundum/browser-task.rb
    lib/corundum/rspec.rb
    lib/corundum/rspec-task.rb
    lib/corundum/gemspec_files.rb
    lib/corundum/gemcutter.rb
    lib/corundum/documentation-task.rb
    lib/corundum/gem_building.rb
    lib/corundum/tasklibs.rb
    lib/corundum/simplecov.rb
    lib/corundum/questionable-content.rb
    lib/corundum/version_control.rb
    lib/corundum/version_control/monotone.rb
    lib/corundum/version_control/git.rb
    lib/corundum/default_configuration/preferences.yaml
    lib/corundum/default_configuration/skel-files/rakefile
    lib/corundum/default_configuration/skel-files/gemspec.erb
    lib/corundum/default_configuration/skel-files/gemfile.erb
    lib/corundum/default_configuration/skel-files/travis
    lib/corundum/default_configuration/skel-files/simplecov
    README.md
    spec/smoking_spec.rb
    spec_help/spec_helper.rb
    spec_help/gem_test_suite.rb
    spec_help/ungemmer.rb
    spec_help/file-sandbox.rb
  ]

  spec.executables = %w{corundum-skel}
  spec.test_file        = "spec_help/gem_test_suite.rb"
  spec.licenses = ["MIT"]
  spec.require_paths = %w[lib/]
  spec.rubygems_version = "1.3.5"

  if spec.respond_to? :specification_version then
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
  spec.rdoc_options	+= ["--title", "#{spec.name}-#{spec.version} RDoc"]

  spec.add_dependency "paint", "~> 0.8.7"
  spec.add_dependency "rspec", ">= 2.0"
  spec.add_dependency "simplecov", ">= 0.5.4"
  spec.add_dependency "bundler"
  spec.add_dependency "simplecov-json", ">= 0.2"

  spec.add_dependency "caliph", "~> 0.3"
  spec.add_dependency "mattock", "~> 0.9"
end
