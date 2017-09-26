#Contributing

General Workflow

Fork the SBlink repo Add an upstream remote to SBlink repo When you've finished with your fix or feature, commit your changes to your forked copy of the repo After committing to your copy of the repo, pull upstream dev for potential merge conflicts Once you are certain that your commit does not have any conflicts, submit a pull request to the SBlink repo Detailed Workflow

Fork the repo and add an upstream remote

Use github’s interface to make a fork of the repo, then add that repo as an upstream remote:

git remote add upstream https://github.com/Se7enACK/SBlink.git Make commits to your feature repo.

Make changes and commits on the dev branch of your own copy of the repo.

Commit Message Guidelines

The first line of your commit message should be a brief summary of what the commit changes. Aim for about 70 characters max. Remember: This is a summary, not a detailed description of everything that changed. If you want to explain the commit in more depth, following the first line should be a blank line and then a more detailed description of the commit. This can be as detailed as you want, so dig into details here and keep the first line short. Pull Upstream changes into your branch

Once you are done pushing your changes to your own copy of the repo, you can begin the process of getting your code merged into the main repo. Step 1 is to pull upstream changes to the SBlink dev branch into yours by running this command from your branch:

git pull upstream dev You must commit all of your changes before doing this. Even if there are no conflicts, you should still be certain that your commit does not break any functionality of the site.

If there are conflicting changes, git will notify you. You should check all of the files git says have been changed in both histories and pick the versions you want.

Submit a pull request

Once you have done all of the above, submit a pull request to SBlink repo.

Someone will review your pull request, and it is a needed change, it will be merged.

Thanks for contributing!

Guidelines

Uphold the current code standard: Keep your code dry. Prioritize readability over cleverness. Your pull request is comprised of a single commit.
