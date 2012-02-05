require 'corundum/tasklib'
require 'corundum/configuration_store'

#require 'rubygems'
#require 'rubygems/installer'

module Corundum
  extend Rake::DSL

  class Toolkit < TaskLib
    settings(
      :gemspec => nil,
      :gemspec_path => nil,
      :corundum_dir => "corundum",
      :finished_dir => nil,
      :package_dir => "pkg",
      :doc_dir => "rubydoc",
      :browser => Corundum.user_preferences["browser"],
      :finished_files => nested.nil_fields(:build, :qa, :package, :release, :press),
      :files => nested.nil_fields(:code, :test, :docs),
      :rubyforge => nested.nil_fields(:group_id, :package_id, :release_name, :home_page, :project_page),
      :email => nested(
        :servers => [ nested({ :server => "ruby-lang.org", :helo => "gmail.com" }) ],
        :announce_to_email => "ruby-talk@ruby-lang.org"
    ),
      :file_lists => nested(:code => FileList['lib/**/*.rb'],
                            :test => FileList['test/**/*.rb','spec/**/*.rb','features/**/*.rb'],
                            :docs => FileList['doc/**/*.rb'],
                            :project => FileList['Rakefile'],
                            :all => nil)
    )

    def load_gemspec
      @gemspec_path ||= guess_gemspec
      @gemspec ||= Gem::Specification::load(gemspec_path)
      return gemspec
    end

    def resolve_configuration
      load_gemspec

      self.finished_dir ||= File::join(corundum_dir, "finished")
      @finished_files.build ||= File::join( package_dir, "#{gemspec.full_name}.gem")

      @finished_files.qa ||= File::join( finished_dir, "qa_#{gemspec.version}")
      @finished_files.release ||= File::join( finished_dir, "release_#{gemspec.version}")
      @finished_files.press ||= File::join( finished_dir, "press_#{gemspec.version}")

      @files.code ||= gemspec.files.grep(%r{^lib/})
      @files.test ||= gemspec.files.grep(%r{^spec/})
      @files.docs ||= gemspec.files.grep(%r{^doc/})

      @file_lists.project << gemspec_path
      @file_lists.all  ||=
        file_lists.code +
        file_lists.test +
        file_lists.docs

      @rubyforge.group_id ||= gemspec.rubyforge_project
      @rubyforge.package_id ||= gemspec.name.downcase
      @rubyforge.release_name ||= gemspec.full_name
      @rubyforge.home_page ||= gemspec.homepage
      @rubyforge.project_page ||= "http://rubyforge.org/project/#{gemspec.rubyforge_project}/"
    end

    def guess_gemspec
      speclist = Dir[File.expand_path("*.gemspec", Rake::original_dir)]
      if speclist.length == 0
        puts "Found no *.gemspec files"
        exit 1
      elsif speclist.length > 1
        puts "Found too many *.gemspec files: #{speclist.inspect}"
        exit 1
      end
      speclist[0]
    end

    def define
      in_namespace do
        directory finished_dir

        desc "Run preflight checks"
        task :preflight

        desc "Run quality assurance tasks"
        task :qa => [:preflight, finished_files.qa]
        file finished_files.qa =>
        [finished_dir] + file_lists.project + file_lists.code + file_lists.test do |task|
          Rake::Task[:qa].invoke #because I don't want this to be needed if it's not
          touch task.name
        end

        desc "Build the package"
        task :build => [finished_files.qa, :preflight, finished_files.build]
        file finished_files.build =>
        [finished_dir] + file_lists.code + file_lists.project do |task|
          Rake::Task[:build].invoke
          touch task.name
        end

        desc "Push package out to the world"
        task :release => [finished_files.build, :preflight, finished_files.release]
        file finished_files.release => [finished_dir] do |task|
          Rake::Task[:release].invoke
          touch task.name
        end

        desc "Announce publication"
        task :press => [finished_files.release, finished_files.press]
        file finished_files.press => [finished_dir] do |task|
          Rake::Task[:press].invoke
          touch task.name
        end
      end
    end
  end
end
