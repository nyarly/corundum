## Corundum
### Foolproof rubygems

With Corudum added as a developement dependancy to your gemspec, and configured
(quickly) in your Rakefile you can do:

    rake release

and know that you're publishing something you won't be embarrassed by.

### (Yet Another Rubygems packager)

Why is Corundum different from Jeweler or Hoe?  (or...) Corundum is built not
to generate code - it doesn't exist to build gems for you if you don't know
how.  For that, check out Jeweler, and come back once you've understood what a
.gemspec is and how it works.

Really, writing a gem is pretty easy - you can do it in a gist if you want.  And releasing Gems isn't all that hard either - rubygems has good tools to package up gems and push them to gem servers.  So why Corundum?

Because releasing a gem that will actually help the Ruby community at large is
actually quite difficult.  There are lot of fiddly details to get wrong, and
even experienced devs can be doofuses sometimes.  Corundum serves as a
collection of safeguards against common errors in releasing gems - certainly
every one that's happened to me.

### Using Corundum

In your coolgem.gemspec:

    spec.add_development_dependency "corundum"

In you Gemfile:

    gemspec

(But you were doing that anyway, right?)

Check out this Rakefile:

    require 'corundum/tasklibs'

    module Corundum
      tk = Toolkit.new do |tk|
      end

      tk.in_namespace do
        sanity = GemspecSanity.new(tk)
        rspec = RSpec.new(tk)
        cov = SimpleCov.new(tk, rspec) do |cov|
          cov.threshold = 55
        end
        gem = GemBuilding.new(tk)
        cutter = GemCutter.new(tk,gem)
        email = Email.new(tk)
        vc = Git.new(tk) do |vc|
          vc.branch = "master"
        end
        task tk.finished_files.build => vc["is_checked_in"]
        docs = YARDoc.new(tk) do |yd|
          yd.extra_files = ["Rakefile"]
        end
        pages = GithubPages.new(docs)
      end
    end

That's the whole thing.  Now 'rake release' will push the current version of
the gem, but only if we can go through a complete a correct QA process.
(Incidentally, that's the Rakefile for Corundum itself.)

The other goal with Corundum is to present all of these tools as
configurable Tasklibs, so the power of Rake remains available.  If you want
to do

    task :default => :release

Then 'rake' will do your releases.
