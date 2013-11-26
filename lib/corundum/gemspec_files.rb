require 'mattock/tasklib'

module Corundum
  class GemspecFiles < Mattock::TaskLib
    default_namespace :gemspec_files

    setting(:gemspec)
    setting(:extra_files, Rake::FileList[])

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

        task :has_extras => :has_files do
          missing_files = extra_files.to_a.find_all{|path| File.file?(path)} - gemspec.files
          unless missing_files.empty?
            fail "Untested extra files are not mentioned in gemspec: #{missing_files.inspect}"
          end
        end

        task :files_exist do
          missing = gemspec.files.find_all do |path|
            not File::exists?(path)
          end

          fail "Files mentioned in gemspec are missing: #{missing.join(", ")}" unless missing.empty?
        end
      end

      task :preflight => in_namespace(:files_exist, :has_extras, :has_files)
    end
  end
end
