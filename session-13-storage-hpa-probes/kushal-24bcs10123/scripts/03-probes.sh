#!/usr/bin/env bash
# 03-probes: liveness, readiness, startup from 05-probes/, then break each one on purpose.
. "$(dirname "$0")/lib.sh"
N=s13-probes; K="kubectl -n $N"
ns_reset $N
watch_start "$L/03-probes-watch.txt" $K get pods

hr "1. liveness"
x "cat 05-probes/liveness.yaml"
x "$K apply -f 05-probes/liveness.yaml && wait_ready $N liveness-demo"
x "$K describe pod liveness-demo | grep -E 'Liveness|Restart Count'"
hr "break it: remove index.html, nginx answers 403 on / -> probe fails 3 times -> restart"
x "$K exec liveness-demo -- rm /usr/share/nginx/html/index.html"
x "$K exec liveness-demo -- curl -s -o /dev/null -w 'nginx now answers %{http_code}\n' localhost/"
x "sleep 30; $K get pod liveness-demo"
x "$K describe pod liveness-demo | grep -E 'Unhealthy|Killing' | sed 's/^ *//' | head -5"
x "$K exec liveness-demo -- curl -s -o /dev/null -w 'after restart: %{http_code}\n' localhost/   # fresh container, index.html is back"

hr "2. readiness"
x "cat 05-probes/readiness.yaml"
x "$K apply -f 05-probes/readiness.yaml && wait_ready $N readiness-demo"
x "$K expose pod readiness-demo --name=readiness-service --port=80"
x "$K get endpoints readiness-service"
hr "break it: readiness fails -> pod stays Running, READY 0/1, endpoint removed, NO restart"
x "$K exec readiness-demo -- rm /usr/share/nginx/html/index.html"
x "sleep 20; $K get pod readiness-demo"
x "$K get endpoints readiness-service"
x "$K describe pod readiness-demo | grep -E 'Unhealthy' | sed 's/^ *//' | tail -1"
hr "fix it in place -> endpoint comes back without a restart"
x "$K exec readiness-demo -- sh -c 'echo ok > /usr/share/nginx/html/index.html'"
x "sleep 12; $K get pod readiness-demo; $K get endpoints readiness-service"

hr "3. startup probe protects slow starters"
x "cat 05-probes/startup.yaml"
x "$K apply -f 05-probes/startup.yaml && wait_ready $N startup-demo"
x "$K describe pod startup-demo | grep -E 'Startup|Liveness|Readiness'"
hr "a slow app without startupProbe gets killed by liveness; with it, it is allowed up to 30x2=60 s"
cat > /tmp/slow-$$.yaml <<Y
apiVersion: v1
kind: Pod
metadata: { name: slow-no-startup }
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh","-c","echo starting; sleep 40; echo ready; touch /tmp/up; sleep 3600"]
      livenessProbe: { exec: { command: ["cat","/tmp/up"] }, periodSeconds: 5, failureThreshold: 3 }
---
apiVersion: v1
kind: Pod
metadata: { name: slow-with-startup }
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh","-c","echo starting; sleep 40; echo ready; touch /tmp/up; sleep 3600"]
      startupProbe:  { exec: { command: ["cat","/tmp/up"] }, periodSeconds: 2, failureThreshold: 30 }
      livenessProbe: { exec: { command: ["cat","/tmp/up"] }, periodSeconds: 5, failureThreshold: 3 }
Y
x "cat /tmp/slow-$$.yaml"
x "$K apply -f /tmp/slow-$$.yaml"
x "sleep 70; $K get pods slow-no-startup slow-with-startup"
x "$K describe pod slow-no-startup | grep -cE 'Killing'; $K describe pod slow-with-startup | grep -cE 'Killing'"
rm -f /tmp/slow-$$.yaml
watch_stop
x "grep -E 'liveness-demo|readiness-demo|slow-' $L/03-probes-watch.txt"
shot_text 03-probes-watch "kubectl get pods -w  (s13-probes)" "$L/03-probes-watch.txt" 600
hr "cleanup"
x "kubectl delete ns $N --wait=false"
