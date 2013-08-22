require 'corundum/documentation-task'
require 'corundum/rspec-task'

module Corundum
  class RSpec < DocumentationTask
    default_namespace :rspec
    title "RSpec run output"

    settings(
      :qa_rejections => nil,
      :sub_dir => "rspec",
      :pattern => './spec{,/*/**}/*_spec.rb',
      :rspec_opts => nil,
      :warning => false,
      :verbose => true,
      :ruby_opts => [],
      :rspec_path => 'rspec',
      :rspec_opts => [],
      :failure_message => "Spec examples failed.",
      :files_to_run => "spec"
    )

    required_fields :gemspec_path, :qa_finished_path, :file_lists, :file_dependencies

    def default_configuration(toolkit)
      super
      self.qa_finished_path = toolkit.finished_files.qa
      self.qa_rejections = toolkit.qa_rejections
    end

    def resolve_configuration
      #XXX Que?
      self.rspec_path = %x"which #{rspec_path}".chomp
      self.file_dependencies = file_lists.code + file_lists.test + file_lists.project
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
        doc_task(:doc) do |t|
          t.rspec_opts = %w{-o /dev/null --failure-exit-code 0 -f h -o} + [t.doc_path]
        end
        file entry_path => :doc

        task :verify => :doc do |task|
          require 'nokogiri'
          require 'corundum/qa-report'

          doc = Nokogiri::parse(File::read(entry_path))

          rejections = QA::Report.new("RSpec")
          qa_rejections << rejections

          def class_xpath(name)
            "contains(concat(' ', normalize-space(@class), ' '), '#{name}')"
          end

          fails_path = "//*[" + %w{example failed}.map{|kind| class_xpath(kind)}.join(" and ") + "]"
          doc.xpath(fails_path).each do |node|
            backtrace_line = node.xpath(".//*[#{class_xpath("backtrace")}]").contents.split("\n").last
            file,line,_ = backtrace_line.split(":")
            label = "fail"
            value = node.xpath(".//[#{class_xpath("message")}]").contents.gsub(/\s+/m, " ")

            rejections.add(label, file, line, value)
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

      task :qa => in_namespace(:verify)
    end
  end
end
