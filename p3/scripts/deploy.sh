#!/bin/bash
# Creates the K3d cluster, installs Argo CD and hands it the app to deploy.
set -e

CLUSTER=mfouadiCI
ARGOCD_MANIFEST=https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

log() { echo "[deploy] $*"; }

# 8080 -> Traefik (Argo CD UI), 10000 -> the app's NodePort.
log "creating cluster $CLUSTER"
k3d cluster delete $CLUSTER &> /dev/null || true
k3d cluster create $CLUSTER -p "8080:80@loadbalancer" -p "10000:30080@loadbalancer"

# Let the vagrant user drive the cluster without sudo.
install -d -o vagrant -g vagrant /home/vagrant/.kube
k3d kubeconfig get $CLUSTER > /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

log "installing Argo CD"
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f $ARGOCD_MANIFEST
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s

# confs/deploy.yaml holds the dev namespace, the Argo CD ingress + HTTP switch
# and the Application syncing the app from GitHub.
log "deploying through Argo CD"
kubectl apply --server-side --force-conflicts -f /home/vagrant/confs/deploy.yaml
kubectl -n argocd rollout restart deployment/argocd-server
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s

cat <<INFO

  Argo CD    http://localhost:8080  admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
  will42     http://localhost:10000

INFO
