# shared helper: print the command the way a terminal would, then run it
x() { printf '\n$ %s\n' "$1"; eval "$1" 2>&1; }
hr() { printf '\n############ %s ############\n' "$1"; }
# run a one-shot pod, print its logs, delete it (kubectl run --rm -i loses the output when the container exits too fast)
runonce() { local n="$1" img="$2"; shift 2
  kubectl run "$n" --restart=Never --image="$img" -- "$@" >/dev/null
  for _ in $(seq 1 60); do case "$(kubectl get pod "$n" -o jsonpath='{.status.phase}')" in Succeeded|Failed) break;; esac; sleep 2; done
  kubectl logs "$n"; kubectl delete pod "$n" --wait=false >/dev/null; }
