#!/bin/bash

set -e

sudo apt update
# sudo apt upgrade -y

# Add /usr/local/bin in PATH for the vagrant user
echo "[LOG] Exporting /usr/local/bin path to PATH env variable"
export PATH=/usr/local/bin:$PATH
echo 'export PATH=/usr/local/bin:$PATH' >> /home/vagrant/.bashrc

append_to_file() {
    local keyword=$1
    local file=$2

    if ! grep -q $keyword $file 2>/dev/null; then
        echo $keyword >> $file
        echo "$keyword added to $file"
    else
        echo KUBECONFIG env exists
    fi
}

install_k3s() {
  if ! command -v k3s >/dev/null 2>&1; then
    echo "Starting K3s installation..."
    curl -sfL https://get.k3s.io |  sh -
  else
    echo "K3s is already installed. Skipping installation."
  fi
}

wait_k3s_installation() {
  echo "Waiting for /etc/rancher/k3s/k3s.yaml to be created..."
  for i in {1..10}; do
    if [ -e /etc/rancher/k3s/k3s.yaml ]; then
      echo "/etc/rancher/k3s/k3s.yaml has been found"
      break
    fi
    sleep 2
  done
}

copy_k3s_config() {
  if [ -e /etc/rancher/k3s/k3s.yaml ]; then
    if [ ! -e $HOME_DIRECTORY/.kube/config ]; then
      echo "Copying kubeconfig to $HOME_DIRECTORY/.kube/config"
      mkdir -p $HOME_DIRECTORY/.kube
      cp /etc/rancher/k3s/k3s.yaml $HOME_DIRECTORY/.kube/config
      chown $(id -u):$(id -g) $HOME_DIRECTORY/.kube/config
      chmod 644 $HOME_DIRECTORY/.kube/config
    else
      echo "$HOME_DIRECTORY/.kube/config already exists. Skipping copy."
    fi

    append_to_file 'export KUBECONFIG=$HOME/.kube/config' /home/vagrant/.zshrc
    append_to_file 'export KUBECONFIG=$HOME/.kube/config' /home/vagrant/.bashrc
    append_to_file 'export KUBECONFIG=$HOME/.kube/config' /home/vagrant/.bash_profile
  else
    echo "k3s.yaml not found after waiting."
  fi
}

install_k3s
wait_k3s_installation
copy_k3s_config