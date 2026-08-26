#!/bin/bash
# Creates the k3d cluster, mirrors the part 3 app into the local GitLab and lets
# Argo CD deploy it from there.
set -e

CLUSTER=mfouadiCI
ARGOCD_MANIFEST=https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
APP_REPO=https://github.com/Mushigarou/mfouadi-iot-app
PROJECT=mfouadi-iot-app
ROOT_PASSWORD=Zurich-Falcon-7714
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

# Known root password + an API token, then a public project Argo CD can clone.
log "setting up the GitLab root account and project $PROJECT"
TOKEN="glpat-$(openssl rand -hex 10)"
gitlab-rails runner "
u = User.find_by_username('root')
u.password = u.password_confirmation = '$ROOT_PASSWORD'
u.password_automatically_set = false
u.save!
u.personal_access_tokens.where(name: 'bootstrap').delete_all
t = u.personal_access_tokens.new(name: 'bootstrap', expires_at: 300.days.from_now,
                                 scopes: ['api', 'write_repository'])
t.set_token('$TOKEN')
t.save!
unless Project.find_by_full_path('root/$PROJECT')
  Projects::CreateService.new(u, name: '$PROJECT', path: '$PROJECT',
    namespace_id: u.namespace.id,
    visibility_level: Gitlab::VisibilityLevel::PUBLIC).execute
end
"

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

  GitLab     $GITLAB_URL          root / $ROOT_PASSWORD
  Argo CD    $GITLAB_URL:8888     admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
  will42     $GITLAB_URL:10000

INFO
