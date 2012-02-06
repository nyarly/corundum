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

    setting(:sub_dir, "coverage")
    setting(:config_file, ".simplecov")
    setting(:filters, ["./spec"])
    setting(:threshold, 80)
    setting(:groups, {})
    setting(:coverage_filter, proc do |path|
      /\.rb$/ =~ path
    end)

    def default_configuration(toolkit, testlib)
      super(toolkit)
      self.test_lib = testlib
      self.code_files = toolkit.files.code
      self.all_files =  toolkit.file_lists.project + toolkit.file_lists.code + toolkit.file_lists.test
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

        task :config_exists do
          File::exists?(config_path) or fail "No .simplecov (try: rake #{self[:example_config]})"
          File::read(config_path) =~ /coverage_dir.*#{target_dir}/ or fail ".simplecov doesn't refer to #{target_dir}"
        end

        RSpecReportTask.new(@test_lib, :report => [:config_exists] + all_files) do |t|
          t.rspec_opts += %w{-r simplecov}
        end
        file entry_path => :report

        task :generate_report => [:preflight, entry_path]

        task :verify_coverage => :generate_report do
          require 'nokogiri'

          doc = Nokogiri::parse(File::read(entry_path))

          coverage_total_xpath = "//span[@class='covered_percent']/span"
          percentage = doc.xpath(coverage_total_xpath).first.content.to_f

          raise "Coverage must be at least #{threshold} but was #{percentage}" if percentage < threshold
          puts "Coverage is #{percentage}% (required: #{threshold}%)"
        end

        task :find_stragglers => :generate_report do
          require 'nokogiri'

          doc = Nokogiri::parse(File::read(entry_path))

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
