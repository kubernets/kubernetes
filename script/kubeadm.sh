#!/bin/bash



ARCH=amd64

CNI_VERSION="v0.7.0"
KUBERNETES_VERSION="v1.10.0"
KUBERNETES_HOME=/opt/kubernetes


debug=

basepath=$(cd `dirname $0`; pwd)

cd $basepath

linux=$(. /etc/os-release; echo "$ID")
kubeadm_init_opts=
network=

echo release is $linux


function install-docker(){

  if [ ! -f "/etc/docker/daemon.json" ]; then
    cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF
  fi  

  if [ "$linux" = "ubuntu" -o "$linux" = "debian" ];then
    $debug apt-get update
    $debug apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    $debug curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $debug apt-key add -
    $debug add-apt-repository \
      "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
      $(lsb_release -cs) \
      stable"
    $debug apt-get update
    version=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')
    $debug apt-get install -y docker-ce=${version}
  elif [ "$linux" = "centos" -o "$linux" = "rhl" ];then
    $debug yum install -y docker
    $debug systemctl enable docker && systemctl start docker
  elif [ "$linux" = "coreos" ];then
    $debug systemctl enable docker && $debug systemctl start docker
  fi
}

function install-kube-tools(){

  if [ "$linux" = "ubuntu" -o "$linux" = "debian" ];then
    $debug apt-get update && $debug apt-get install -y apt-transport-https
    $debug curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | $debug apt-key add -
    $debug cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
    deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main
EOF
    $debug apt-get update
    $debug apt-get install -y kubelet kubeadm kubectl 
  elif [ "$linux" = "centos" -o "$linux" = "rhl" ];then
    $debug cat <<EOF > /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    $debug setenforce 0

    $debug cat <<EOF >  /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
EOF
    $debug sysctl --system

    $debug yum install -y kubelet kubeadm kubectl
    $debug systemctl enable kubelet && $debug systemctl start kubelet
  elif [ "$linux" = "coreos" ];then
    
    $debug mkdir -p /opt/cni/bin
    if [ ! -f "/opt/cni/bin/flannel" ]; then
      $debug curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-${ARCH}-${CNI_VERSION}.tgz" | $debug tar -C /opt/cni/bin -xz
    fi

    $debug mkdir -p $KUBERNETES_HOME/bin
    if [ ! -f "$KUBERNETES_HOME/bin/kubeadm" ]; then
      RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"

      echo kubernetes version ${KUBERNETES_VERSION}, new release is ${KUBERNETES_VERSION}

      $debug cd $KUBERNETES_HOME/bin
      $debug curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/${ARCH}/{kubeadm,kubelet,kubectl}
      $debug chmod +x {kubeadm,kubelet,kubectl}
    fi

    if [ "$debug" = "echo" ]; then
      echo curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${KUBERNETES_VERSION}/build/debs/kubelet.service"
      echo curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${KUBERNETES_VERSION}/build/debs/10-kubeadm.conf"
    else
      if [ ! -f "/etc/systemd/system/kubelet.service" ]; then
        $debug curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${KUBERNETES_VERSION}/build/debs/kubelet.service" | sed "s:/usr/bin:$KUBERNETES_HOME/bin:g" > /etc/systemd/system/kubelet.service
      fi
      if [ ! -f "/etc/systemd/system/kubelet.service.d/10-kubeadm.conf" ]; then
        $debug mkdir -p /etc/systemd/system/kubelet.service.d
        $debug curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${KUBERNETES_VERSION}/build/debs/10-kubeadm.conf" | sed "s:/usr/bin:$KUBERNETES_HOME/bin:g" > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
      fi
    fi

    $debug systemctl enable kubelet && $debug systemctl start kubelet
  fi

  $debug sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

  if [ "$debug" != "echo" ]; then
    echo "export PATH=\$PATH:$KUBERNETES_HOME/bin" > /etc/profile.d/kubernetes.sh
  fi

  $debug systemctl daemon-reload
  $debug systemctl restart kubelet

  echo "please exec source /etc/profile"
}



function kubeadm-install-network(){
  if [ "$network" = "calico" ];then 
    $debug $KUBERNETES_HOME/bin/kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
  elif [ "$network" = "canal" ];then 
    $debug $KUBERNETES_HOME/bin/kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.7/rbac.yaml
    $debug $KUBERNETES_HOME/bin/kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.7/canal.yaml
  elif [ "$network" = "flannel" ];then 
    $debug $KUBERNETES_HOME/bin/kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  elif [ "$network" = "romana" ];then 
    $debug $KUBERNETES_HOME/bin/kubectl apply -f https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-kubeadm.yml
  elif [ "$network" = "weave" ];then 
    $debug export kubever=$(kubectl version | base64 | tr -d '\n')
    $debug $KUBERNETES_HOME/bin/kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
  fi

}


function kubeadm-init(){
  if [ "$debug" = "" ];then
    echo $KUBERNETES_HOME/bin/kubeadm init $kubeadm_init_opts
  fi
  $debug $KUBERNETES_HOME/bin/kubeadm init $kubeadm_init_opts
  kubeadm-install-network
}

# for help
function help(){
    echo $0 -D for debug
    echo $0 -H for help
}

# goto help
if [ $# == 0 ]; then 
    help
    exit 
fi 


# get args
while getopts "DHdkn:Nio:" opt; do  
  case $opt in
    D)  
      debug=echo
      ;;
    H)
      help
      ;;  
    d)
      install-docker
      ;;
    k)
      install-kube-tools
      ;;
    o)
      kubeadm_init_opts+=" "$OPTARG
      ;;
    N)
      # DNS
      kubeadm_init_opts+=" ""–-feature-gates=CoreDNS=true"
      ;;
    n)
      # pod network
      if [ "$OPTARG" = "calico" ]; then
        if [ "$ARCH" != "amd64" ]; then
          echo "Calico works on amd64 only."
          exit
        fi
        kubeadm_init_opts+=" ""--pod-network-cidr=192.168.0.0/16"
      elif [ "$OPTARG" = "canal" ]; then
        if [ "$ARCH" != "amd64" ]; then
          echo "Canal works on amd64 only."
          exit
        fi
        kubeadm_init_opts+=" ""--pod-network-cidr=10.244.0.0/16"
      elif [ "$OPTARG" = "flannel" ];then 
        kubeadm_init_opts+=" ""--pod-network-cidr=10.244.0.0/16"
        $debug sysctl net.bridge.bridge-nf-call-iptables=1
      elif [ "$OPTARG" = "kube-router" ]; then
        $debug sysctl net.bridge.bridge-nf-call-iptables=1
        kubeadm_init_opts+=" ""--pod-network-cidr"
      elif [ "$OPTARG" = "romana" ]; then
        if [ "$ARCH" != "amd64" ]; then
          echo "Canal works on amd64 only."
          exit
        fi
        $debug sysctl net.bridge.bridge-nf-call-iptables=1
      elif [ "$OPTARG" = "weave" ]; then
        $debug sysctl net.bridge.bridge-nf-call-iptables=1
      else
        echo "please -n calico | canal | flannel | kube-router | romana | weave"
        exit
      fi

      network=$OPTARG

      if [ "$debug" = "echo" ]; then
        echo "pod network" is $network
      fi
      ;;
    i)
      if [ "$network" = "" ]; then
        echo "please -n calico | canal | flannel | kube-router | romana | weave"
      fi
      kubeadm-init
      ;;
    \?)  
      help
      exit   
      ;;  
  esac  
done 
