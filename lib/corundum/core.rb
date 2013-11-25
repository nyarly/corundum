require 'corundum'
require 'mattock/tasklib'

module Corundum
  #This is the core tasklib for Corundum.  It defines a series of lifecycle
  #steps that define the release process.  The real work is done by other
  #Tasklibs that hook into the lifecycle.
  #
  #The lifecycle steps (as implied by the Rakefile definition) are:
  #
  #[ preflight ] simple tests before we do anything at all
  #[ qa ]
  #    quality assurance - make sure everything is acceptable
  #    before we build the gem
  # [build] construct the actual gem
  # [release] push the gem out to the world
  # [press] send out notifications that the gem has been published
  class Core < Mattock::TaskLib
    settings(
      :gemspec => nil,
      :gemspec_path => nil,
      :corundum_dir => "corundum",
      :finished_dir => nil,
      :package_dir => "pkg",
      :doc_dir => "rubydoc",
      :qa_rejections => nil,
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
                            :all => nil),
      :file_patterns => nested( :code => [%r{^lib/}], :test => [%r{^spec/}, %r{^test/}], :docs => [%r{^doc/}])
    )

    def load_gemspec
      @gemspec_path ||= guess_gemspec
      @gemspec ||= Gem::Specification::load(gemspec_path)
      return gemspec
    end

    def resolve_configuration
      super
      load_gemspec

      self.finished_dir ||= File::join(corundum_dir, "finished")
      @finished_files.build ||= File::join( package_dir, "#{gemspec.full_name}.gem")

      @finished_files.qa ||= File::join( finished_dir, "qa_#{gemspec.version}")
      @finished_files.release ||= File::join( finished_dir, "release_#{gemspec.version}")
      @finished_files.press ||= File::join( finished_dir, "press_#{gemspec.version}")

      @qa_rejections ||= []

      @files.code ||= file_patterns.code.map{ |pattern| gemspec.files.grep(pattern) }.flatten
      @files.test ||= file_patterns.test.map{ |pattern| gemspec.files.grep(pattern) }.flatten
      @files.docs ||= file_patterns.docs.map{ |pattern| gemspec.files.grep(pattern) }.flatten

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

        task :run_quality_assurance => [:preflight, finished_files.qa]

        task :run_continuous_integration

        desc "Run quality assurance tasks"
        task :qa => :run_quality_assurance do
          require 'corundum/qa-report'
          puts QA::ReportFormatter.new(qa_rejections).to_s
          unless qa_rejections.all?(&:passed)
            fail "There are QA tests that failed"
          end
        end

        desc "Run limited set of QA tasks appropriate for CI"
        task :ci => :run_continuous_integration do
          require 'corundum/qa-report'
          puts QA::ReportFormatter.new(qa_rejections).to_s
          if qa_rejections.all?(&:passed)
            puts "Passed"
          else
            fail "There are Continuous Integration tests that failed"
          end
        end


        file finished_files.qa =>
        [finished_dir] + file_lists.project + file_lists.code + file_lists.test do |task|
          Rake::Task[:qa].invoke
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

  #deprecated name for Core
  Toolkit = Core
end
