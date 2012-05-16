## Corundum
### Foolproof rubygems

With Corudum added as a developement dependancy to your gemspec, and configured
(quickly) in your Rakefile you can do:

    rake release

and know that you're publishing something you won't be embarrassed by.

### What is it?

Corundum is a set of Rake tasklibs built so that you can set up safeguards on
your gem deployment so that your deploys won't distress your users.

The tasklibs are built to be extremely flexible and terse, so that they can
conform to your build process, rather than the other way around.

### Why do I care?

Have you ever released a gem that:

* Didn't pass its own specs?
* Were poorly tested?
* Depended on gems that weren't released yet?
* Didn't include all their source files?
* Included tons of files that weren't actually part of the gem?
* Still had a p or debugger line hanging around?
* Weren't commited and pushed to github?
* Weren't tagged with their version on github?

If so, Corundum is for you.

Have you ever been irritated with a gem packaging system that

* Did the easy parts and left you to figure out the hard things?
* Imposed it's own ideas about how to organize your gem?
* Relied heavily on code generation?
* Wouldn't let you use Rake as it was intended?

If so, Corundum is for you.

[Learn more](http://nyarly.github.com/corundum/)
