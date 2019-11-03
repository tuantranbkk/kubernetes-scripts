#!/usr/bin/env bash

set -e

# disable swap
sudo swapoff -a

# install docker

sudo apt-get remove docker docker-engine docker.io
sudo apt install docker.io

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload

sudo systemctl start docker
sudo systemctl enable docker

# install kubeadm, kubelet

sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# install  k8s
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install calico network for pods
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml
# taint all nodes
kubectl taint nodes --all node-role.kubernetes.io/master-

# install helm 
cat > helm.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF

kubectl create -f helm.yaml

curl https://get.helm.sh/helm-v2.15.2-linux-amd64.tar.gz -O $HOME/helm.tar.gz
cd $HOME
tar -xvf helm.tar.gz
sudo ln linux-amd64/helm /usr/local/bin/helm
helm init --service-account tiller

