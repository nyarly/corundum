require 'corundum/tasklib'

module Corundum
  class DocumentationTask < TaskLib
    setting :title
    setting :browser

    setting :corundum_dir
    setting :docs_root

    setting :target_dir
    setting :sub_dir

    setting :entry_file, "index.html"
    setting :entry_path
    setting :entry_link

    # docsroot | subdir | entry_file

    # docsroot + subdir => target_dir
    # subdir + entry_file => entry_link
    # target_dir + entryfile => entry_file

    def self.title(name)
      setting :title, name
    end

    def default_configuration(toolkit)
      toolkit.copy_settings_to(self)
    end

    def resolve_configuration
      if unset?(docs_root)
        self.docs_root = File::join(corundum_dir, "docs")
      end

      if unset?(target_dir)
        self.target_dir = File::join(docs_root, sub_dir)
      else
        self.sub_dir = target_dir.sub(/^#{docs_root}\//,"")
      end

      if unset?(entry_path)
        self.entry_path = File::join(target_dir, entry_file)
      end

      if unset?(entry_link)
        self.entry_link = File::join(sub_dir, entry_file)
      end
    end

    def entry_point(under = nil)
      File::join(under || target_dir, entry_file)
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
end
