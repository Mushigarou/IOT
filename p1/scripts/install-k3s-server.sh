curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=$SERVER_NODE_IP --advertise-address=$SERVER_NODE_IP" sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
