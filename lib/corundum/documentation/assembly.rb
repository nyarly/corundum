require 'corundum/documentation-task'
require 'mattock/template-host'
require 'compass'

module Corundum
  class DocumentationAssembly < DocumentationTask
    include Mattock::TemplateTaskLib

    title 'Assembled Documentation'

    setting :sub_dir, "assembled"
    setting :documenters, []
    setting :extra_data, {}
    setting :external_docs, {}
    setting :stylesheet
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
      self.valise = Corundum::configuration_store.valise

      self.compass_config.http_stylesheets_path = css_dir
      self.compass_config.project_path = template_path("doc_assembly/theme")
    end

    def resolve_configuration
      super
      self.documenters = documenters.each_with_object({}) do |doccer, hash|
        hash[File::join(target_dir, doccer.sub_dir)] = doccer
      end
      if unset?(stylesheet)
        self.stylesheet = File::join(target_dir, "stylesheet.css")
      end
    end


    def define
      in_namespace do
        subdir_regex = %r{^#{File::expand_path(target_dir)}}

        documenters.each_pair do |subdir, doccer|
          file subdir => [target_dir, doccer.entry_point] do
            if subdir_regex =~ File::expand_path(doccer.target_dir)
              fail "Documentation being rendered to #{doccer.target_dir}, inside of #{target_dir}"
            end

            FileUtils.rm_rf(subdir)
            FileUtils.mv(doccer.target_dir, subdir)
          end
        end

        #Colision of doc groups
        task :collect => documenters.keys

        task :setup_compass do
          Compass.add_configuration(compass_config.to_hash, __FILE__)
        end

        template_task("doc_assembly/stylesheet.scss", stylesheet, Compass.sass_engine_options)
        file stylesheet => [:setup_compass, target_dir]

        template_task("doc_assembly/index.html.erb", entry_point)
        file entry_point => [stylesheet, target_dir, :collect]
      end
      super
    end
  end
end
