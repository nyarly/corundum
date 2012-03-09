require 'mattock/tasklib'

module Corundum
  class VersionControl < Mattock::TaskLib
    default_namespace :version_control

    required_fields(:gemspec, :build_finished_file, :gemspec_files, :tag)

    def default_configuration(toolkit)
      self.gemspec =  toolkit.gemspec
      self.build_finished_file =  toolkit.finished_files.build
      self.gemspec_files = toolkit.files.code + toolkit.files.test
      self.tag =  toolkit.gemspec.version.to_s
    end

    def define
      in_namespace do
        task :not_tagged
        task :gemspec_files_added
        task :workspace_committed
        task :is_checked_in => %w{gemspec_files_added workspace_committed}
        task :tag
        task :check_in => :tag
      end

      task :preflight => in_namespace(:not_tagged)
      task :build => in_namespace(:is_checked_in)
      in_namespace(:tag, :check_in).each do |taskname|
        task taskname => build_finished_file
      end
      task :release => in_namespace(:tag, :check_in)
    end
  end
end
