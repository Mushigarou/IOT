#!/bin/bash
# Creates the k3d cluster, mirrors the part 3 app into the local GitLab and lets
# Argo CD deploy it from there.
set -e

CLUSTER=mfouadiCI
ARGOCD_MANIFEST=https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
APP_REPO=https://github.com/Mushigarou/mfouadi-iot-app
PROJECT=mfouadi-iot-app
GITLAB_HOST=${GITLAB_URL#http://}

log() { echo "[deploy] $*"; }

# 8888 -> Traefik (Argo CD UI), 10000 -> the app's NodePort.
# Not 8080: GitLab's Puma already listens there.
log "creating cluster $CLUSTER"
k3d cluster delete $CLUSTER &> /dev/null || true
k3d cluster create $CLUSTER -p "8888:80@loadbalancer" -p "10000:30080@loadbalancer"

# Let the vagrant user run kubectl without sudo.
install -d -o vagrant -g vagrant /home/vagrant/.kube
k3d kubeconfig get $CLUSTER > /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

log "installing Argo CD"
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f $ARGOCD_MANIFEST
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s

log "waiting for GitLab to answer"
until curl -fsSo /dev/null "$GITLAB_URL/users/sign_in"; do sleep 5; done

# Public so Argo CD can clone it without credentials.
log "creating the GitLab project $PROJECT"
TOKEN=$(gitlab-rails runner "puts User.find_by_username('root').personal_access_tokens.create!(
  name: 'deploy', expires_at: 300.days.from_now, scopes: ['api', 'write_repository']).token" \
  | grep -oE 'glpat-\S+')
curl -fsS --header "PRIVATE-TOKEN: $TOKEN" -X POST "$GITLAB_URL/api/v4/projects" \
  --data "name=$PROJECT&path=$PROJECT&visibility=public" > /dev/null || true

log "mirroring the part 3 app into GitLab"
rm -rf /tmp/$PROJECT
git clone -q $APP_REPO /tmp/$PROJECT
git -C /tmp/$PROJECT push -q --force "http://oauth2:$TOKEN@$GITLAB_HOST/root/$PROJECT.git" HEAD:main

# dev + gitlab namespaces, Argo CD ingress/config, and the Application.
log "deploying through Argo CD"
kubectl apply --server-side --force-conflicts -f /home/vagrant/confs/deploy.yaml
kubectl -n argocd rollout restart deployment/argocd-server
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s

cat <<INFO

  GitLab     $GITLAB_URL          root / $(awk '/^Password:/ {print $2}' /etc/gitlab/initial_root_password)
  Argo CD    $GITLAB_URL:8888     admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
  will42     $GITLAB_URL:10000

INFO
