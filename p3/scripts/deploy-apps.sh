# Reactivate docker for current user cause it was deactivated when instaling rootless mode of docker
# systemctl --user start docker
# systemctl --user start docker

# Function to print logs
log() {
    echo "[LOG] $1"
}
# Ensure /usr/local/bin is in PATH for the vagrant user
log "Exporting /usr/local/bin path to PATH env variable"
export PATH=/usr/local/bin:$PATH
echo 'export PATH=/usr/local/bin:$PATH' >> /home/vagrant/.bashrc


# k3d cluster create --k3s-arg '--kubelet-arg=feature-gates=KubeletInUserNamespace=true@server:*' mfouadiCI
# Delete any existing cluster with the same name to avoid port conflicts
log "Deleting any existing cluster mfouadiCI"
k3d cluster delete mfouadiCI --yes 2>/dev/null || true

# https://github.com/NixOS/nixpkgs/issues/385044
# In docker rootless mode creation of a cluster needs KubeletInUserNamespace=true to be activated
log "Creating cluster mfouadiCI"
k3d cluster create mfouadiCI -p "8080:80@loadbalancer" -p "8443:443@loadbalancer" -p "8085:80@loadbalancer"

# Copy kubeconfig to vagrant user
mkdir -p /home/vagrant/.kube
cp ~/.kube/config /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Create dev namespace
log "Creating namespace dev"
kubectl create namespace dev

# Install argoCD in namespace argocd
log "Installing argoCD in namespace argocd"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
log "Waiting for ArgoCD server deployment to be ready"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Set ArgoCD server to insecure mode to serve HTTP without TLS redirect
# log "Setting ArgoCD server to insecure mode"
# kubectl patch deployment argocd-server -n argocd --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/env", "value": [{"name": "ARGOCD_SERVER_INSECURE", "value": "true"}]}]'

# Default namespace for kubectl config must be set to argocd
kubectl config set-context --current --namespace=argocd

# argocd CLI
if ! command -v argocd &> /dev/null; then
    log "Installing argocd CLI"
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
fi

kubectl config set-context --current --namespace=dev

export KUBECONFIG="$(k3d kubeconfig write mfouadiCI)"
# kubectl apply -f /home/vagrant/confs/deploy.yaml
kubectl apply -f /home/vagrant/confs/ingress.yaml


kubectl config set-context --current --namespace=argocd
argocd admin initial-password -n argocd


# kubectl apply -f /home/vagrant/app/confs/deploy.yaml
# kubectl create service clusterip nginx-test --tcp=80:80 -n dev
# kubectl apply -f /home/vagrant/app/confs/ingress.yaml" -n dev

# # configure CLI access talk directly to kube API server instead of argocd API server 
argocd login --core

# kubectl port-forward --address=0.0.0.0 svc/argocd-server -n argocd 8080:443 r
argocd app create will42 --repo https://github.com/Mushigarou/mfouadi-iot-app --path . --dest-server https://kubernetes.default.svc --dest-namespace dev --sync-policy automated