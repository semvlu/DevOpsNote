cd /tmp
# Install containerd
wget https://github.com/containerd/containerd/releases/download/v2.3.1/containerd-2.3.1-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-2.3.1-linux-amd64.tar.gz
# Install runc
wget  https://github.com/opencontainers/runc/releases/download/v1.4.3/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc
# Install CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.9.1/cni-plugins-linux-amd64-v1.9.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.9.1.tgz
# Config containerd systemd service
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /etc/systemd/system/containerd.service
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl daemon-reload
systemctl enable --now containerd
systemctl status containerd

swapoff -a
vi /etc/fstab
# Comment out swap entry
systemctl daemon-reload

# Config Kernel modules & networking
tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF


tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
sysctl --system
EOF

# Install K8s components
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet


# Control plane: def Pod CIDR for Calico
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
sudo kubeadm token list

sudo kubeadm join --token <token> <control-plane-host>:<control-plane-port> --discovery-token-ca-cert-hash sha256:<hash>


# Copy admin kubeconfig to user dir for kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Set up tigera and let it install Calico
helm repo add projectcalico https://docs.tigera.io/calico/charts

cat > values.yaml <<EOF
installation:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 10.244.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
EOF

kubectl create namespace tigera-operator
helm template calico-crds projectcalico/crd.projectcalico.org.v1 --version v3.32.0 | kubectl apply --server-side -f -
helm install calico projectcalico/tigera-operator --version v3.32.0 --namespace tigera-operator -f values.yaml
watch kubectl get pods -n calico-system

# If Master Not Ready, but workers are Ready:
systemctl restart containerd
systemctl restart kubelet


# Local-path-storage
kubectl apply -f <CRD>.yaml
# Set local-pth-storage as cluster default StorageClass
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
# Verify
kubectl get sc


# Cert-manager
kubectl apply -f <CRD>.yaml
kubectl get pods -n cert-manager
# Troubleshoot for cert failure
kubectl get certificate -A
kubectl get certificaterequest -A
kubectl get clusterissuer vault-issuer -o yaml


# ESO: External Secrets Operator
kubectl get pods -n external-secrets
# Check ESO auth w/ Vault
kubectl get clustersecretstore -A
# Check secrets actually synced Vault -> Kubernetes
kubectl get externalsecrets -A
# If ExternalSecret: "SyncFailed", find out:
kubectl describe externalsecret minio-secret-sync -n minio-tenant


# Secret setup
kubectl create secret generic vault-token -n external-secrets --from-literal=token="$VAULT_TOKEN"


# HA
# Join new control plane node
# All control plane nodes
vi /etc/hosts
<master_ip> <hostname>
...

systemctl stop firewalld
systemctl disable firewalld

# Keep keepalived.conf & haproxy.cfg at temp path, e.g. ~/

apt update && apt install socat -y

# Bind VIP to loopback interface
ip a add 200.200.1.10/32 dev lo
# Start the tunnel in the background
socat TCP4-LISTEN:8443,bind=200.200.1.10,reuseaddr,fork TCP4:<origin_master_ip>:6443 &
# Verify the tunnel
curl -k https://200.200.1.10:8443/version

kubeadm join 200.200.1.10:8443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash> \
    --control-plane --certificate-key <key> \
    --apiserver-advertise-address <new_master_ip>


killall socat
ip a del 200.200.1.10/32 dev lo

# Move LB into static pod path
mv ~/haproxy.yaml /etc/kubernetes/manifests/
mv ~/keepalived.yaml /etc/kubernetes/manifests/

# All control plane nodes
tee  /etc/haproxy/haproxy.cfg <<EOF
server master-N <master-N_ip>:6443 check verify none
EOF

# Join worker nodes
ip route add 200.200.1.10/32 dev ens160
curl -k https://200.200.1.10:8443/version
kubeadm join 200.200.1.10:8443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

