require 'corundum/tasklib'
require 'yard/rake/yardoc_task'

module Corundum
  class YARDoc < TaskLib
    default_namespace :documentation

    setting(:gemspec)
    setting(:doc_dir, "rubydoc")
    setting(:files, nested(:code => [], :docs => []))

    def default_configuration(toolkit)
      self.gemspec = toolkit.gemspec
    end

    def define
      directory doc_dir

      in_namespace do
        YARD::Rake::YardocTask.new(:docs) do |rd|
          rd.options += gemspec.rdoc_options
          rd.options += ["--output-dir", doc_dir]
          rd.files += files.code
          rd.files += files.docs
          rd.files += gemspec.extra_rdoc_files
        end
      end

      desc "Generate documentation based on code using YARD"
      task root_task => in_namespace("docs")
    end
  end
end
