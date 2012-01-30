## Corundum
### Foolproof rubygems

#### (Yet Another Rubygems packager)

Why is Corundum different from Jeweler or Hoe?  (or...) Corundum is built not
to generate code - it doesn't exist to build gems for you if you don't know
how.  For that, check out Jeweler, and come back once you've understood what a
.gemspec is and how it works.

The goal of Corundum is to be able to run 'rake release' and know that
you're publishing something you won't be embarrassed by.  Any packaging is a
tricky problem with lots of details.  Fortunately, those details can mostly
be automated.

#### Using Corundum

Check out this Rakefile:

{include:file:Rakefile.rb}

That's the whole thing.  'rake release' will push the current version of the
gem, but only if we can go through a complete a correct QA process.
(Incidentally, that's the Rakefile for Corundum itself.)

The other goal with Corundum is to present all of these tools as
configurable Tasklibs, so the power of Rake remains available.  If you want
to do

    task :default => :release

Then 'rake' will do your releases.
