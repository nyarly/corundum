require 'compass'
require 'corundum/documentation-task'

module Corundum
  class DocumentationAssembly < DocumentationTask

    title 'Assembled Documentation'

    dir(:assembly_sub, "doc_assembly",
        dir(:theme_dir, "theme",
            dir(:theme_sass, "sass",
               path(:root_stylesheet, "styles"))),
        path(:index_source, "index.html"))

    dir(:target_dir, path(:stylesheet, "stylesheet.css"))

    setting :templates

    setting :documenters, []
    setting :extra_data, {}
    setting :external_docs, {}
    setting :css_dir, "stylesheets"
    setting :compass_config, nested(
      :http_path => "/",
      :line_comments => false,
      :preferred_syntax => :scss,
      :http_stylesheets_path => nil,
      :project_path => nil,
      :images_dir => 'images',
    )

    def default_configuration(toolkit, *documenters)
      super(toolkit)
      self.documenters = documenters

      target_dir.relative_path = "assembled"

      self.compass_config.http_stylesheets_path = css_dir
    end

    def resolve_configuration
      super
      assembly_sub.absolute_path = assembly_sub.relative_path

      resolve_paths

      if field_unset?(:templates)
        self.templates = Corundum::configuration_store.valise.templates do |mapping|
          case mapping
          when "sass", "scss"
            valise = Corundum::configuration_store.valise
            options =
              if Compass.respond_to? :sass_engine_options
                Compass.sass_engine_options
              else
                require 'compass/core'
                { :load_paths => [Compass::Core.base_directory("stylesheets")] }
              end
            options[:load_paths] = valise.sub_set("templates").map(&:to_s) + options[:load_paths]
            { :template_options => options }
          else
            nil
          end
        end
      end

      self.compass_config.project_path = templates.find("doc_assembly/theme").full_path

      self.documenters = documenters.each_with_object({}) do |doccer, hash|
        hash[File::join(target_dir.abspath, doccer.target_dir.relpath)] = doccer
      end
      if field_unset?(:stylesheet)
        self.stylesheet = File::join(target_dir.abspath, "stylesheet.css")
      end

    end


    def define
      in_namespace do
        subdir_regex = %r{^#{File::expand_path(target_dir.abspath)}}

        documenters.each_pair do |subdir, doccer|
          file subdir => [target_dir.abspath, doccer.entry_point] do
            if subdir_regex =~ File::expand_path(doccer.target_dir.abspath)
              fail "Documentation being rendered to #{doccer.target_dir.abspath}, inside of #{target_dir.abspath}"
            end

            FileUtils.rm_rf(subdir)
            FileUtils.mv(doccer.target_dir.abspath, subdir)
          end
        end

        task :collect => documenters.keys

        file stylesheet.abspath => [target_dir.abspath] do |task|
          template = templates.find(root_stylesheet.abspath).contents
          File::open(task.name, "w") do |file|
            file.write(template.render(nil, nil))
          end
        end

        file entry_point => [stylesheet.abspath, target_dir.abspath, :collect] do |task|
          template = templates.find(index_source.abspath).contents
          File::open(task.name, "w") do |file|
            file.write(template.render(self, {}))
          end
        end
      end
      super
    end
  end
end
