require 'mattock/tasklib'

module Corundum
  class GemCutter < Mattock::TaskLib
    default_namespace :gemcutter

    setting(:gem_path, nil)
    setting(:build)
    setting(:gemspec)
    setting(:build_finished_path)
    setting(:gem_name)
    setting(:package_dir)

    def default_configuration(toolkit, build)
      self.build = build
      self.gemspec = toolkit.gemspec
      self.build_finished_path = toolkit.finished_files.build
      self.gem_name = toolkit.gemspec.full_name
      self.package_dir = build.package_dir
    end

    def resolve_configuration
      self.gem_path ||= File::join(package_dir, gemspec.file_name)
    end

    module CommandTweaks
      def setup_args(args = nil)
        args ||= []
        handle_options(args)
      end

      def gem_list=(list)
        gems = list
      end

      def get_all_gem_names
        return gems if defined?(gems)
        super
      end

      def get_one_gem_name
        return gems.first if defined?(gems)
        super
      end
    end

    def get_command(klass, args=nil)
      cmd = klass.new
      cmd.extend(CommandTweaks)
      cmd.setup_args(args)
      cmd
    end

    def define
      in_namespace do
        task :uninstall do |t|
          when_writing("Uninstalling #{gem_name}") do
            require "rubygems/commands/uninstall_command"
            uninstall = get_command Gem::Commands::UninstallCommand
            uninstall.options[:args] = [gem_path]
            uninstall.execute
          end
        end

        task :install => [gem_path] do |t|
          when_writing("Installing #{gem_path}") do
            require "rubygems/commands/install_command"
            install = get_command Gem::Commands::InstallCommand
            install.options[:args] = [gem_path]
            install.execute
          end
        end

        task :reinstall => [:uninstall, :install]

        task :dependencies_available do
          checker = Gem::SpecFetcher.new
          gemspec.runtime_dependencies.each do |dep|
            fulfilling = checker.find_matching(dep,false,false,false)
            if fulfilling.empty?
              fail "Dependency #{dep} is unfulfilled remotely"
            else
              puts "Remotely fulfilled: #{dep}" if verbose
            end
          end
        end

        task :is_unpushed do
          checker = Gem::SpecFetcher.new
          dep = Gem::Dependency.new(gemspec.name, "= #{gemspec.version}")
          fulfilling = checker.find_matching(dep,false,false,false)
          unless fulfilling.empty?
            fail "Gem #{gemspec.full_name} is already pushed"
          end
        end

        desc 'Push a gem up to Gemcutter'
        task :push => [:dependencies_available, :is_unpushed] do
          require "rubygems/commands/push_command"
          push = get_command(Gem::Commands::PushCommand)
          push.options[:args] = [gem_path]
          push.execute
        end
        task :push => build_finished_path
      end
      task :release => in_namespace(:push)
      task :preflight => in_namespace(:dependencies_available, :is_unpushed)
    end
  end
end
