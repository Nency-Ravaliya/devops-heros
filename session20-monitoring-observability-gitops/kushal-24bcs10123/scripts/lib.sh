# shared helpers. Every script cd's into session20-monitoring-observability-gitops/ so the commands read
# like the course READMEs (kubectl apply -f 02-metrics-logs-traces/k8s-demo/ ...).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ME="$ROOT/kushal-24bcs10123"
L="$ME/logs"
NS=s20-monitoring                 # my namespace for the monitoring demo
MON=monitoring                    # where kube-prometheus-stack lives on this cluster
cd "$ROOT"
x()  { printf '\n$ %s\n' "$1"; eval "$1" 2>&1; }
hr() { printf '\n############ %s ############\n' "$1"; }
# port-forward helpers: pf <ns> <svc> <local:remote> ; pf_stop
pf()      { kubectl -n "$1" port-forward "svc/$2" "$3" >/dev/null 2>&1 & PFPID=$!; sleep 2; }
pf_stop() { kill "$PFPID" 2>/dev/null; wait "$PFPID" 2>/dev/null; }
# PromQL against the in-cluster Prometheus (expects pf monitoring kube-prometheus-stack-prometheus 19090:9090)
promql() { curl -s -G http://localhost:19090/api/v1/query --data-urlencode "query=$1" | python3 -c '
import sys,json; r=json.load(sys.stdin)["data"]["result"]
for s in r: print(" ", {k:v for k,v in s["metric"].items() if k in ("pod","container","job","instance","path","alertname","alertstate","severity","namespace","__name__")}, "=>", s["value"][1])
print("  (no series)" if not r else "")'; }
# wait until a PromQL alert query returns a series with alertstate=firing (max ~N seconds)
wait_alert() { for _ in $(seq 1 "$2"); do curl -s -G http://localhost:19090/api/v1/query --data-urlencode "query=ALERTS{alertname=\"$1\",alertstate=\"firing\"}" | grep -q '"alertstate":"firing"' && { echo "  $1 is FIRING"; return; }; sleep 5; done; echo "  $1 did not fire in time"; }
