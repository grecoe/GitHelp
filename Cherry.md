# Cherry options


#### Find the commits that are in grecoe/test that are not in grecoe/test2

This will show you all of the commits that were done on /test that are not in Test2

```bash
git cherry -v grecoe/test2 grecoe/test
```

### Cherry pick something from one branch

You add a file to the repo but don't add it in git yet, but you want a change from another branch.

You can pick which changes you want from another branch using the commit hash, this will bring over the second change. 

```bash
git cherry -v grecoe/test2 grecoe/test
+ 57b7ba300569ec90df40c0faf5744a98a4596b2b Hello
+ 1af04c95074176597d512df566b8216cf939ce82 This is the second change

git cherry-pick 1af04c95074176597d512df566b8216cf939ce82
```

### Now lets say you want to get rid of the cherry-pick 

- First add your local changes, but don't commit.
- Run the following to stash your changes, reset to head, and reapply your local change

```bash
git stash
$ git reset --hard HEAD^
$ git stash 
```

### TO see the commits on the current branch that are only specific to that branch

```bash
git log master..

OR

git -v cherry master
```

### Trying to remove a single change

You use rebase see [this page](https://graphite.dev/guides/how-to-delete-a-git-commit)

Include enough history to get the changes, an editor opens in code and you can make changes there. 

```bash
git rebase -i HEAD~4
```