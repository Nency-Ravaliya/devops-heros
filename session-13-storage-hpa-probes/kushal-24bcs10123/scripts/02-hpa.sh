#!/usr/bin/env bash
# 02-hpa: the course 04-hpa demo - deploy, HPA, load, watch it scale out and back in.
. "$(dirname "$0")/lib.sh"
N=s13-hpa; K="kubectl -n $N"
ns_reset $N

hr "1. deploy the application + service"
x "cat 04-hpa/deployment.yaml"
x "$K apply -f 04-hpa/deployment.yaml && $K apply -f 04-hpa/service.yaml"
x "$K rollout status deploy/hpa-demo --timeout=120s"
x "$K get deploy,svc,pods -o wide"

hr "2. metrics server is working"
x "kubectl get deploy metrics-server -n kube-system"
x "kubectl top nodes"
x "sleep 20; $K top pods"

hr "3. configure the HPA"
x "cat 04-hpa/hpa.yaml"
x "$K apply -f 04-hpa/hpa.yaml"
x "sleep 20; $K get hpa"
x "$K describe hpa hpa-demo | sed -n '/^Metrics/,/^Events/p'"

hr "4. load generator (in-cluster, 3 busybox pods looping wget)"
watch_start "$L/02-hpa-watch.txt" $K get hpa
for i in 1 2 3; do
x "$K run load-generator-$i --image=busybox:1.36 --restart=Never -- /bin/sh -c 'while true; do wget -q -O- http://hpa-demo-service >/dev/null; done'"
done
x "$K get pods"
hr "5. observe CPU and scaling (one sample every 30 s)"
for i in $(seq 1 10); do
  printf '\n--- t+%ds\n' $((i*30)); sleep 30
  $K top pods -l app=hpa-demo 2>&1
  $K get hpa hpa-demo --no-headers
  $K get pods -l app=hpa-demo --no-headers | awk '{print "   "$1, $3}'
done
x "$K describe hpa hpa-demo | sed -n '/^Metrics/,\$p'"
x "$K get deploy hpa-demo"

hr "6. the course host script hpa/load_generator.sh (10 parallel curl loops through a port-forward)"
$K port-forward svc/hpa-demo-service 18080:80 >/dev/null 2>&1 & PF=$!; sleep 2
x "bash hpa/load_generator.sh http://localhost:18080/ > /tmp/lg-$$.txt 2>&1 & echo started pid \$!; sleep 60; pkill -f 'hpa/load_generator.sh'; pkill -f 'curl -s http://localhost:18080'; echo '(script and its 10 curl workers killed after 60 s - the loops are infinite by design)'; head -8 /tmp/lg-$$.txt"
x "$K top pods -l app=hpa-demo"
kill $PF 2>/dev/null; rm -f /tmp/lg-$$.txt
x "$K get hpa hpa-demo"

hr "7. stop the load, wait for scale-down (default stabilization window is 300 s)"
x "$K delete pod load-generator-1 load-generator-2 load-generator-3 --wait=false"
for i in $(seq 1 14); do
  printf '\n--- t+%ds after load stopped\n' $((i*30)); sleep 30
  $K get hpa hpa-demo --no-headers
  $K get pods -l app=hpa-demo --no-headers | wc -l | awk '{print "   pods:", $1}'
done
x "$K describe hpa hpa-demo | sed -n '/^Events/,\$p'"
watch_stop
x "cat $L/02-hpa-watch.txt"

shot_text 02-hpa-watch "kubectl get hpa -w  (s13-hpa)" "$L/02-hpa-watch.txt" 700
hr "cleanup"
x "kubectl delete ns $N --wait=false"
