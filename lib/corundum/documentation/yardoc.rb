require 'corundum/documentation-task'
require 'yard'

module Corundum
  class YARDoc < DocumentationTask
    title "YARD API documentation"
    default_namespace :yardoc

    setting :gemspec

    settings(:options =>  nil,
             :readme =>  nil,
             :sub_dir =>  "yardoc",
             :files =>  nested(:code => [], :docs => []),
             :extra_files =>  [] )

    def document_inputs
      FileList["README*"] + files.code + files.docs + extra_files
    end

    def default_configuration(toolkit)
      super
      self.gemspec = toolkit.gemspec
      toolkit.files.copy_settings_to(self.files)
      self.files.docs = []
    end

    def resolve_configuration
      self.options ||= gemspec.rdoc_options
      self.options += [ "--readme", readme ] if readme
      self.options += files.code
      unless files.docs.empty? and extra_files.empty?
        self.options += [ "-" ] + files.docs  + extra_files
      end
      super
      self.options += [ "--output-dir", target_dir]
    end

    def define
      in_namespace do
        file entry_point => document_inputs do
          YARD::CLI::Yardoc.run( *(options) )
        end
      end

      super
    end
  end
end
