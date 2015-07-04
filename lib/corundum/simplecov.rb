require 'corundum/documentation-task'
require 'corundum/browser-task'

module Corundum

  class SimpleCov < DocumentationTask
    default_namespace :coverage

    setting(:title, "Coverage report")

    setting(:test_lib)
    setting(:code_files)
    setting(:all_files)

    setting(:config_path, nil)

    setting(:config_file, ".simplecov")
    setting(:filters, ["./spec"])
    setting(:threshold, 80)
    setting(:groups, {})
    setting(:coverage_filter, proc do |path|
      /\.rb$/ =~ path
    end)

    dir(:target_dir,
        path(:coverage_json, "coverage.json"))

    setting(:test_options, [])

    setting :qa_rejections, nil

    def default_configuration(toolkit, testlib)
      super(toolkit)
      target_dir.relative_path = "coverage"
      self.test_lib = testlib
      self.code_files = toolkit.files.code
      self.all_files =  toolkit.file_lists.project + toolkit.file_lists.code + toolkit.file_lists.test
      self.qa_rejections = toolkit.qa_rejections
    end

    def resolve_configuration
      self.config_path ||= File::expand_path(config_file, Rake::original_dir)
      super
    end

    def filter_lines
      return filters.map do |pattern|
        "add_filter \"#{pattern}\""
      end
    end

    def group_lines
      lines = []
      groups.each_pair do |group, pattern|
        lines << "add_group \"#{group}\", \"#{pattern}\""
      end
      lines
    end

    def config_file_contents
      contents = ["SimpleCov.start do"]
      contents << "  coverage_dir \"#{target_dir}\""
      contents += filter_lines.map{|line| "  " + line}
      contents += group_lines.map{|line| "  " + line}
      contents << "end"
      return contents.join("\n")
    end

    def define
      super
      in_namespace do
        task :example_config do
          $stderr.puts "Try this in #{config_path}"
          $stderr.puts "(You can just do #$0 > #{config_path})"
          $stderr.puts
          puts config_file_contents
        end

        config_exists = task :config_exists do
          problems = []
          File::exists?(config_path) or problems << "No .simplecov (try: rake #{self[:example_config]})"
          config_string = File.read(config_path)
          unless config_string =~ /coverage_dir.*#{target_dir.pathname.relative_path_from(Pathname.pwd)}/
            problems << ".simplecov doesn't refer to #{target_dir}"
          end
          unless config_string =~ /SimpleCov::Formatter::JSONFormatter/
            problems << ".simplecov doesn't refer to SimpleCov::Formatter::JSONFormatter"
            problems << "in your .simplecov file, either: "
            problems << "    add 'formatter SimpleCov::Formatter::JSONFormatter'"
            problems << "  or"
            problems << "    add 'SimpleCov::Formatter::JSONFormatter' to an existing"
            problems << "    'formatter SimpleCov::Formatter::MultiFormatter'"
          end
          fail problems.join("\n") unless problems.empty?
        end

        class << config_exists
          attr_accessor :config_path

          def timestamp
            if File.exist?(config_path)
              File.mtime(config_path.to_s)
            else
              Rake::EARLY
            end
          end
        end
        config_exists.config_path = config_path

        @test_lib.report_task.rspec_opts << "-r simplecov"
        file entry_point => @test_lib.report_task.name
        file coverage_json => @test_lib.report_task.name

        task :verify_coverage => coverage_json do
          require 'json'
          require 'corundum/qa-report'

          doc = JSON::parse(File::read(coverage_json.to_s))

          percentage = doc["metrics"]["covered_percent"]

          report = QA::Report.new("Coverage")
          report.summary_counts = false
          report.add("percentage", entry_point, nil, percentage.round(2))
          report.add("threshold", entry_point, nil, threshold)
          qa_rejections << report

          if percentage < threshold
            report.fail "Coverage below threshold"
          end
        end

        task :find_stragglers => coverage_json do
          require 'json'
          require 'corundum/qa-report'

          doc = JSON::parse(File::read(coverage_json.to_s))

          pwd = Pathname.pwd
          covered_files = doc["files"].map{|f| Pathname.new(f["filename"]).relative_path_from(pwd).to_s}
          need_coverage = code_files.find_all(&coverage_filter)

          report = QA::Report.new("Stragglers")
          qa_rejections << report
          (covered_files - need_coverage).each do |file|
            report.add("Not in gemspec", file)
          end

          (need_coverage - covered_files).each do |file|
            report.add("Not covered", file)
          end

          unless report.empty?
            report.fail "Covered files and gemspec manifest don't match"
          end
        end
      end

      task @test_lib.report_task.name => in_namespace(:config_exists)
      task @test_lib.report_task.name => all_files

      task :preflight => in_namespace(:config_exists)
      task :run_quality_assurance => in_namespace(:verify_coverage, :find_stragglers)
      task :run_continuous_integration => in_namespace(:verify_coverage, :find_stragglers)
    end
  end
end
