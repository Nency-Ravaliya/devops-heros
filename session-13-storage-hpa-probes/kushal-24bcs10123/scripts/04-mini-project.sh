#!/usr/bin/env bash
# 04-mini-project: production-webapp (PVC + probes + HPA) from mini-project/, with the 3 bonus challenges.
. "$(dirname "$0")/lib.sh"
N=production-webapp; K="kubectl -n $N"
kubectl delete ns $N --ignore-not-found --wait=true >/dev/null 2>&1
cd mini-project

hr "5.1 namespace"
x "kubectl apply -f namespace.yaml"
hr "5.2 PVC"
x "kubectl apply -f pvc.yaml"
x "$K get pvc    # Pending with WaitForFirstConsumer until a pod mounts it"
hr "5.3 deployment + service"
x "cat deployment.yaml"
x "kubectl apply -f deployment.yaml && kubectl apply -f service.yaml"
x "$K rollout status deploy/web-app --timeout=180s"
x "$K get pods -o wide"
x "$K get pvc"
x "$K get pods -o jsonpath='{range .items[*]}{.metadata.name}{\" -> \"}{.spec.nodeName}{\"\\n\"}{end}'   # RWO local-path volume: both replicas must land on the same node"
hr "5.4 HPA"
x "kubectl apply -f hpa.yaml"
x "sleep 30; $K get hpa"

hr "Task 1: storage persistence"
POD=$($K get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
x "$K exec $POD -- sh -c 'echo \"Student: Kushal Talati (24BCS10123)\" > /data/student.txt'"
x "$K exec $POD -- cat /data/student.txt"
x "$K delete pod $POD"
x "$K rollout status deploy/web-app --timeout=120s"
NEW=$($K get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
x "$K get pods"
x "$K exec $NEW -- cat /data/student.txt     # new pod, same PVC, same file"
hr "the other replica sees the same volume too"
OTHER=$($K get pods -l app=web-app -o jsonpath='{.items[1].metadata.name}')
x "$K exec $OTHER -- cat /data/student.txt"

hr "Task 2: service verification"
$K port-forward svc/web-service 18081:80 >/dev/null 2>&1 & PF=$!; sleep 2
x "curl -s http://localhost:18081 | head -5"
shot_url 04-mini-webapp-browser http://localhost:18081/
kill $PF 2>/dev/null

hr "Task 3: HPA elastic scaling"
watch_start "$L/04-mini-hpa-watch.txt" $K get hpa
for i in 1 2 3; do
x "$K run load-generator-$i --image=busybox:1.36 --restart=Never -- /bin/sh -c 'while true; do wget -q -O- http://web-service >/dev/null; done'"
done
for i in $(seq 1 8); do printf '\n--- t+%ds\n' $((i*30)); sleep 30; $K get hpa web-app-hpa --no-headers; $K top pods -l app=web-app 2>&1 | tail -n +2; done
x "$K get pods -l app=web-app"
x "$K describe hpa web-app-hpa | sed -n '/^Events/,\$p'"

hr "Challenge 1: target 50% -> 30%"
x "sed 's/averageUtilization: 50/averageUtilization: 30/' hpa.yaml | kubectl apply -f -"
x "sleep 45; $K get hpa web-app-hpa"
x "$K delete pod load-generator-1 load-generator-2 load-generator-3 --wait=false"
x "kubectl apply -f hpa.yaml     # back to 50%"
watch_stop

hr "Challenge 2: readiness path -> /does-not-exist"
x "$K patch deploy web-app --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/path\",\"value\":\"/does-not-exist\"}]'"
x "sleep 40; $K get pods -l app=web-app"
x "$K get endpoints web-service"
x "$K describe deploy web-app | grep -E 'Readiness|Replicas:'"
hr "Challenge 3: liveness path -> /crash"
x "kubectl apply -f deployment.yaml >/dev/null; $K rollout status deploy/web-app --timeout=120s >/dev/null"
x "$K patch deploy web-app --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/livenessProbe/httpGet/path\",\"value\":\"/crash\"}]'"
watch_start "$L/04-mini-liveness-watch.txt" $K get pods -l app=web-app
x "sleep 75; $K get pods -l app=web-app"
x "$K describe pods -l app=web-app | grep -E 'Liveness probe failed|Restart Count' | sed 's/^ *//' | sort | uniq -c | head"
watch_stop
x "cat $L/04-mini-liveness-watch.txt"
x "kubectl apply -f deployment.yaml && $K rollout status deploy/web-app --timeout=120s"

hr "final state"
x "$K get all,pvc,hpa"
shot_text 04-mini-hpa-watch "kubectl get hpa -w  (production-webapp)" "$L/04-mini-hpa-watch.txt" 500
hr "cleanup"
x "kubectl delete ns $N --wait=false"
