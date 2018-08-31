# Script

1. **git-push.sh**

    Check the changes of Dockerfile files, automatically generate README.md files, take the version number of Dockerfile as tag and submit it to GitHub.
    Get new tag from: [https://console.cloud.google.com/gcr/images/google-containers/GLOBAL?location=GLOBAL&project=google-containers](https://console.cloud.google.com/gcr/images/google-containers/GLOBAL?location=GLOBAL&project=google-containers)

2. **docker-pull.sh**

    Check the tag of the Dockerfile file, then pull the mirror from docker hub, and reset the tag on the Dockerfile.

3. **kubeadm.sh**

    Use kubeadm install kubernetes.

## use

### flag

- -H for help
- -D for debug

### commad

1. generate images readme.md

    > ./script/git-push.sh -r

1. generate repo readme.md

    > ./script/git-push.sh -R

1. init/commit images repo

    > ./script/git-push.sh -G