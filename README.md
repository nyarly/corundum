## Corundum
### Quickstart

The corundum-skel executable templates all the basic files necessary for building
a gem with corundum. It's cautious and will not overwrite existing files.


```
gem install corundum
cd my-new-rubygem
corundum-skel
rake -T
```

### Foolproof rubygems

With Corundum added as a developement dependency to your gemspec, and configured
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
* Didn't have decent public documentation?

If so, Corundum is for you.

Have you ever been irritated with a gem packaging system that

* Did the easy parts and left you to figure out the hard things?
* Imposed it's own ideas about how to organize your gem?
* Relied heavily on code generation?
* Wouldn't let you use Rake as it was intended?

If so, Corundum is for you.

[Learn more](http://nyarly.github.com/corundum/)

### Thanks

Corundum certainly wouldn't exist without seattlerb's Hoe.

Corundum's default documentation theme is lifted wholesale from Steve Smith's Modernizer theme for github pages.

Obviously, Bundler and Rubygems are a prerequisite, and the teams that works on them are pretty much amazing.

### Contributing

The decisions about what to support in Corundum have everything to do with my
personal dev environment (which might help explain the Montone version control
tasklib).  From the start, the idea has been to make changing out components
absurdly easy.  Legos stick together more than these things.  I'd love to see
an RCov tasklib, for instance, or a Minitest one.  Mercurial.

Make a pull request, and I'll get it merged.  If you're worried, we can talk it
out in Issues or email, and we can hash out the form of a pull request that
I'll commit to merging.

### License

MIT
