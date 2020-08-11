# GIT Help

## Create new Feature branch and push to GitHub
```
$ git checkout -b Feature1

$ git push origin Feature1
```

# Now create a Dev branch on the Feature branch
```
$ git checkout Feature1
$ git checkout -b Dev1 Feature1
```

## A. Do work in Dev1 and move it to github for a PR
```
# While on the Dev1 branch
$ git commit -am "First developer update to feature"
$ git push -u origin Dev1
```

## B. Do work in Dev1 then move those into Feature1
```
# While on the Dev1 branch
$ git commit -am "First developer update to feature"

# Now merge your changes to Feature1 without a fast-forward
$ git checkout Feature1
$ git merge --no-ff Dev1

```

## Changes in Feature1 branch to roll down to Dev1
```
$ git checkout Dev1
$ git merge --no-ff Feature1
```

## Now push the changes back out to GitHub
```
$ git push origin Feature1
$ git push origin Dev1
```


## Delete a branch
```
#Delete a branch on your local filesystem :
$ git branch -d Dev1

# To force the deletion of local branch on your filesystem :
$ git branch -D [name_of_your_new_branch]

#Delete the branch on github :
$ git push origin :[name_of_your_new_branch]
```

## Remote Branches

Clone the repo
```
$ git clone git://example.com/myproject
$ cd myproject
```

Look at all the branches
```
$ git branch -a
* master
  remotes/origin/HEAD
  remotes/origin/master
  remotes/origin/v1.0-stable
  remotes/origin/experimental
```

To work on a remote branch
```
$ git checkout experimental
```

That last line throws some people: "New branch" - huh? What it really means is that the branch is taken from the index and created locally for you. The previous line is actually more informative as it tells you that the branch is being set up to track the remote branch, which usually means the origin/branch_name branch

Now, if you look at your local branches, this is what you'll see:

```
$ git branch
* experimental
  master
```