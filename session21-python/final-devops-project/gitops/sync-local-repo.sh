#!/usr/bin/env bash
# Create/refresh the LOCAL git repo that Argo CD watches, and serve it with git daemon.
#   GITOPS_SRC=~/gitops-src ./gitops/sync-local-repo.sh "commit message"
# Copies helm/taskboard and gitops/apps from this project into $GITOPS_SRC/taskboard-gitops,
# commits, and (if needed) starts `git daemon` on :9418 so the cluster can clone
# git://host.minikube.internal/taskboard-gitops
set -euo pipefail
PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${GITOPS_SRC:-$HOME/gitops-src}"
REPO="$SRC/taskboard-gitops"
MSG="${1:-sync from final-devops-project}"

mkdir -p "$REPO"
if [ ! -d "$REPO/.git" ]; then
  git -C "$REPO" init -q -b main
fi
mkdir -p "$REPO/helm" "$REPO/gitops/apps"
rsync -a --delete "$PROJECT/helm/taskboard/" "$REPO/helm/taskboard/"
rsync -a --delete "$PROJECT/gitops/apps/" "$REPO/gitops/apps/"
git -C "$REPO" add -A
if git -C "$REPO" diff --cached --quiet; then
  echo "nothing to commit"
else
  git -C "$REPO" -c user.name="gitops-bot" -c user.email="gitops-bot@local" commit -q -m "$MSG"
  git -C "$REPO" log --oneline -1
fi

if ! lsof -iTCP:9418 -sTCP:LISTEN >/dev/null 2>&1; then
  git daemon --reuseaddr --export-all --base-path="$SRC" --port=9418 --detach
  echo "git daemon started: git://host.minikube.internal/taskboard-gitops"
fi
