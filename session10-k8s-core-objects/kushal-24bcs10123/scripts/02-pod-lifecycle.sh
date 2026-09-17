#!/usr/bin/env bash
# Pod lifecycle lab: all 12 situations from pod-lifecycle/README.md, watched live.
. "$(dirname "$0")/lib.sh"
watch_start "$L/02-pod-lifecycle-watch.txt"
phase() { kubectl get pod "$1" -o jsonpath='{.metadata.name}: phase={.status.phase} ready={.status.conditions[?(@.type=="Ready")].status} restarts={.status.containerStatuses[0].restartCount} state={.status.containerStatuses[0].state}' | sed -E 's/"(startedAt|finishedAt)":"[^"]*",?//g; s/"containerID":"[^"]*",?//g'; echo; }

hr "1. Running"
x "kubectl apply -f pod-lifecycle/01-running.yaml"
x "kubectl wait --for=condition=Ready pod/lifecycle-running --timeout=120s"
x "kubectl get pod lifecycle-running"
x "phase lifecycle-running"

hr "2. Pending"
x "kubectl apply -f pod-lifecycle/02-pending.yaml"
x "sleep 8; kubectl get pod lifecycle-pending"
x "kubectl get nodes -o custom-columns='NODE:.metadata.name,ALLOC_MEM:.status.allocatable.memory,ALLOC_CPU:.status.allocatable.cpu'"
x "sed 's/9Gi/900Gi/; s/lifecycle-pending/lifecycle-pending-900gi/' pod-lifecycle/02-pending.yaml | kubectl apply -f -   # request more than any node has"
x "sleep 8; kubectl get pod lifecycle-pending-900gi"
x "kubectl describe pod lifecycle-pending-900gi | grep -A3 '^Events'"
x "phase lifecycle-pending-900gi"

hr "3. Succeeded"
x "kubectl apply -f pod-lifecycle/03-succeeded.yaml"
x "kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/lifecycle-succeeded --timeout=120s"
x "kubectl get pod lifecycle-succeeded"
x "kubectl logs lifecycle-succeeded"
x "phase lifecycle-succeeded"

hr "4. Failed"
x "kubectl apply -f pod-lifecycle/04-failed.yaml"
x "kubectl wait --for=jsonpath='{.status.phase}'=Failed pod/lifecycle-failed --timeout=120s"
x "kubectl get pod lifecycle-failed"
x "kubectl logs lifecycle-failed"
x "kubectl get pod lifecycle-failed -o jsonpath='exit code: {.status.containerStatuses[0].state.terminated.exitCode}{\"\\n\"}'"

hr "5. CrashLoopBackOff"
x "kubectl apply -f pod-lifecycle/05-crashloopbackoff.yaml"
x "sleep 75; kubectl get pod lifecycle-crashloop"
x "kubectl describe pod lifecycle-crashloop | grep -E 'Exit Code|Restart Count|Back-off' | head -4"
x "kubectl logs lifecycle-crashloop"
x "phase lifecycle-crashloop"

hr "6. ImagePullBackOff"
x "kubectl apply -f pod-lifecycle/06-imagepullbackoff.yaml"
x "sleep 45; kubectl get pod lifecycle-image-error"
x "kubectl describe pod lifecycle-image-error | grep -E 'Failed to pull|Back-off pulling|Error: ' | sed -E 's/^ +//' | sort -u | head -3"
x "phase lifecycle-image-error"

hr "7. Readiness probe: Running != Ready"
x "kubectl apply -f pod-lifecycle/07-readiness.yaml"
x "sleep 3; kubectl get pod lifecycle-readiness            # container up, probe not passed yet -> 0/1"
x "kubectl wait --for=condition=Ready pod/lifecycle-readiness --timeout=120s"
x "kubectl get pod lifecycle-readiness"
x "kubectl describe pod lifecycle-readiness | grep -E 'Readiness:'"

hr "8. Liveness probe: failing probe restarts the container"
x "kubectl apply -f pod-lifecycle/08-liveness.yaml"
x "kubectl wait --for=condition=Ready pod/lifecycle-liveness --timeout=120s"
x "kubectl get pod lifecycle-liveness"
x "sleep 60; kubectl get pod lifecycle-liveness            # /tmp/healthy removed after 20s -> RESTARTS went up"
x "kubectl describe pod lifecycle-liveness | grep -E 'Liveness:|Unhealthy|Killing' | sed -E 's/^ +//' | head -4"
x "kubectl get pod lifecycle-liveness -o jsonpath='last state: {.status.containerStatuses[0].lastState.terminated.reason} exit {.status.containerStatuses[0].lastState.terminated.exitCode}{\"\\n\"}'"

hr "9. Startup probe: give a slow app time before liveness/readiness kick in"
x "kubectl apply -f pod-lifecycle/09-startup.yaml"
x "sleep 5; kubectl get pod lifecycle-startup"
x "kubectl wait --for=condition=Ready pod/lifecycle-startup --timeout=180s"
x "kubectl get pod lifecycle-startup"
x "kubectl describe pod lifecycle-startup | grep -E 'Startup:'"

hr "10. Init container"
x "kubectl apply -f pod-lifecycle/10-init-container.yaml"
x "sleep 3; kubectl get pod lifecycle-init                  # Init:0/1 while setup runs"
x "kubectl wait --for=condition=Ready pod/lifecycle-init --timeout=180s"
x "kubectl get pod lifecycle-init"
x "kubectl logs lifecycle-init -c setup"

hr "11. Multi-container pod"
x "kubectl apply -f pod-lifecycle/11-multi-container.yaml"
x "kubectl wait --for=condition=Ready pod/lifecycle-multi-container --timeout=180s"
x "kubectl get pod lifecycle-multi-container"
x "kubectl logs lifecycle-multi-container -c app --tail=1 | sed -E 's#^[0-9/]{10} [0-9:]{8} ##'"
x "kubectl logs lifecycle-multi-container -c sidecar --tail=2"

hr "12. Graceful termination (SIGTERM handled, terminationGracePeriodSeconds: 20)"
x "kubectl apply -f pod-lifecycle/12-termination.yaml"
x "kubectl wait --for=condition=Ready pod/lifecycle-termination --timeout=120s"
kubectl logs -f lifecycle-termination > "$L/02-termination-logs.txt" 2>&1 &
LOGPID=$!
x "SECONDS=0; kubectl delete pod lifecycle-termination; echo \"delete returned after \${SECONDS}s\""
wait $LOGPID 2>/dev/null
x "cat '$L/02-termination-logs.txt'"

hr "Summary: STATUS column vs official phase"
x "kubectl get pods"
x "kubectl get pods -o custom-columns='NAME:.metadata.name,PHASE:.status.phase,READY:.status.conditions[?(@.type==\"Ready\")].status,RESTARTS:.status.containerStatuses[0].restartCount,WAITING_REASON:.status.containerStatuses[0].state.waiting.reason'"

hr "Cleanup"
x "kubectl delete -f pod-lifecycle/ --ignore-not-found"
x "kubectl delete pod lifecycle-pending-900gi --ignore-not-found"
watch_stop
