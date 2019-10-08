
sudo systemctl stop kubelet docker

cd /etc/

# backup old kubernetes data
sudo rm -rf kubernetes-backup
sudo mv kubernetes kubernetes-backup
sudo rm -rf /var/lib/kubelet-backup
sudo mv /var/lib/kubelet /var/lib/kubelet-backup



# restore certificates

sudo mkdir -p kubernetes

sudo cp -r kubernetes-backup/pki kubernetes

sudo rm kubernetes/pki/{apiserver.*,etcd/peer.*}



sudo systemctl start docker



# reinit master with data in etcd

# add --kubernetes-version, --pod-network-cidr and --token options if needed

sudo kubeadm init --ignore-preflight-errors=DirAvailable--var-lib-etcd



# update kubectl config

sudo cp kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# wait for some time and delete old node

sleep 120

kubectl get nodes --sort-by=.metadata.creationTimestamp

kubectl delete node $(kubectl get nodes -o jsonpath='{.items[?(@.status.conditions[0].status=="Unknown")].metadata.name}')

kubectl taint nodes --all node-role.kubernetes.io/master-

# check running pods

kubectl get pods --all-namespaces
