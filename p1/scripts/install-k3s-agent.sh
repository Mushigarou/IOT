curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=$SERVER_AGENT_NODE_IP" K3S_URL=$K3S_SERVER_URL K3S_TOKEN=$K3S_SERVER_TOKEN sh -

# Configure kubectl for mfouadi user by copying from server
sudo mkdir -p /home/mfouadi/.kube

# Wait a moment for k3s agent to fully start
sleep 5

# Copy the kubeconfig from the server node and modify it
# Note: This requires the server to be accessible
SERVER_IP=$(echo $K3S_SERVER_URL | sed 's|https://||' | cut -d':' -f1)

# Create a simple kubeconfig that uses the server's endpoint with insecure flag for simplicity
# In production, you'd want to copy the actual certificates
sudo tee /home/mfouadi/.kube/config > /dev/null <<EOF
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: ${K3S_SERVER_URL}
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    token: ${K3S_SERVER_TOKEN}
EOF
