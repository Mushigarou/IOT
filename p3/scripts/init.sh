#!/bin/bash
# Installs Docker, kubectl and k3d. Run with sudo.
set -e

log() { echo "[init] $*"; }

if ! command -v docker &> /dev/null; then
    log "installing Docker"
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker "${SUDO_USER:-$USER}"
fi

# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
if ! command -v kubectl &> /dev/null; then
    log "installing kubectl"
    curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x /usr/local/bin/kubectl
fi

# https://k3d.io/stable/#installation
if ! command -v k3d &> /dev/null; then
    log "installing k3d"
    curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi
