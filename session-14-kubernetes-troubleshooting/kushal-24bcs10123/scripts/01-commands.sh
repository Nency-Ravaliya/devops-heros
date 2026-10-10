#!/usr/bin/env bash
# 01-commands: hands-on with every troubleshooting command from folders 01-05 (+ explain, top, events).
. "$(dirname "$0")/lib.sh"
N=s14-commands; K="kubectl -n $N"
ns_reset $N

hr "kubectl get"
x "$K apply -f 01-kubectl-get/pod.yaml && wait_ready $N get-demo"
x "$K get pods"
x "$K get pods -o wide"
x "$K get pods --show-labels"
x "$K get pod get-demo -o yaml | sed -n '/^status:/,\$p' | head -40"
x "$K get pod get-demo -o jsonpath='{.status.phase} {.status.podIP} {.spec.nodeName}{\"\\n\"}'"
x "$K get pod get-demo -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[0].image,NODE:.spec.nodeName,IP:.status.podIP'"
x "kubectl get pods -A | head -12                      # -A: every namespace"
x "kubectl get pods -A --field-selector=status.phase!=Running | head"
x "$K get all"
x "kubectl get nodes -o wide | cut -c1-120"
x "kubectl api-resources | grep -E '^(pods|services|deployments|events|endpoints) '"

hr "kubectl describe"
x "$K apply -f 02-kubectl-describe/demo-pod.yaml && wait_ready $N describe-demo"
x "$K describe pod describe-demo"
x "$K describe node kushal-lab-worker | sed -n '/^Allocated resources/,/^Events/p'"

hr "kubectl logs"
x "$K apply -f 03-kubectl-logs/pod.yaml && wait_ready $N logs-demo"
x "sleep 12; $K logs logs-demo"
x "timeout 12 $K logs -f logs-demo; echo '(followed for 12 s, ctrl-c)'"
x "$K logs logs-demo --tail=2"
x "$K logs logs-demo --since=10s --timestamps"
hr "logs -c for a multi-container pod, and --previous after a crash"
cat > /tmp/two-$$.yaml <<Y
apiVersion: v1
kind: Pod
metadata: { name: two-containers }
spec:
  containers:
    - { name: web,     image: nginx:1.27 }
    - { name: sidecar, image: busybox:1.36, command: ["sh","-c","echo sidecar attempt \$(date +%T); exit 1"] }
Y
x "$K apply -f /tmp/two-$$.yaml; sleep 25; $K get pod two-containers"
x "$K logs two-containers 2>&1 | head -3                # error: you must pick a container"
x "$K logs two-containers -c web | tail -2"
x "$K logs two-containers -c sidecar"
x "$K logs two-containers -c sidecar --previous        # the output of the container that already died"
x "$K logs two-containers --all-containers --prefix | tail -4"
rm -f /tmp/two-$$.yaml

hr "kubectl exec"
x "$K apply -f 04-kubectl-exec/pod.yaml && wait_ready $N exec-demo"
x "$K exec exec-demo -- hostname"
x "$K exec exec-demo -- ls /usr/share/nginx/html"
x "$K exec exec-demo -- curl -s -o /dev/null -w 'HTTP %{http_code}\n' localhost"
x "$K exec exec-demo -- nginx -T 2>/dev/null | grep -E 'listen|root' | head -3"
x "$K exec exec-demo -- sh -c 'cat /etc/resolv.conf; echo; env | grep KUBERNETES_SERVICE'"
x "$K exec exec-demo -c nginx -- id"
x "$K exec exec-demo -- bash -c 'echo \"interactive shell would be: kubectl exec -it exec-demo -- bash\"'"

hr "events"
x "$K apply -f 05-events/pod.yaml && wait_ready $N events-demo"
x "$K get events --sort-by=.lastTimestamp | tail -12"
x "$K events --for pod/events-demo"
x "$K events --types=Warning"
x "$K events --types=Warning --for pod/two-containers"
x "$K describe pod events-demo | sed -n '/^Events/,\$p'"
x "timeout 8 $K events --watch >/dev/null; echo '(kubectl events --watch streams new events live)'"

hr "kubectl explain"
x "kubectl explain pod.spec.containers.livenessProbe | head -25"
x "kubectl explain pod.spec.nodeSelector"
x "kubectl explain deployment.spec.strategy.rollingUpdate.maxUnavailable | head -12"
x "kubectl explain pod.spec.containers.resources.limits | head -12"

hr "kubectl top"
x "kubectl top nodes"
x "$K top pods"
x "$K top pods --containers | head"
x "kubectl top pods -A --sort-by=cpu | head -8"

hr "cleanup"
x "kubectl delete ns $N --wait=false"
