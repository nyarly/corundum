require 'mattock/tasklib'

module Corundum
  class GemBuilding < Mattock::TaskLib
    setting(:gemspec)
    setting(:package)
    setting(:qa_file)

    def default_configuration(toolkit)
      super
      toolkit.copy_settings_to(self)
    end

    def define
      require 'rubygems/package_task'

      in_namespace do
        Gem::PackageTask.new(gemspec) do |t|
          t.need_tar_gz = true
          t.need_tar_bz2 = true
          t.package_dir = package.abspath
        end

        task(:package).prerequisites.each do |package_type|
          file package_type => qa_file
        end
      end

      task :build => in_namespace("gem")
    end
  end
end
