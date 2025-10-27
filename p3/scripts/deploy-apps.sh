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
k3d cluster create mfouadiCI -p "8080:80@loadbalancer" -p "10000:30080@loadbalancer"

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

# Apply custom configmap for insecure mode
kubectl apply -f /home/vagrant/confs/configmap.yaml

# Wait for ArgoCD to be ready
log "Waiting for ArgoCD server deployment to be ready"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Restart the deployment to pick up the configmap changes
kubectl rollout restart deployment argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Set default namespace for kubectl to argocd
kubectl config set-context --current --namespace=argocd

# argocd CLI
if ! command -v argocd &> /dev/null; then
    log "Installing argocd CLI"
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
fi

export KUBECONFIG="$(k3d kubeconfig write mfouadiCI)"

kubectl apply -f /home/vagrant/confs/ingress.yaml

kubectl config set-context --current --namespace=argocd

# # configure CLI access talk directly to kube API server instead of argocd API server 
argocd login --core


argocd app create will42 \
    --repo https://github.com/Mushigarou/mfouadi-iot-app \
    --path . \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace dev \
    --sync-policy automated

argocd admin initial-password -n argocd

# Informational messages about access
log "ArgoCD UI available at: http://localhost:8080"
log "Deployed application available at: http://localhost:10000"

echo ""