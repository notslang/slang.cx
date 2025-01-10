# Should I Merge One Feature Branch Into Another Feature Branch?

No. The answer is no.

## Background

Sometimes, when working on a team, one developer will start working on a feature. His branch is named `my-cool-feature`. Then a second developer will start working on another feature that depends upon the work of the first developer. Their branch is named `cool-feature-extended` and it branches off of `my-cool-feature`.

Feature branches that branch off of other feature branches are fine. They're commonly used to create stacked PRs.

![branch diagram showing both branches](/merging-into-a-feature-branch-1.svg)

When the work is done, you may be tempted to merge `cool-feature-extended` into `my-cool-feature`, then merge `my-cool-feature` into `master`. This gets all the commits from both branches into `master`, and on a small enough team it can work just fine.

![branch diagram showing branches merged](/merging-into-a-feature-branch-2.svg)

However, in a world where other people are merging into develop, human code reviews are required, and merge conflicts happen, this process causes problems.

## Double Reviewing

If your team has a code review process, then they'll probably want to review both `my-cool-feature` and `cool-feature-extended`.

Lets say `cool-feature-extended` gets reviewed first, and then it gets merged. Now the `my-cool-feature` contains a mix of reviewed and unreviewed code and the whole thing needs to be reviewed again, possibly by a different set of people, depending on your code review process. Also, now the `my-cool-feature` branch is even larger, meaning it will take longer to review.

What if you don't review `cool-feature-extended`, merge it into `my-cool-feature`, and then let the reviewers of `my-cool-feature` review all the code? That gets rid of the duplicated work, but now if there's a review issue that gets found in the `cool-feature-extended` work, the developer of `my-cool-feature` needs to deal with it, and it's not even code that he wrote.

What about the opposite order? Maybe `my-cool-feature` gets reviewed first, then `cool-feature-extended` gets reviewed and merged into `my-cool-feature`. Now either the people who have reviewed `my-cool-feature` will be asked to re-review the whole PR (if your reviews reset on push) or they will be marked as having signed off on code that they haven't looked at.

You could get around this by having the same people review both PRs in the parent-then-child without resetting reviews on push. However, that requires careful planning and at that point you're treating it like one big PR.

## Merge Conflict Hell

You've now gotten through reviews and all the code from both braches is approved and merged into the `my-cool-feature` branch. You're all ready to merge your PR. But wait, what's that? The "Merge pull request" button is greyed out. Someone else's work has been merged into `master` and it conflicts with your PR. Not a surprise given how large your changes have gotten.

Now you either have to rebase or resolve a merge conflict. However, half of the code in this PR isn't even code that you wrote because it was merged in from `cool-feature-extended`, so you're resolving conflicts on code that you haven't even worked with. This is merge conflict hell.

## Alternatives

The first and best alternative is to break up work so developers are not dependent upon each other. If you're following the [INVEST](https://en.wikipedia.org/wiki/INVEST_%28mnemonic%29) criteria, your backlog items should often be independent. If you can structure backlog items that are independent, then `cool-feature-extended` might not need to branch off of `my-cool-feature` at all. They can be worked on in different sprints, or in parallel without relying on each other.

The second alternative is to merge each branch separately. First, get code review on `my-cool-feature` and merge it into `master`. Then rebase `cool-feature-extended` on `master`, get it reviewed, then merge `cool-feature-extended` into `master`. This will give you the same result, but you're only merging a small chunk of work each time and there's no wasted effort on reviews.

![branch diagram showing branches merged](/merging-into-a-feature-branch-3.svg)
