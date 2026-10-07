# shared helpers. Every script cd's into session-12-ingress-configmaps-secrets/ so the commands
# read exactly like the course READMEs (kubectl apply -f 01-rolling-update/...).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
L="$ROOT/kushal-24bcs10123/logs"
cd "$ROOT"
x()  { printf '\n$ %s\n' "$1"; eval "$1" 2>&1; }
hr() { printf '\n############ %s ############\n' "$1"; }
# background `kubectl get pods -w` into a file, stopped with watch_stop
watch_start() { WATCHFILE="$1"; shift; kubectl get pods "$@" -w > "$WATCHFILE" 2>&1 & WATCHPID=$!; sleep 1; }
watch_stop()  { sleep 3; kill "$WATCHPID" 2>/dev/null; wait "$WATCHPID" 2>/dev/null; }
# hammer a NodePort and record what each request returned (or FAIL)
curl_loop() { # url pattern count sleep
  for _ in $(seq 1 "$3"); do curl -s --max-time 1 "$1" | grep -o "$2" || echo "FAIL (no response)"; sleep "$4"; done
}
# run a one-shot pod, print its logs, delete it (kubectl run --rm -i loses the output when the container exits too fast)
runonce() { local n="$1" img="$2"; shift 2
  kubectl run "$n" --restart=Never --image="$img" -- "$@" >/dev/null
  for _ in $(seq 1 60); do case "$(kubectl get pod "$n" -o jsonpath='{.status.phase}')" in Succeeded|Failed) break;; esac; sleep 2; done
  kubectl logs "$n"; kubectl delete pod "$n" --wait=false >/dev/null; }
