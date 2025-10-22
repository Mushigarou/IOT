# Reactivate docker for current user cause it was deactivated when instaling rootless mode of docker
# systemctl --user start docker
# systemctl --user start docker

# Ensure /usr/local/bin is in PATH for the vagrant user
echo "[LOG] Exporting /usr/local/bin path to PATH env variable"
export PATH=/usr/local/bin:$PATH
echo 'export PATH=/usr/local/bin:$PATH' >> /home/vagrant/.bashrc


# https://github.com/NixOS/nixpkgs/issues/385044
# In docker rootless mode creation of a cluster needs KubeletInUserNamespace=true to be activated
# k3d cluster create --k3s-arg '--kubelet-arg=feature-gates=KubeletInUserNamespace=true@server:*' mfouadiCI
k3d cluster create mfouadiCI

# Copy kubeconfig to vagrant user
mkdir -p /home/vagrant/.kube
cp ~/.kube/config /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Create dev namespace
kubectl create namespace dev

# Install argoCD in namespace argocd 
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# brew install argocd
