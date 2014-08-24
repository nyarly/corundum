require 'corundum/documentation-task'
require 'corundum/rspec-task'

module Corundum
  class RSpec < DocumentationTask
    default_namespace :rspec
    title "RSpec run output"

    settings(
      :qa_rejections => nil,
      :pattern => './spec{,/*/**}/*_spec.rb',
      :warning => false,
      :verbose => true,
      :ruby_opts => [],
      :rspec_program => 'rspec',
      :rspec_opts => [],
      :failure_message => "Spec examples failed.",
      :files_to_run => "spec"
    )

    dir(:target_dir,
        path(:json_report, "rspec.json"),
        path(:doc_path, "index.html"))

    setting :rspec_path

    required_fields :gemspec_path, :qa_finished_path, :file_lists, :file_dependencies

    attr_reader :report_task

    def default_configuration(toolkit)
      super
      target_dir.relative_path = "rspec"
      self.qa_finished_path = toolkit.qa_file.abspath
      self.qa_rejections = toolkit.qa_rejections
      self.file_dependencies = file_lists.code + file_lists.test + file_lists.project
    end

    def resolve_configuration
      self.rspec_path ||= %x"which #{rspec_program}".chomp
      resolve_paths
      super
    end

    def test_task(name)
      RSpecTask.define_task(self, name) do |t|
        yield(t) if block_given?
      end
    end

    def doc_task(name)
      RSpecReportTask.define_task(self, name) do |t|
        yield(t) if block_given?
      end
    end

    def define
      super
      in_namespace do
        desc "Always run every spec"
        test_task(:all)

        desc "Generate specifications documentation"
        @report_task = doc_task(:doc => file_dependencies) do |t|
          t.rspec_opts += %w{-o /dev/null --failure-exit-code 0}
          t.formats["html"] = doc_path
          t.formats["json"] = json_report
        end
        file entry_point => :doc
        file json_report => :doc

        task :verify => json_report do |task|
          require 'json'
          require 'corundum/qa-report'

          doc = JSON::parse(File::read(json_report.to_s))

          rejections = QA::Report.new("RSpec[#{json_report}]")
          qa_rejections << rejections

          doc["examples"].find_all do |example|
            example["status"] == "failed"
          end.each do |failed|
            file,line,_ = failed["exception"]["backtrace"].first.split(":", 3)
            value = failed["exception"]["message"]
            rejections.add("fail", file, line, value)
          end

          unless rejections.empty?
            rejections.fail "Spec fails, none allowed"
          end
        end

        desc "Run only failing examples listed in last_run"
        test_task(:quick) do |t|
          examples = []
          begin
            File.open("last_run", "r") do |fail_list|
              fail_list.each_line.grep(%r{^\s*\d+\)\s*(.*)}) do |line|
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

      task :run_quality_assurance => in_namespace(:verify)
      task :run_continuous_integration => in_namespace(:verify)
    end
  end
end
