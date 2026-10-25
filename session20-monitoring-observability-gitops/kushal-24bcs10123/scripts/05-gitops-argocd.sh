#!/usr/bin/env bash
# 05-gitops-argocd: Git is the desired state, Argo CD is the reconciler, the cluster is the actual state.
# The manifests live in my fork on branch gitops-kushal-s20 (path kushal-24bcs10123/gitops/app); this script edits
# that branch through a git worktree at $WT, pushes, and watches Argo CD react.
. "$(dirname "$0")/lib.sh"
WT=/Users/kushalscaler/devops-heros-s20
G="$WT/session20-monitoring-observability-gitops/kushal-24bcs10123/gitops"
GIT="git -C $WT -c user.name=kushaltalati -c user.email=kushaltalati@users.noreply.github.com"
APPNS=s20-gitops
x "kubectl -n argocd get pods"
x "kubectl -n argocd get deploy argocd-server -o jsonpath='Argo CD image: {.spec.template.spec.containers[0].image}{\"\\n\"}'"
hr "The Git side: what is in the repo"
x "$GIT log --oneline -3 -- session20-monitoring-observability-gitops/kushal-24bcs10123/gitops"
x "$GIT ls-remote --heads origin gitops-kushal-s20"
x "find $G -type f | sed 's|$WT/||' | sort"
x "cat $G/app/deployment.yaml"
x "cat $G/argocd-application.yaml"
hr "Log the CLI in (through a port-forward to argocd-server)"
pf argocd argocd-server 19443:443
PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
x "argocd login localhost:19443 --insecure --username admin --password '***' --grpc-web >/dev/null && echo 'logged in (password read from secret argocd-initial-admin-secret, not shown)'" 2>/dev/null
argocd login localhost:19443 --insecure --username admin --password "$PW" --grpc-web >/dev/null 2>&1 && echo "  argocd login ok"
x "argocd version --short"
hr "Step 5: register the Application (the only thing I apply by hand)"
x "kubectl apply -f $G/argocd-application.yaml"
for _ in $(seq 1 60); do s=$(kubectl -n argocd get application session20-mini -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null); [ "$s" = "Synced/Healthy" ] && break; sleep 5; done
x "kubectl -n argocd get applications"
x "argocd app get session20-mini --grpc-web | sed -n '1,40p'"
hr "Step 6: the cluster now has what Git says (I never ran kubectl apply on these files)"
x "kubectl -n $APPNS get all"
x "kubectl -n $APPNS get deploy session20-mini -o jsonpath='managed by: {.metadata.labels}{\"\\n\"}annotations: {.metadata.annotations}{\"\\n\"}' | cut -c1-300"
pf2() { kubectl -n "$APPNS" port-forward svc/session20-mini 19081:80 >/dev/null 2>&1 & PF2=$!; sleep 2; }
pf2; x "curl -s -m 5 http://localhost:19081 | grep -o '<title>.*</title>'"; kill $PF2 2>/dev/null
TOKEN=$(curl -sk -X POST https://localhost:19443/api/v1/session -H 'Content-Type: application/json' -d "{\"username\":\"admin\",\"password\":\"$PW\"}" | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')
node "$ME/scripts/shot.mjs" "https://localhost:19443/applications/argocd/session20-mini?view=tree&resource=" "$ME/screenshots/05-argocd-app-synced-2-replicas.png" "argocd.token=$TOKEN" 9000
hr "Step 7: change Git (replicas 2 -> 3), push, do NOT touch the cluster"
x "sed -i '' 's/replicas: 2/replicas: 3/' $G/app/deployment.yaml && grep -n replicas $G/app/deployment.yaml"
x "$GIT add -A && $GIT commit -q -m 'scale session20-mini to three replicas' && $GIT push -q origin gitops-kushal-s20 && $GIT log --oneline -1"
kubectl -n "$APPNS" get deploy session20-mini -w > "$L/05-deploy-watch-git-change.txt" 2>&1 & W=$!
echo "  waiting for Argo CD to notice the new commit (it polls the repo every 3 minutes by default; no manual sync) ..."
t0=$SECONDS; for _ in $(seq 1 60); do [ "$(kubectl -n $APPNS get deploy session20-mini -o jsonpath='{.status.readyReplicas}')" = "3" ] && break; sleep 5; done
echo "  cluster reached 3/3 after $((SECONDS-t0))s"
sleep 3; kill $W 2>/dev/null
x "cat $L/05-deploy-watch-git-change.txt"
x "kubectl -n $APPNS get pods"
x "argocd app get session20-mini --grpc-web | grep -E 'Sync Status|Health Status|Revision|Repo|Target'"
x "argocd app history session20-mini --grpc-web"
hr "Step 8: self-healing - drift the cluster by hand, Argo CD puts it back"
x "kubectl -n $APPNS scale deployment session20-mini --replicas=1"
kubectl -n "$APPNS" get deploy session20-mini -w > "$L/05-deploy-watch-selfheal.txt" 2>&1 & W=$!
t0=$SECONDS; for _ in $(seq 1 60); do [ "$(kubectl -n $APPNS get deploy session20-mini -o jsonpath='{.spec.replicas}')" = "3" ] && break; sleep 2; done
echo "  spec.replicas is back to 3 after $((SECONDS-t0))s"
sleep 8; kill $W 2>/dev/null
x "cat $L/05-deploy-watch-selfheal.txt"
x "kubectl -n $APPNS get deploy session20-mini"
x "kubectl -n argocd get application session20-mini -o jsonpath='{range .status.history[*]}revision {.id}: {.revision} deployed {.deployedAt}{\"\\n\"}{end}'"
x "kubectl -n argocd get events --field-selector involvedObject.name=session20-mini -o custom-columns='LAST:.lastTimestamp,REASON:.reason,MESSAGE:.message' | tail -6 | cut -c1-200"
node "$ME/scripts/shot.mjs" "https://localhost:19443/applications/argocd/session20-mini?view=tree&resource=" "$ME/screenshots/05-argocd-app-3-replicas.png" "argocd.token=$TOKEN" 9000
node "$ME/scripts/shot.mjs" "https://localhost:19443/applications" "$ME/screenshots/05-argocd-applications-list.png" "argocd.token=$TOKEN" 7000
hr "Step 9: observe"
x "kubectl -n $APPNS logs deployment/session20-mini --tail=3 2>&1 | cut -c1-120"
x "argocd app diff session20-mini --grpc-web && echo 'no diff: Git == cluster'"
hr "Cleanup: deleting the Application with --cascade removes everything it created; the Git branch stays"
x "argocd app delete session20-mini --cascade --yes --grpc-web"
for _ in $(seq 1 30); do kubectl get ns $APPNS >/dev/null 2>&1 || break; sleep 3; done
x "kubectl get ns $APPNS 2>&1"
x "kubectl -n argocd get applications 2>&1"
argocd logout localhost:19443 >/dev/null 2>&1; pf_stop
