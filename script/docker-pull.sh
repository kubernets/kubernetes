#!/bin/bash


get_image_user=kubernets

k8s_repo=k8s.gcr.io


debug=
k8s_replace=false


# help info
function help(){
    echo $0 -D for debug
    echo $0 -K for set $k8s_repo as repo
    echo $0 -p for docker pull Dockerfile images
    echo $0 -H for help
}

# goto help
if [ $# == 0 ]; then 
    help
    exit 
fi 

shell_path=$(cd `dirname $0`;pwd)

cd $shell_path

function pull-images(){

    files=`find $1 -name Dockerfile`
    
    for file in $files; do
        text=`grep -i "^FROM" $file`
        repo=${text%/*}
        repo=${repo##*"FROM "}
        image=${text##*/}

        if [ "$debug" = "echo" ]; then
            echo "--------"
        fi

        # pull
        $debug docker pull $get_image_user/$image
        # tag
        if [ $k8s_replace = true ];then
            $debug docker tag $get_image_user/$image $k8s_repo/$image
        else
            $debug docker tag $get_image_user/$image $repo/$image
        fi
        # remove
        $debug docker rmi $get_image_user/$image
    done
}


# get args
while getopts "DHKp" opt; do  
  case $opt in  
    D)  
      debug=echo   
      ;;
    K)  
      k8s_replace=true 
      ;;
    p)  
      pull-images ..
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
