require 'mattock/tasklib'

module Corundum
  class GemspecFiles < Mattock::TaskLib
    default_namespace :gemspec_files

    setting(:gemspec)

    def default_configuration(toolkit)
      super
      self.gemspec = toolkit.gemspec
    end

    def define
      in_namespace do
        task :has_files do
          if gemspec.files.nil? or gemspec.files.empty?
            fail "No files mentioned in gemspec - do you intend an empty gem?"
          end
        end

        task :files_exist do
          missing = gemspec.files.find_all do |path|
            not File::exists?(path)
          end

          fail "Files mentioned in gemspec are missing: #{missing.join(", ")}" unless missing.empty?
        end
      end

      task :preflight => in_namespace(:files_exist, :has_files)
    end
  end
end