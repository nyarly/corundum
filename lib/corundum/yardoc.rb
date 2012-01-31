require 'corundum/tasklib'
require 'yard'

module Corundum
  class YARDoc < TaskLib
    default_namespace :documentation

    setting :gemspec
    setting :options, nil
    setting :browser
    setting :yardoc_index, nil

    setting(:target_dir, "yardoc")
    setting(:readme, nil)
    setting(:files, nested(:code => [], :docs => []))
    setting(:extra_files, [])

    def default_configuration(toolkit)
      self.gemspec = toolkit.gemspec
      toolkit.files.copy_settings_to(self.files)
      self.browser = toolkit.browser
    end

    def resolve_configuration
      self.options ||= gemspec.rdoc_options
      self.options += [ "--output-dir", target_dir]
      self.options += [ "--readme", readme ] if readme
      self.options += files.code
      unless files.docs.empty? and extra_files.empty?
        self.options += [ "-" ] + files.docs  + extra_files
      end
      self.yardoc_index ||= File::join(target_dir, "index.html")
    end

    def define
      directory target_dir

      in_namespace do
        file yardoc_index =>
        FileList["README*"] + files.code + files.docs + extra_files do
          YARD::CLI::Yardoc.run( *(options) )
        end

        desc "Open up a browser to view your documentation"
        BrowserTask.new(self) do |t|
          t.index_html = yardoc_index
        end
      end

      desc "Generate documentation based on code using YARD"
      task root_task => yardoc_index
    end
  end
end
