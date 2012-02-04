require 'corundum/tasklib'
require 'rspec/core'
require 'mattock/command-task'
require 'rbconfig'

module Corundum
  class RSpecTask < Mattock::CommandTask
    setting :ruby_command, Mattock::CommandLine.new(RbConfig.ruby) do |cmd|
      if /^1\.8/ =~ RUBY_VERSION
        cmd.options << "-S"
      end
    end

    setting :runner_command

    required_fields :pattern, :ruby_opts, :rspec_configs, :rspec_opts,
      :warning, :rspec_path, :rspec_opts, :failure_message, :files_to_run

    def default_configuration(rspec)
      super
      self.pattern = rspec.pattern
      self.ruby_opts = rspec.ruby_opts
      self.rspec_configs = rspec.rspec_configs
      self.rspec_opts = rspec.rspec_opts
      self.warning = rspec.warning
      self.rspec_path = rspec.rspec_path
      self.rspec_opts = rspec.rspec_opts
      self.failure_message = rspec.failure_message
      self.files_to_run = rspec.files_to_run
    end

    def resolve_configuration
      self.rspec_configs = rspec_opts
      self.rspec_path = %x"which #{rspec_path}".chomp

      ruby_command.options << ruby_opts if ruby_opts
      ruby_command.options << "-w" if warning

      self.runner_command = Mattock::CommandLine.new(rspec_path) do |cmd|
        cmd.options << rspec_opts
        cmd.options << files_to_run
      end

      self.command = Mattock::WrappingChain.new do |cmd|
        cmd.add ruby_command
        cmd.add runner_command
      end
      super
    end
  end


  class RSpec < TaskLib
    default_namespace :rspec

    settings(
      :pattern => './spec{,/*/**}/*_spec.rb',
      :rspec_configs => nil,
      :rspec_opts => nil,
      :warning => false,
      :verbose => true,
      :ruby_opts => [],
      :rspec_path => 'rspec',
      :rspec_opts => %w{--format documentation --out last_run --color --format documentation},
      :failure_message => "Spec examples failed.",
      :files_to_run => "spec"
    )

    required_fields :gemspec_path, :qa_finished_path

    def default_configuration(toolkit)
      self.gemspec_path = toolkit.gemspec_path
      self.qa_finished_path = toolkit.finished_files.qa
    end

    def resolve_configuration
      #XXX Que?
      self.rspec_configs = rspec_opts
      self.rspec_opts = []
      self.rspec_path = %x"which #{rspec_path}".chomp
    end

    def define
      in_namespace do
        desc "Always run every spec"
        RSpecTask.new(self) do |t|
          t.task_name = :all
        end

        desc "Generate specifications documentation"
        RSpecTask.new(self) do |t|
          t.task_name = :doc
          t.rspec_opts = %w{-o /dev/null -f d -o doc/Specifications}
          t.failure_message = "Failed generating specification docs"
        end

        desc "Run only failing examples listed in last_run"
        RSpecTask.new(self) do |t|
          t.task_name = :quick
          examples = []
          begin
            File.open("last_run", "r") do |fail_list|
              fail_list.lines.grep(%r{^\s*\d+\)\s*(.*)}) do |line|
                examples << $1.gsub(/'/){"[']"}
              end
            end
          rescue
          end
          unless examples.empty?
            t.rspec_opts << "--example"
            t.rspec_opts << "\"#{examples.join("|")}\""
          end
          t.failure_message = "Spec examples failed."
        end
      end

      desc "Run failing examples if any exist, otherwise, run the whole suite"
      task root_task => in_namespace(:quick)

      task :qa => in_namespace(:doc)
    end
  end
end
