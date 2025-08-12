curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=$SERVER_NODE_IP --advertise-address=$SERVER_NODE_IP" sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Configure kubectl for mfouadi user
sudo mkdir -p /home/mfouadi/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/mfouadi/.kube/config
sudo chown mfouadi:mfouadi /home/mfouadi/.kube/config
sudo chmod 600 /home/mfouadi/.kube/config