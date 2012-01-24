require 'corundum/tasklib'
require 'yard'

module Corundum
  class YARDoc < TaskLib
    default_namespace :documentation

    setting :gemspec
    setting :options, nil

    setting(:doc_dir, "doc")
    setting(:readme, "README")
    setting(:files, nested(:code => [], :docs => [], :all => nil))

    def default_configuration(toolkit)
      self.gemspec = toolkit.gemspec
    end

    def resolve_configuration
      self.options ||= gemspec.rdoc_options +
        [ "--output-dir", doc_dir,
          "--readme", readme ]
      self.files.all ||= files.code + files.docs
    end

    def define
      directory doc_dir

      in_namespace do
        task :generate do
          YARD::CLI::Yardoc.run( *(options + files.all))
        end
      end

      desc "Generate documentation based on code using YARD"
      task root_task => in_namespace("generate")
    end
  end
end
