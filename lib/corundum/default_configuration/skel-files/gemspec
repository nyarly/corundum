Gem::Specification.new do |spec|
  spec.name		= "mattock"
  spec.version		= "0.2.13"
  author_list = {
    "Judson Lester" => "nyarly@gmail.com"
  }
  spec.authors		= author_list.keys
  spec.email		= spec.authors.map {|name| author_list[name]}
  spec.summary		= "A powerful companion to Rake"
  spec.description	= <<-EndDescription
  If Rake won't do it by itself, you oughtta Mattock.

  If you survived the pun, you might enjoy this gem.

  Features:

  * Extensions to Tasklibs to support powerful deerpaths.
  * A commandline library that supports mocking for tests.
  * A module to support common templating patterns

  EndDescription

  spec.rubyforge_project= spec.name.downcase
  spec.homepage        = "http://nyarly.github.com/mattock/"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f 2>/dev/null
  spec.files		= %w[
    yard_templates/default/module/setup.rb
    yard_templates/default/module/html/setting_summary.erb
    yard_templates/default/module/html/settings.erb
    yard_templates/default/module/html/task_definition.erb
    yard_templates/default/layout/html/setup.rb
    yard_templates/default/layout/html/tasklib_list.erb
    lib/mattock/command-line.rb
    lib/mattock/command-task.rb
    lib/mattock/testing/rake-example-group.rb
    lib/mattock/testing/mock-command-line.rb
    lib/mattock/testing/record-commands.rb
    lib/mattock/template-host.rb
    lib/mattock/yard_extensions.rb
    lib/mattock/remote-command-task.rb
    lib/mattock/tasklib.rb
    lib/mattock/task.rb
    lib/mattock/configurable.rb
    lib/mattock/configuration-store.rb
    lib/mattock/cascading-definition.rb
    lib/mattock.rb
    doc/README
    doc/Specifications
    spec/command-line.rb
    spec/command-task.rb
    spec/tasklib.rb
    spec/configurable.rb
    spec/configuration-store.rb
    spec/yard-extensions.rb
    spec/template-host.rb
    spec_help/spec_helper.rb
    spec_help/gem_test_suite.rb
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

  spec.add_dependency("valise", ">= 0.6")
  spec.add_dependency("tilt", "> 0")

  spec.post_install_message = "Another tidy package brought to you by Judson"
end
