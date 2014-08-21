Gem::Specification.new do |spec|
  spec.name		= "corundum-docs"
  #{MAJOR: incompatible}.{MINOR added feature}.{PATCH bugfix}-{LABEL}
  spec.version		= "0.3.9"
  author_list = {
    "Judson Lester" => "nyarly@gmail.com"
  }
  spec.authors		= author_list.keys
  spec.email		= spec.authors.map {|name| author_list[name]}
  spec.summary		= "Documentation tools for ruby projects"
  spec.description	= <<-EndDescription
  EndDescription

  spec.rubyforge_project= spec.name.downcase
  spec.homepage        = "http://nyarly.github.com/corundum/"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f
  spec.files		= %w[
    lib/corundum/documentation.rb
    lib/corundum/documentation/email.rb
    lib/corundum/documentation/github-pages.rb
    lib/corundum/documentation/yardoc.rb
    lib/corundum/documentation/assembly.rb

    lib/corundum/default_configuration/templates/doc_assembly/index.html.erb
    lib/corundum/default_configuration/templates/doc_assembly/theme/sass/styles.scss
    lib/corundum/default_configuration/templates/doc_assembly/stylesheet.scss
    lib/corundum/default_configuration/templates/doc_assembly/theme/stylesheets/pygment_trac.css
    lib/corundum/default_configuration/templates/doc_assembly/theme/stylesheets/styles.css
    lib/corundum/default_configuration/templates/doc_assembly/theme/javascripts/scale.fix.js
    lib/corundum/default_configuration/templates/doc_assembly/theme/images/checker.png

    README-docs.md

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
  spec.rdoc_options	+= ["--title", "#{spec.name}-#{spec.version} RDoc"]

  spec.add_dependency "rdoc", ">= 0"
  spec.add_dependency "paint", "~> 0.8.7"
  spec.add_dependency "yard", ">= 0"
  spec.add_dependency "mailfactory", "~> 1.4.0"
  spec.add_dependency "rspec", ">= 2.0"
  spec.add_dependency "simplecov", ">= 0.5.4"
  spec.add_dependency "bundler"
  spec.add_dependency "nokogiri"

  spec.add_dependency "caliph", "~> 0.3"
  spec.add_dependency "mattock", "~> 0.8"
  #spec.add_dependency "sass", ">= 3.1"
  spec.add_dependency "compass", ">= 0.12.1"
end
