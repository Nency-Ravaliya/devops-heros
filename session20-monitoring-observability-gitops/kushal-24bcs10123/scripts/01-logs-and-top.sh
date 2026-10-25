#!/usr/bin/env bash
# 01-logs-and-top: the LOGS pillar and the metrics-server view, with the course's 02-metrics-logs-traces/k8s-demo.
. "$(dirname "$0")/lib.sh"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
x "cat 02-metrics-logs-traces/k8s-demo/deployment.yaml"
x "kubectl -n $NS apply -f 02-metrics-logs-traces/k8s-demo/"
x "kubectl -n $NS rollout status deployment/session20-demo --timeout=120s"
x "kubectl -n $NS get pods -o wide"
hr "Logs: what the container printed to stdout, kept by the kubelet on the node"
x "sleep 25; kubectl -n $NS logs deployment/session20-demo"
x "kubectl -n $NS logs deployment/session20-demo --since=15s --timestamps"
x "kubectl -n $NS logs deployment/session20-demo --tail=2"
printf '\n$ kubectl -n %s logs deployment/session20-demo -f --tail=0     # follow for 12 seconds\n' "$NS"
kubectl -n "$NS" logs deployment/session20-demo -f --tail=0 2>&1 | sed 's/^/  (live) /' & FP=$!; sleep 12; kill $FP 2>/dev/null; wait $FP 2>/dev/null
POD=$(kubectl -n $NS get pod -l app=session20-demo -o jsonpath='{.items[0].metadata.name}')
x "docker exec kushal-lab-worker sh -c 'ls /var/log/pods | grep session20-demo'; docker exec kushal-lab-worker2 sh -c 'ls /var/log/pods | grep session20-demo'    # where those lines physically live"
hr "Metrics the easy way: metrics-server -> kubectl top"
x "kubectl top nodes"
x "kubectl top pods -n $NS --containers"
x "kubectl top pods -n $MON | sort -k2 -h -r | head -5     # the monitoring stack itself is the heaviest thing on the cluster"
x "kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/$NS/pods | python3 -c 'import sys,json; [print(p[\"metadata\"][\"name\"], c[\"usage\"]) for p in json.load(sys.stdin)[\"items\"] for c in p[\"containers\"]]'"
hr "Events and describe: the control plane's own log about the pod"
x "kubectl -n $NS get events --sort-by=.lastTimestamp -o custom-columns='LAST:.lastTimestamp,TYPE:.type,REASON:.reason,OBJECT:.involvedObject.name,MESSAGE:.message' | tail -8"
x "kubectl -n $NS describe pod $POD | sed -n '/^Containers:/,/^Conditions:/p' | grep -E 'Image:|State:|Started:|Ready:|Restart Count:'"
x "kubectl -n $NS delete -f 02-metrics-logs-traces/k8s-demo/"
