# Merge 2 repositories and keep history

## Sources

We have 3 repositories, arepo1 and arepo2 that we want to put into a new repo aumbrealla. Clone all 3 repositories to your machine. 

```
https://github.com/grecoe/aumbrella.git
https://github.com/grecoe/arepo1.git
https://github.com/grecoe/arepo2.git
```

## Modify your originals if you want them in a sub folder contained within the new parent repo. 

- Download git-filter-repo :: https://github.com/newren/git-filter-repo/blob/main/git-filter-repo
- Put this file on your machine somewhere, you can modify path, or just use it where it is (this is what I'm doing)

## For your source repos, put them into their own sub folders in the original repository

```
arepo1> python C:\...\git-filter-repo --to-subdirectory-filter arepo1
arepo2> python C:\...\git-filter-repo --to-subdirectory-filter arepo2
```

## Move them to your new parent umbrella repository

Note, you are only bringing over one branch, so make sure the child repos are up to date. 

```
aumbrella> git remote add arepo1 ../arepo1
aumbrella> git fetch arepo1 --no-tags
aumbrella> git merge --allow-unrelated-histories arepo1/main

aumbrella> git remote add arepo2 ../arepo2
aumbrella> git fetch arepo2 --no-tags
aumbrella> git merge --allow-unrelated-histories arepo2/main
```

## Verify
Once it looks good an you like what you have, add/commit the umbrella to source control. Again review what you have there. 

When satisfied it worked, delete the original source repos arepo1 and arepo2. 
