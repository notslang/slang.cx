# Pre-Commit Hooks are Almost Always a Bad Idea

Git provides a way to run [custom scripts](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) when certain events occur. One of these hooks is called `pre-commit` and some projects use it to run checks like formatting, linting, or even executing a test suite before a commit can be made.

This is a bad idea because you need to wait for those checks to finish before you can write your commit message and push your commit. This means interrupting your workflow to wait for the script to finish running. Plus, this script can take a non-trivial amount of time to finish. Formatting a large project can take several seconds and test suites can take even longer. That time spent waiting can be enough to break concentration and ruin developer experience.

This issue only gets more annoying if you make small and frequent commits because the pre-commit hook needs to run each time. Generally, making small commits is a good habit, but pre-commit hooks penalize you for it.

Of course, checks like formatting, linting, and running the test suite are valuable. However, it's better to run those on a CI server. With a CI server the checks will be run automatically after you write your commit message and push your commit, meaning it's not an interruption to your workflow. You can continue writing code while your commit is checked remotely.

CI has several advantages over pre-commit hooks too:

- CI will always run, whereas pre-commit hooks will only run if each contributor has installed them on their development machine.
- CI executes in a predictable environment with known versions of each package installed, guaranteeing consistency in the checks.

With a CI server, pre-commit hooks are unnecessary and redundant.

But what if you want to make sure that your code is formatted correctly before you commit it, so you don't have to amend your commits after they fail CI? There's a better solution for that too. Modern editors have support for automatically formatting and linting your code as you work on it. For example, there's [ale](https://github.com/dense-analysis/ale) for vim or the `formatOnSave` option in VSCode.

This type of in-editor formatting and linting happens asynchronously and only needs to run on the file that you're editing. This means that you don't need to wait for it to finish and it does not interrupt your workflow.

There are still a few cases where pre-commit hooks make sense:

- Maybe your project has no budget to run a CI server and cannot use a free one for some reason. If all you have is your development machine then maybe pre-commit hooks are your best option.
- Maybe your favorite editor has no support for automatic formatting or linting (like `vi` or `nano`) and you have no intention of switching to a modern editor. If that's the case then pre-commit hooks might be the easiest way to automatically run those checks.
- Maybe you're using a git repo for something other than code, like [pass](https://www.passwordstore.org/) or some type of flat-file database. If that's the case then a pre-commit hook probably isn't going to impede your workflow
