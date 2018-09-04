#!/bin/bash


debug=

init_readme=0
init_git=0
init_git_readme=0
enable_git_push=1

enable_clean=0

organization=kubernets

docker_hub=https://hub.docker.com/u/$organization
docker_base=https://hub.docker.com/r/$organization
github_base=https://github.com/$organization

user_name=galaxyobe
user_email=galaxyobe@qq.com

git_submodules=()

basepath=$(cd `dirname $0`; pwd)

cd $basepath

base_path=..

# for help
function help(){
    echo $0 -D for debug
    echo $0 -c for clean .git and README.md
    echo $0 -G for enable init git
    echo $0 -R for enable gen readme
    echo $0 -r for enable gen images readme
    echo $0 -P for enable disable git push
    echo $0 -H for help
}

# goto help
if [ $# == 0 ]; then 
    help
    exit 
fi 

# get args
while getopts "cDHGRrPp:" opt; do  
  case $opt in
    c) 
      enable_clean=1 
      ;;
    D)  
      debug=echo   
      ;;
    G)  
      init_git=1 
      ;;
    R)  
      init_readme=1 
      ;;
    r)  
      init_git_readme=1 
      ;;
    P)  
      enable_git_push=0 
      ;;
    H)
      help
      ;;  
    \?)  
      help
      exit   
      ;;  
  esac  
done 

