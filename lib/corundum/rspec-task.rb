require 'rbconfig'
require 'mattock/command-task'

module Corundum
  class RSpecTask < Mattock::Rake::CommandTask
    setting :ruby_command, cmd(RbConfig.ruby) do |cmd|
      if /^1\.8/ =~ RUBY_VERSION
        cmd.options << "-S"
      end
    end

    runtime_required_fields :runner_command, :pattern, :ruby_opts,
      :warning, :rspec_path, :rspec_opts, :failure_message, :files_to_run,
      :file_dependencies

    def default_configuration(rspec)
      super
      rspec.copy_settings_to(self)
    end

    def resolve_runtime_configuration
      self.rspec_path = %x"which #{rspec_path}".chomp

      ruby_command.options << ruby_opts if ruby_opts
      ruby_command.options << "-w" if warning

      self.runner_command = cmd(rspec_path) do |cmd|
        cmd.options << all_rspec_options
        cmd.options << files_to_run
      end

      self.command = ruby_command - runner_command

      super
    end

    def all_rspec_options
      rspec_opts
    end

    def resolve_configuration
      super

      if task_args.last.is_a? Hash
        key = task_args.last.keys.first
        task_args.last[key] = [*task_args.last[key]] + file_dependencies
      else
        key = task_args.pop
        task_args << { key => file_dependencies }
      end
    end
  end

  class RSpecReportTask < RSpecTask
    dir(:target_dir, path(:doc_path, "index.html"))

    setting(:formats, {})
    setting(:extra_products, [])

    def timestamp
      return Rake::EARLY if formats.empty?
      (formats.values + extra_products).map do |path|
        if File.exist?(path.to_s)
          File.mtime(path.to_s)
        else
          Rake::EARLY
        end
      end.min
    end

    def out_of_date?(stamp)
      prerequisites.any? { |n|
        application[n, @scope].timestamp > stamp
      }
    end

    def needed?
      ! File.exist?(doc_path.abspath) || out_of_date?(timestamp)
    end

    def default_configuration(rspec)
      super
    end

    def all_rspec_options
      super + formats.inject([]) do |list, (format, target)|
        list + ["--format", format, "--out", target]
      end
    end

    def resolve_configuration
      super
      resolve_paths
    end
  end
end
