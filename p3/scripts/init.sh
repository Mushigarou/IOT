# https://docs.docker.com/engine/install/centos/#install-using-the-repository
# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
sudo systemctl enable docker
sudo systemctl start docker

# https://docs.docker.com/engine/security/rootless/
# run docker service and daemon in rootless mode (for testing purposes not for prod)
sudo systemctl disable --now docker.service docker.socket
sudo rm /var/run/docker.sock
dockerd-rootless-setuptool.sh install

if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
fi