# init git repo
function git-init(){
    $debug git init
    $debug git config user.email $user_email
    $debug git config user.name $user_name
    $debug git remote add origin git@github.com:kubernets/$1.git
    if [ "$2" == "" ]; then
        git_submodules[${#git_submodules[*]}]="git@github.com:kubernets/$1.git"
    fi
}

# git commit 
function git-commit(){
    ret=`git status`
    commit=$(echo ${ret} | grep "干净的工作区")
    if [[ "${commit}" != "" ]]; then
        echo exit `pwd`
	    return
    fi
    $debug git add *
    $debug git commit -m "$2"
    if [ "$3" == "" ]; then
        $debug git tag "$2"
    fi
    if [ "$enable_git_push" == "1" ]; then
        $debug git push -u origin $1 --tags
    fi
}

# git root repo
function git-root-init(){
    $debug cd ..

    git-init "kubernetes" false

    for submodule in ${git_submodules[*]}
    do
        $debug git submodule add $submodule
    done

    git-commit master "`date "+%F %T"`" false

    $debug cd -
}

function readme-root-init(){
    $debug tee $1/README.md << EOF
# $2 image repo

github addr [$github_base/$2]($github_base/$2)

docker hub addr [$docker_hub]($docker_hub)

* **clone repo and pull all submodule**

    > git clone git@github.com:kubernets/kubernetes.git --recursive

    or

    > git clone https://github.com/kubernets/kubernetes.git --recursive

* **pull git submodule**

    > git submodule init

    > git submodule sync

    > git submodule update

* **get shell script to download all image's script**

    > wget $github_base/$2/raw/master/get-$2-image.sh

* **find new version form google**

    > https://console.cloud.google.com/gcr/images/google-containers/GLOBAL?location=GLOBAL&project=google-containers

* **update**

    1. generate images README.md

        > ./script/git-push.sh -r

    1. generate this repo README.md

        > ./script/git-push.sh -R

    1. git init/commit images repo and push to origin

        > ./script/git-push.sh -G

## Arch and Version
EOF
}

function readme-init(){
    $debug tee $1/README.md << EOF
# $2

github addr [$github_base/$2]($github_base/$2)

docker hub addr [$docker_hub]($docker_hub)

get shell script to pull docker image and replace origin tag

    wget $github_base/$2/raw/master/get-$2-image.sh

## Arch and Version
EOF
}


function add-readme-arch(){
    if [ -f "$1/README.md" ]; then
        grep "$4" $1/README.md > /dev/null
        if [ $? -ne 0 ]; then
            arch=
            if [ "$3" != "all" ]; then
                arch="-"$3
            fi
            $debug tee -a $1/README.md << EOF

- [**$3** $4]($docker_base/$2$arch)

    > docker pull $organization/$2$arch:$4

    > docker tag $organization/$2$arch:$4 $5 

    > docker rmi $organization/$2$arch:$4
EOF
            $debug tee $1/get-$2-image.sh << EOF
docker pull $organization/$2$arch:$4
docker tag $organization/$2$arch:$4 $5 
docker rmi $organization/$2$arch:$4
EOF
            $debug chmod +x $1/get-$2-image.sh            
        fi
    fi
}

function add-readme-link(){
    $debug tee -a $1/README.md << EOF

1. **$2** $3

    $github_base/$2
EOF

    $debug tee -a $1/get-Kubernetes-image.sh << EOF
# image: $2 
# tag: $3
# repo: $github_base/$2
wget $github_base/$2/raw/master/get-$2-image.sh

EOF
}

function gen-root-readme(){
    if [ "$debug" == "" ]; then
        readme-root-init $1 "Kubernetes"
        rm -f $1/get-Kubernetes-image.sh
    fi

    files=`find $1 -name Dockerfile`
    for path in $files
    do
        abs_path=${path##*./}
        dir_name=${abs_path%%/*}
        text=`grep -i "^FROM" $path`
        tag=${text##*:}
        if [ "$debug" == "echo" ]; then
            $debug dir:$dir_name name:$tag
        else
            add-readme-link $1 $dir_name $tag
        fi
    done 
}

function init(){
    exec=`pwd`
    files=`find $1 -name Dockerfile`
    for path in $files
    do
        abs_path=${path##*./}
        dir_name=${abs_path%%/*}
        file=${abs_path#*/}
        arch=${file%%/*}
        
        if [ "Dockerfile" == "$arch" ]; then
            arch=all
        fi

        text=`grep -i "^FROM" $path`
        tag=${text##*:}

        cd $1/$dir_name

        echo current:`pwd` path:$path abs_path:$abs_path dir:$dir_name arch:$arch tag:$tag
        
        git_submodules[${#git_submodules[*]}]="git@github.com:kubernets/$dir_name.git"

        if [ ! -d ".git" ]; then
            if [ "${init_git}" == "1" ]; then
                git-init $dir_name
            fi
        else
            if [ "$debug" == "echo" ]; then
                echo ".git is in `pwd`"
            fi
        fi

        if [ "${init_git_readme}" == "1" ]; then
            if [ ! -f "README.md" ]; then
                readme-init . $dir_name
            else
                if [ "$debug" == "echo" ]; then
                    echo "README.md is in `pwd`"
                fi
            fi
            add-readme-arch . $dir_name $arch $tag ${text##"FROM "}
        fi

        if [ "${init_git}" == "1" ]; then
            git-commit master $tag
        fi

        cd $exec
    done
}


function clean(){
    files=`find $1 -name Dockerfile`
    for path in $files
    do
        abs_path=${path##*./}
        dir_name=${abs_path%%/*}
        if [ "${init_git}" == "1" ]; then
            $debug rm -rf $1/$dir_name/.git
            if [ "$debug" != "echo" ]; then
                echo rm -rf $1/$dir_name/.git
            fi
        fi
        if [ "${init_git_readme}" == "1" ]; then
            $debug rm -rf $1/$dir_name/README.md
            if [ "$debug" != "echo" ]; then
                echo rm -rf $1/$dir_name/README.md
            fi
        fi
    done
}

if [ "${enable_clean}" == "1" ]; then
    clean $base_path 
    exit
fi

if [ "${init_git}" == "1" -o "${init_git_readme}" == "1" ]; then
    init $base_path
    if [ "${init_git}" == "1" ];then
        git-root-init
    fi
fi

if [ "${init_readme}" == "1" ]; then
    gen-root-readme $base_path
fi
