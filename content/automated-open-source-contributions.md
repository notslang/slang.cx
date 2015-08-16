# Automated Open-Source Contributions
If you've spent any amount of time as a Wikipedian, you've likely come across the bots that the community uses to manage the site. They handle vandalism detection, spelling correction, migrations, creating new articles, and a slew of other tasks. These bots free human editors from needing to do simple tasks and (with the current size of the project) are essential to maintaining the wiki.

We can see a similar type of automation beginning to emerge on GitHub in the form of automated testing systems like [Travis CI](http://travis-ci.org/) & [Hound](https://houndci.com/). Of course, these aren't nearly as direct as the bots of Wikipedia - they merely run through commenting & notifying users of issues, rather than editing code directly.

In addition, there have been impressive efforts in language-wide automated refactoring through tools like [gofix](http://golang.org/cmd/fix/) & [gofmt](https://golang.org/cmd/gofmt/). These are, of course, specific to the Go language, but they've allowed users to automatically upgrade their code from old versions of the Go API (making deprecation less painful), and format their code to the Go standard (increasing the stylistic consistency among Go packages).

But I think that we have a lot of un-tapped potential for increasing automation within

## Why not in-editor tools?
I think that refactoring while writing code is vastly easier to work with than bots designed to scan open-source projects

...but we can't expect every contributor to have them installed & it's important for discovery

## A note about terms used
I mention GitHub specifically because it is, at the time of writing, the largest community for open-source software development, and is my social network of choice. However, there is no reason why bots would need to be tied specifically to GitHub. Any mass index of open-source projects that supports pull-requests would do.
