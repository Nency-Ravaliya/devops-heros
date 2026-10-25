# shared helpers. Every script cd's into session-15-helm/ so the commands read exactly like the
# course READMEs (helm install web-app ./07-install-upgrade/app-chart ...).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ME="$ROOT/kushal-24bcs10123"
L="$ME/logs"
NS=s15-helm            # everything goes into one namespace so my releases never clash with other work on the cluster
cd "$ROOT"
export HELM_NAMESPACE="$NS"   # same as writing -n s15-helm on every helm command
x()  { printf '\n$ %s\n' "$1"; eval "$1" 2>&1; }
hr() { printf '\n############ %s ############\n' "$1"; }
# wait until a deployment reports all replicas ready (or give up after ~2 min)
ready() { kubectl -n "$NS" rollout status deployment/"$1" --timeout=120s 2>&1 | tail -1; }
# the pods of a release as "name image status" lines
pods() { kubectl -n "$NS" get pods -l "app=$1" -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[0].image,STATUS:.status.phase,READY:.status.containerStatuses[0].ready' 2>&1; }
