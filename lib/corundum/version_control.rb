require 'mattock/tasklib'
require 'erb'

module Corundum
  class VersionControl < Mattock::CommandTaskLib
    default_namespace :version_control

    setting :tag_format, "<%= name %>-<%= version %>"
    required_fields(:gemspec, :build_finished_file, :gemspec_files, :tag)

    class TagContext
      def initialize(gemspec)
        @gemspec = gemspec
      end

      def version
        @gemspec.version
      end

      def name
        @gemspec.name
      end

      def bind
        binding
      end
    end

    def default_configuration(toolkit)
      super
      self.gemspec =  toolkit.gemspec
      self.build_finished_file =  toolkit.build_file.abspath
      self.gemspec_files = toolkit.files.code + toolkit.files.test
      tag_template = ERB.new(tag_format)
      context = TagContext.new(gemspec)
      self.tag = tag_template.result(context.bind)
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
