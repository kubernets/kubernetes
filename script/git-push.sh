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
    echo $0 -r for enable gen git readme
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


function readme-init(){
    $debug tee $1/README.md << EOF
# $2

github addr [$github_base/$2]($github_base/$2)

docker hub addr [$docker_hub]($docker_hub)

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
EOF
        fi
    fi
}

function add-readme-link(){
    $debug tee -a $1/README.md << EOF

1. **$2** $3

    $github_base/$2
EOF
}

function gen-root-readme(){
    if [ "$debug" == "" ]; then
        readme-init $1 "Kubernetes"
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
            add-readme-arch . $dir_name $arch $tag
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
