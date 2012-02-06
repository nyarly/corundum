require 'corundum/documentation-task'
require 'mattock/template-host'

module Corundum
  class DocumentationAssembly < DocumentationTask
    include Mattock::TemplateHost

    title 'Assembled Documentation'

    setting :sub_dir, "assembled"
    setting :documenters, []
    setting :extra_data, {}

    def default_configuration(toolkit, *documenters)
      super(toolkit)
      self.documenters = documenters
      self.valise = Corundum::configuration_store.valise
    end

    def resolve_configuration
      super
      self.documenters = documenters.each_with_object({}) do |doccer, hash|
        hash[File::join(target_dir, doccer.sub_dir)] = doccer
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

        desc "Generate various documentation and collect it in one place"
        file entry_point => [target_dir, :collect] do
          File::open(entry_point, "w") do |file|
            file.write(render("doc_assembly/index.html.erb"))
          end
        end
      end
      super
    end
  end
end
