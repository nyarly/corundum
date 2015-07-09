# vim: set ft=ruby :
require 'corundum/tasklibs'

# This Rakefile makes use of the Corundum tasklibs to parameterize lots and
# lots of tasks to build your gem. Most of this is (minimal) boilerplate, but
# there are some places where you can configure exactly how the tasks should
# work.
#
# If you haven't seen the pattern before, simply instantiating the tasklib
# class (i.e. SomeTasklib.new) is enough to create all the tasks it's
# responsible for. If you do need to configure a tasklib, you can give ::new a
# block which will receive the tasklib to configure. c.f. QuestionableContent
# for an example.
#
# (Further docs for all the Corundum tasklibs will be coming to an Internet
# near you real soon now.)
module Corundum
  Corundum::register_project(__FILE__)

  # The Core tasklib coordinates the other tasks. Generally it doesn't need any
  # configuration.
  core = Core.new

  core.in_namespace do
    # The GemspecFiles tasklib is responsible for checking that all the files
    # necessary for your gem are listed in the Gemfile. Usually you don't need
    # to add any configuration. Of note is the "extra_files" configuration - a
    # list of files that need to be included but that Corundum might not be
    # able to detect on its own.
    GemspecFiles.new(core)

    # QuestionableContent searches codefiles for words (especially in comments)
    # that you might not want going out into the world. Note that QC is added 4
    # times by default with different types of text.
    #
    # If QC is wrong about something (e.g. there's a completely legitimate
    # reason that 'p' appears on a line) You can tag the line with an '#ok'
    # comment to have QC ignore it.

    # This default checks for unacceptable language (of both the profanity
    # and -ism varieties) before release, as well as debugging statements
    # like debugger, byebug, puts, p, etc. accidentally left in the code.
    #
    # Also available: 'unfinished': TODO and XXX
    ["debug", "profanity", "ableism", "racism"].each do |type|
      QuestionableContent.new(core) do |content|
        content.type = type
      end
    end

    # Corundum won't let you release a gem where any tests fail. By default, it
    # assumes RSpec is used to test the project (alternative implementations
    # are anxiously encouraged!)
    rspec = RSpec.new(core)

    # To make sure that tests don't just pass because they're incomplete,
    # Corundum also requires a coverage threshold, which we measure with
    # Simplecov.  Coverage also figures into how we determine that files should
    # be in the gemspec (covered files should be included, and included files
    # should be covered)
    SimpleCov.new(core, rspec) do |cov|
      cov.threshold = 85
    end

    # The tasks to actually take code + gemspec and package into a gem. All its
    # configuration should be determined by the gemspec itself.
    gem = GemBuilding.new(core)

    # Tasks for uploading gems to rubygems.com - called GemCutter for
    # historical reasons.
    GemCutter.new(core,gem)

    # We require that the code for a gem be pushed before releasing, and tag
    # the branch with the version of the gem automatically. Corundum assumes
    # Git for version control - alternatives encouraged.
    Git.new(core) do |vc|
      vc.branch = "master"
    end
  end
end

task :default => [:release]
