require 'mattock/tasklib'

module Corundum
  class GemBuilding < Mattock::TaskLib
    setting(:gemspec)
    setting(:qa_finished_file)
    setting(:package_dir, "pkg")

    def default_configuration(toolkit)
      self.gemspec =  toolkit.gemspec
      self.qa_finished_file =  toolkit.finished_files.qa
    end

    def define
      require 'rubygems/package_task'

      in_namespace do
        package = Gem::PackageTask.new(gemspec) do |t|
          t.need_tar_gz = true
          t.need_tar_bz2 = true
          t.package_dir = package_dir
        end

        task(:package).prerequisites.each do |package_type|
          file package_type => qa_finished_file
        end
      end

      task :build => in_namespace("gem")
    end
  end
end
