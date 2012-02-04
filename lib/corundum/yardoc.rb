require 'corundum/tasklib'
require 'yard'

module Corundum
  class DocumentationTask < TaskLib
    setting :entry_point
    setting :target_dir
    setting :browser

    def default_configuration(toolkit)
      self.browser = toolkit.browser
    end

    def resolve_configuration
      self.entry_point ||= File::join(target_dir, "index.html")
    end

    def define
      directory target_dir

      in_namespace do
        desc "Open up a browser to view your documentation"
        BrowserTask.new(self) do |t|
          t.index_html = entry_point
        end
      end

      desc "Generate documentation based on code using YARD"
      task root_task => entry_point
    end
  end

  class YARDoc < DocumentationTask
    default_namespace :yardoc

    setting :gemspec
    setting :options, nil
    setting :entry_point, nil

    setting(:target_dir, "yardoc")
    setting(:readme, nil)
    setting(:files, nested(:code => [], :docs => []))
    setting(:extra_files, [])

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
      self.options += [ "--output-dir", target_dir]
      self.options += [ "--readme", readme ] if readme
      self.options += files.code
      unless files.docs.empty? and extra_files.empty?
        self.options += [ "-" ] + files.docs  + extra_files
      end
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
