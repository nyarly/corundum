require 'corundum'

require 'corundum/documentation/assembly'
require 'corundum/documentation/yardoc'
require 'corundum/documentation/github-pages'
require 'corundum/documentation/email'

Corundum.configuration_store.valise.add_search_root(
  Valise::SearchRoot.new( Valise::Unpath.from_here("default_configuration") )
)

module Corundum
  class Documentation < ::Mattock::Tasklib
    dir(:corundum_dir, "corundum",
        dir(:finished_dir, "finished",
            path(:press_file)))

    setting :gemspec

    def default_configuration(*core)
      super
      core.copy_settings_to(self)
    end

    def resolve_configuration
      super
      press_file.relative_path ||= "press-" + gemspec.version.to_s
      resolve_paths
    end

    default_namespace :documentation

    def define
      task :assemble => [ build_file.abspath, assemble_file.abspath ]
      file assemble_file.abspath => [finished_dir.abspath] do |task|
        Rake::Task[:assemble].invoke
        touch task.name
      end

      desc "Publish documentation"
      task :publish => [ assemble_file.abspath, publish_file.abspath ]
      file publish_file.abspath => [finished_dir.abspath] do |task|
        Rake::Task[:publish].invoke
        touch task.name
      end

      desc "Announce publication"
      task :press => [ release_file.abspath, press_file.abspath ]
      file press_file.abspath => [finished_dir.abspath] do |task|
        Rake::Task[:press].invoke
        touch task.name
      end
    end
  end
end
