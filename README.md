# Kubernetes image repo

github addr [https://github.com/kubernets/Kubernetes](https://github.com/kubernets/Kubernetes)

docker hub addr [https://hub.docker.com/u/kubernets](https://hub.docker.com/u/kubernets)

* **clone repo and pull all submodule**

    > git clone git@github.com:kubernets/kubernetes.git --recursive

    or

    > git clone https://github.com/kubernets/kubernetes.git --recursive

* **pull git submodule**

    > git submodule init

    > git submodule sync

    > git submodule update

* **get shell script to download all image's script**

    > wget https://github.com/kubernets/Kubernetes/raw/master/get-Kubernetes-image.sh

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

1. **spinnaker-halyard** 1.9.1-20180830145737

    https://github.com/kubernets/spinnaker-halyard

1. **coredns** 1.1.3

    https://github.com/kubernets/coredns

1. **k8s-dns-sidecar** 1.14.10

    https://github.com/kubernets/k8s-dns-sidecar

1. **etcd** 3.2.18

    https://github.com/kubernets/etcd

1. **spinnaker-clouddriver** 3.4.2-20180828182842

    https://github.com/kubernets/spinnaker-clouddriver

1. **spinnaker-rosco** 0.7.3-20180818041609

    https://github.com/kubernets/spinnaker-rosco

1. **kube-apiserver** v1.11.2

    https://github.com/kubernets/kube-apiserver

1. **heapster-influxdb** v1.5.2

    https://github.com/kubernets/heapster-influxdb

1. **kube-scheduler** v1.11.2

    https://github.com/kubernets/kube-scheduler

1. **hyperkube** v1.10.7

    https://github.com/kubernets/hyperkube

1. **spinnaker-redis** v2

    https://github.com/kubernets/spinnaker-redis

1. **spinnaker-gate** 1.1.1-20180829141913

    https://github.com/kubernets/spinnaker-gate

1. **kube-proxy** v1.11.2

    https://github.com/kubernets/kube-proxy

1. **kubernetes-dashboard** v1.10.0

    https://github.com/kubernets/kubernetes-dashboard

1. **pause** 3.1

    https://github.com/kubernets/pause

1. **spinnaker-deck** 2.4.1-20180824212434

    https://github.com/kubernets/spinnaker-deck

1. **spinnaker-igor** 0.9.0-20180221133510

    https://github.com/kubernets/spinnaker-igor

1. **k8s-dns-dnsmasq-nanny** 1.14.10

    https://github.com/kubernets/k8s-dns-dnsmasq-nanny

1. **spinnaker-orca** 1.0.0-20180814155153

    https://github.com/kubernets/spinnaker-orca

1. **kube-controller-manager** v1.11.2

    https://github.com/kubernets/kube-controller-manager

1. **spinnaker-echo** 2.0.1-20180817041609

    https://github.com/kubernets/spinnaker-echo

1. **k8s-dns-kube-dns** 1.14.10

    https://github.com/kubernets/k8s-dns-kube-dns

1. **spinnaker-front50** 0.12.0-20180802022808

    https://github.com/kubernets/spinnaker-front50

1. **heapster-grafana** v5.0.4

    https://github.com/kubernets/heapster-grafana

1. **tiller** v2.10.0

    https://github.com/kubernets/tiller

1. **heapster** v1.5.4

    https://github.com/kubernets/heapster
