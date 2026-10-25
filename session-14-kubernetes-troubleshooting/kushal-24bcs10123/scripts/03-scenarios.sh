#!/usr/bin/env bash
# 03-scenarios: the "triage gauntlet" - run scenarios/triage_all.sh, then diagnose and fix all five pods.
. "$(dirname "$0")/lib.sh"
N=s14-scenarios; K="kubectl -n $N"
ns_reset $N
# the professor's script uses plain kubectl; run it with my namespace as the context default without touching the shared kubeconfig
export KUBECONFIG=/tmp/kc-$$; kubectl config view --raw --kubeconfig ~/.kube/config > $KUBECONFIG; kubectl config set-context --current --namespace=$N >/dev/null
K="kubectl"
watch_start "$L/03-scenarios-watch.txt" kubectl get pods -l tier=triage-gauntlet

hr "deploy the 5 broken pods"
x "bash scenarios/triage_all.sh"
x "sleep 45; kubectl get pods -l tier=triage-gauntlet"
x "kubectl events --types=Warning | sed 's/  */ /g' | cut -c1-170"

hr "Scenario 1: CrashLoopBackOff"
x "kubectl get pod fail-1-crashloop-pod"
x "kubectl logs fail-1-crashloop-pod --previous 2>/dev/null || kubectl logs fail-1-crashloop-pod"
x "kubectl describe pod fail-1-crashloop-pod | grep -E 'Exit Code|Restart Count|Reason' | sed 's/^ *//'"
x "grep -n DATABASE_URL scenarios/scenario-1-crashloop/broken.yaml"
echo "ROOT CAUSE: the app exits 1 when DATABASE_URL is not set, and the manifest sets no env. FIX: provide the variable (here from a Secret)."
x "kubectl create secret generic db-credentials --from-literal=DATABASE_URL=postgres://app:secret@postgres-db:5432/app"
x "cat kushal-24bcs10123/fixes/scenario-1-crashloop-fixed.yaml | sed -n '/env:/,/command:/p'"
x "kubectl delete pod fail-1-crashloop-pod && kubectl apply -f kushal-24bcs10123/fixes/scenario-1-crashloop-fixed.yaml && wait_ready $N fail-1-crashloop-pod && kubectl logs fail-1-crashloop-pod"
x "kubectl get pod fail-1-crashloop-pod"

hr "Scenario 2: ImagePullBackOff"
x "kubectl get pod fail-2-imagepull-pod"
x "kubectl describe pod fail-2-imagepull-pod | sed -n '/^Events/,\$p' | cut -c1-200"
echo "ROOT CAUSE: image yatri-api-service:v999-invalid-tag-does-not-exist is neither a real repository nor a real tag; docker.io/library/yatri-api-service does not exist. FIX: use the image that actually exists for this app."
x "kubectl delete pod fail-2-imagepull-pod; sed 's#image: yatri-api-service:v999-invalid-tag-does-not-exist#image: nginx:1.27-alpine#' scenarios/scenario-2-imagepull/broken.yaml | kubectl apply -f - && wait_ready $N fail-2-imagepull-pod && kubectl get pod fail-2-imagepull-pod"

hr "Scenario 3: Pending"
x "kubectl get pod fail-3-pending-pod"
x "kubectl describe pod fail-3-pending-pod | sed -n '/^Events/,\$p'"
x "kubectl describe node kushal-lab-worker | sed -n '/^Allocatable/,/^System Info/p' | grep -E 'cpu|memory'"
echo "ROOT CAUSE: requests cpu=500, memory=1000Gi exceed any node (6 CPU, ~15Gi). FIX: realistic requests."
x "kubectl delete pod fail-3-pending-pod; sed 's/cpu: \"500\"/cpu: \"50m\"/; s/memory: \"1000Gi\"/memory: \"32Mi\"/' scenarios/scenario-3-pending/broken.yaml | kubectl apply -f - && wait_ready $N fail-3-pending-pod 180 && kubectl get pod fail-3-pending-pod -o wide"

hr "Scenario 4: DNS failure"
x "kubectl get pod fail-4-dns-failure-pod"
x "kubectl logs fail-4-dns-failure-pod"
x "kubectl exec fail-4-dns-failure-pod -- sh -c 'nslookup postgres-db-wrong-name.production.svc.cluster.local 2>&1 | tail -2; echo; nslookup kubernetes.default.svc.cluster.local | tail -2'"
echo "DIAGNOSIS: DNS itself works (kubernetes.default resolves); only the requested name is wrong - no such service, no such namespace."
echo "FIX: create the real database Service and point the client at <svc>.<ns>.svc.cluster.local."
x "kubectl create deploy postgres-db --image=nginx:1.27-alpine --port=80 && kubectl expose deploy postgres-db --port=5432 --target-port=80 && kubectl rollout status deploy/postgres-db --timeout=120s"
x "kubectl delete pod fail-4-dns-failure-pod; sed 's#postgres-db-wrong-name.production.svc.cluster.local#postgres-db.$N.svc.cluster.local#; s#curl -s --connect-timeout 3#curl -s -o /dev/null -w \"HTTP %{http_code}\\\\n\" --connect-timeout 3#' scenarios/scenario-4-dns-failure/broken.yaml | kubectl apply -f - && wait_ready $N fail-4-dns-failure-pod 120 && sleep 3 && kubectl logs fail-4-dns-failure-pod"
x "kubectl exec fail-4-dns-failure-pod -- nslookup postgres-db | tail -3"

hr "Scenario 5: OOMKilled"
x "kubectl get pod fail-5-oomkilled-pod"
x "kubectl describe pod fail-5-oomkilled-pod | grep -E 'Reason|Exit Code|Restart Count|Limits|memory' | sed 's/^ *//'"
x "kubectl get pod fail-5-oomkilled-pod -o jsonpath='lastState: {.status.containerStatuses[0].lastState.terminated.reason} exit {.status.containerStatuses[0].lastState.terminated.exitCode}{\"\\n\"}'"
x "kubectl logs fail-5-oomkilled-pod --previous"
echo "ROOT CAUSE: the container allocates 100 x 10MiB = 1000MiB with a 20Mi memory limit; the kernel OOM killer kills it (exit 137 = 128+9 SIGKILL), kubelet restarts it -> CrashLoopBackOff with reason OOMKilled. FIX: a limit the program fits in (or fix the leak)."
x "sed -n '/resources:/,\$p' kushal-24bcs10123/fixes/scenario-5-oomkilled-fixed.yaml"
x "kubectl delete pod fail-5-oomkilled-pod && kubectl apply -f kushal-24bcs10123/fixes/scenario-5-oomkilled-fixed.yaml && wait_ready $N fail-5-oomkilled-pod && sleep 20 && kubectl logs fail-5-oomkilled-pod && kubectl top pod fail-5-oomkilled-pod"

hr "all five fixed"
x "kubectl get pods -l tier=triage-gauntlet -o wide"
watch_stop
x "cat $L/03-scenarios-watch.txt"
shot_text 03-scenarios-before-after "triage gauntlet: kubectl get pods -w  (s14-scenarios)" "$L/03-scenarios-watch.txt" 900
rm -f "$KUBECONFIG"; unset KUBECONFIG
hr "cleanup"
x "kubectl delete ns $N --wait=false"
