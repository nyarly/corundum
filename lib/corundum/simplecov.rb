require 'corundum/tasklib'



module Corundum
  class RSpecReportTask < RSpecTask
    def command_task
      @command_task ||= file task_name do
        decorated(command).must_succeed!
      end
    end
  end

  class SimpleCov < TaskLib
    default_namespace :coverage

    setting(:test_lib)
    setting(:browser)
    setting(:code_files)
    setting(:all_files)

    setting(:report_path, nil)
    setting(:config_path, nil)

    setting(:report_dir, "doc/coverage")
    setting(:config_file, ".simplecov")
    setting(:filters, ["./spec"])
    setting(:threshold, 80)
    setting(:groups, {})
    setting(:coverage_filter, proc do |path|
      /\.rb$/ =~ path
    end)

    def default_configuration(toolkit, testlib)
      self.test_lib = testlib
      self.browser = toolkit.browser
      self.code_files = toolkit.files.code
      self.all_files =  toolkit.file_lists.project + toolkit.file_lists.code + toolkit.file_lists.test
    end

    def resolve_configuration
      self.config_path ||= File::expand_path(config_file, Rake::original_dir)
      self.report_path ||= File::join(report_dir, "index.html")
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
      contents << "  coverage_dir \"#{report_dir}\""
      contents += filter_lines.map{|line| "  " + line}
      contents += group_lines.map{|line| "  " + line}
      contents << "end"
      return contents.join("\n")
    end

    def define
      in_namespace do
        file "Rakefile"

        task :example_config do
          $stderr.puts "Try this in #{config_path}"
          $stderr.puts "(You can just do #$0 > #{config_path})"
          $stderr.puts
          puts config_file_contents
        end

        task :config_exists do
          File::exists?(File::join(Rake::original_dir, ".simplecov")) or fail "No .simplecov (try: rake #{self[:example_config]})"
        end

        directory File::dirname(report_path)
        RSpecReportTask.new(@test_lib) do |t|
          t.task_name = report_path
          t.rspec_opts += %w{-r simplecov}
        end
        file report_path => all_files

        task :generate_report => [:preflight, report_path]

        desc "View coverage in browser"
        task :view => report_path do
          sh "#{browser} #{report_path}"
        end

        task :verify_coverage => :generate_report do
          require 'nokogiri'

          doc = Nokogiri::parse(File::read(report_path))

          coverage_total_xpath = "//span[@class='covered_percent']/span"
          percentage = doc.xpath(coverage_total_xpath).first.content.to_f

          raise "Coverage must be at least #{threshold} but was #{percentage}" if percentage < threshold
          puts "Coverage is #{percentage}% (required: #{threshold}%)"
        end

        task :find_stragglers => :generate_report do
          require 'nokogiri'

          doc = Nokogiri::parse(File::read(report_path))

          covered_files = doc.xpath(
            "//table[@class='file_list']//td//a[@class='src_link']").map do |link|
            link.content
            end
          need_coverage = @code_files.find_all(&coverage_filter)

          not_listed = covered_files - need_coverage
          not_covered = need_coverage - covered_files
          unless not_listed.empty? and not_covered.empty?
            raise ["Covered files and gemspec manifest don't match:",
              "Not in gemspec: #{not_listed.inspect}",
            "Not covered: #{not_covered.inspect}"].join("\n")
          end
        end
      end
      task :preflight => in_namespace(:config_exists)

      task :qa => in_namespace(:verify_coverage, :find_stragglers)
    end
  end
end
