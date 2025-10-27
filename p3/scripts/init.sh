# https://docs.docker.com/engine/install/centos/#install-using-the-repository
# install docker

# Add /usr/local/bin in PATH for the vagrant user
echo "[LOG] Exporting /usr/local/bin path to PATH env variable"
export PATH=/usr/local/bin:$PATH
echo 'export PATH=/usr/local/bin:$PATH' >> /home/vagrant/.bashrc

if ! command -v docker &> /dev/null; then
    echo "[LOG] Docker was not found. Installing docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh ./get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker vagrant
fi

# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "[LOG] kubectl was not found. Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin
fi

# https://k3d.io/stable/#installation
# Install k3d
if ! command -v k3d &> /dev/null; then
    echo "[LOG] k3d was not found. Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

