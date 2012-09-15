module Corundum
  class SkelFiles < Mattock::Tasklib
    default_namespace :skel_files

    def define
      in_namespace do
        Corundum::configuration_store.files.each do |item|
          next unless item.segments[0] == 'skel-files'

          desc "Outputs suggested contents for #{item.segments[1]}"
          task item.segments[1] do |task|
            puts item.contents
          end
        end
      end
    end
  end
end
