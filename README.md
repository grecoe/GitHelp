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

## Do work in Dev1 then move those into Feature1
```
# While on the Dev1 branch
$ git commit -am "First developer update to feature"

#Now merge your changes to Feature1 without a fast-forward
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