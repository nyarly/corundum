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
    dir(:package, "pkg",
        path(:build_file))

    dir(:corundum_dir, "corundum",
        dir(:finished_dir, "finished",
            path(:qa_file), path(:release_file)))

    settings(
      :gemspec => nil,
      :gemspec_path => nil,
      :qa_rejections => nil,
      :browser => Corundum.user_preferences["browser"],
      :files => nested.nil_fields(:code, :test, :docs),
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

    def resolve_configuration
      super

      self.gemspec_path ||= guess_gemspec
      self.gemspec ||= Gem::Specification::load(gemspec_path)

      self.qa_rejections ||= []

      build_file.relative_path ||= gemspec.full_name + ".gem"
      qa_file.relative_path ||= "qa-" + gemspec.version.to_s
      release_file.relative_path ||= "release-" + gemspec.version.to_s

      resolve_paths

      self.files.code ||= file_patterns.code.map{ |pattern| gemspec.files.grep(pattern) }.flatten
      self.files.test ||= file_patterns.test.map{ |pattern| gemspec.files.grep(pattern) }.flatten
      self.files.docs ||= file_patterns.docs.map{ |pattern| gemspec.files.grep(pattern) }.flatten

      self.file_lists.project << gemspec_path
      self.file_lists.all  ||=
        file_lists.code +
        file_lists.test +
        file_lists.docs
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
        directory finished_dir.abspath

        desc "Run preflight checks"
        task :preflight

        task :run_quality_assurance => [ :preflight, qa_file.abspath ]

        task :run_continuous_integration

        desc "Run quality assurance tasks"
        qa_task = task :qa => :run_quality_assurance do
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

        file qa_file.abspath =>
        [finished_dir.abspath] + file_lists.project + file_lists.code + file_lists.test do |task|
          qa_task.invoke
          touch task.name
        end

        desc "Build the package"
        build_task = task :build => [qa_file.abspath, :preflight, build_file.abspath]
        file build_file.abspath =>
        [finished_dir.abspath] + file_lists.code + file_lists.project do |task|
          build_task.invoke
          puts "\n#{__FILE__}:#{__LINE__} => #{task.name.inspect}"
          touch task.name
        end

        desc "Push package out to the world"
        release_task = task :release => [ build_file.abspath, :preflight, release_file.abspath ]
        file release_file.abspath => [ finished_dir.abspath ] do |task|
          release_task.invoke
          touch task.name
        end
      end
    end
  end

  #deprecated name for Core
  Toolkit = Core
end
