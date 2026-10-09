#!/usr/bin/env bash
# GitOps part 2: change the desired state ONLY through Git and watch Argo CD apply it.
# Expects: the Application from run-demo.sh is Synced, and we are inside a checkout of the repo.
set +e
cd "$(dirname "$0")/.."
OUT=outputs
APPDIR="Monitoring Observability GitOps/gitops/app"
cap() { echo "\$ $*"; bash -c "$*" 2>&1; echo; }
wait_rev() {  # wait until Argo CD has synced the given commit and is Healthy
  for i in $(seq 1 60); do
    s=$(kubectl -n argocd get application session20-app -o jsonpath='{.status.sync.revision} {.status.sync.status} {.status.health.status}')
    [[ "$s" == "$1 Synced Healthy" ]] && return 0
    kubectl -n argocd annotate application session20-app argocd.argoproj.io/refresh=normal --overwrite >/dev/null
    sleep 5
  done
}
WT=$(mktemp -d)
git worktree add -q "$WT" origin/gitops-demo
{
echo '################ Change 1: scale from 2 to 3 replicas - by committing to Git, not with kubectl ################'
cap "kubectl -n session20-gitops get deploy session20-gitops-app"
( cd "$WT" && sed -i 's/replicas: 2/replicas: 3/' "$APPDIR/deployment.yaml" && git add -A && git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" commit -q -m "GitOps demo: scale session20-gitops-app to 3 replicas" && git push -q origin HEAD:gitops-demo )
REV1=$(git -C "$WT" rev-parse HEAD)
cap "git -C '$WT' log --oneline -1 && git -C '$WT' show --stat --format= HEAD && git -C '$WT' diff HEAD~1 -- '$APPDIR/deployment.yaml'"
wait_rev "$REV1"
cap "kubectl -n argocd get application session20-app -o jsonpath='synced revision: {.status.sync.revision}  sync={.status.sync.status}  health={.status.health.status}'; echo"
cap "kubectl -n session20-gitops get deploy session20-gitops-app"
cap "kubectl -n session20-gitops get pods"

echo '################ Change 2: upgrade the image nginx:1.27-alpine -> nginx:1.28-alpine via Git ################'
( cd "$WT" && sed -i 's/nginx:1.27-alpine/nginx:1.28-alpine/' "$APPDIR/deployment.yaml" && git add -A && git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" commit -q -m "GitOps demo: upgrade to nginx 1.28" && git push -q origin HEAD:gitops-demo )
REV2=$(git -C "$WT" rev-parse HEAD)
cap "git -C '$WT' diff HEAD~1 -- '$APPDIR/deployment.yaml'"
wait_rev "$REV2"
cap "kubectl -n session20-gitops get deploy session20-gitops-app -o jsonpath='{.spec.template.spec.containers[0].image}  ready={.status.readyReplicas}/{.spec.replicas}'; echo"

echo '################ Change 3: prune - delete service.yaml from Git, Argo CD deletes the Service ################'
cap "kubectl -n session20-gitops get svc"
( cd "$WT" && git rm -q "$APPDIR/service.yaml" && git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" commit -q -m "GitOps demo: remove the Service" && git push -q origin HEAD:gitops-demo )
REV3=$(git -C "$WT" rev-parse HEAD)
wait_rev "$REV3"
cap "kubectl -n session20-gitops get svc"

echo '################ Roll back = git revert ################'
( cd "$WT" && git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" revert --no-edit HEAD >/dev/null && git push -q origin HEAD:gitops-demo )
REV4=$(git -C "$WT" rev-parse HEAD)
wait_rev "$REV4"
cap "git -C '$WT' log --oneline -5"
cap "kubectl -n session20-gitops get deploy,svc"
cap "kubectl -n argocd get application session20-app -o jsonpath='{range .status.history[*]}{.id}  {.revision}  {.deployedAt}{\"\n\"}{end}'"
} 2>&1 | tee "$OUT/05-gitops-git-change.txt"
git worktree remove --force "$WT"
echo "gitops-git-change.sh finished"
