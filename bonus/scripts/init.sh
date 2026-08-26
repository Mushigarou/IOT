#!/bin/bash
# Installs Docker, kubectl, k3d and the latest GitLab CE.
set -e

log() { echo "[init] $*"; }

if ! command -v docker &> /dev/null; then
    log "installing Docker"
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker vagrant
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

# https://docs.gitlab.com/install/package/ubuntu/
if ! command -v gitlab-ctl &> /dev/null; then
    log "installing GitLab CE at $GITLAB_URL (this takes a while)"
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        curl ca-certificates tzdata perl openssh-server git
    curl -fsSL https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
    EXTERNAL_URL="$GITLAB_URL" DEBIAN_FRONTEND=noninteractive apt-get install -y gitlab-ce
fi
