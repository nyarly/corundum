require 'mattock/tasklib'

module Corundum
  class DocumentationTask < Mattock::TaskLib
    setting :title
    setting :browser
    setting :gemspec

    dir(:corundum_dir,
        dir(:docs_root, "docs",
            dir(:target_dir,
               path(:entry_path, "index.html"))))

    #The URL path from this documentation root
    #Resolves if unset to sub_dir + entry_file
    setting :entry_link

    def self.title(name)
      setting :title, name
    end

    def default_configuration(toolkit)
      super
      toolkit.copy_settings_to(self)
    end

    def resolve_configuration
      super

      if field_unset?(:entry_link)
        self.entry_link = File::join(target_dir.relpath, entry_path.relpath)
      end

      resolve_paths
    end

    def entry_point
      entry_path.abspath
    end

    def define
      directory target_dir.abspath

      in_namespace do
        desc "Open up a browser to view your documentation"
        BrowserTask.define_task(self) do |t|
          t.index_html = entry_point
        end
      end
    end
  end
end
