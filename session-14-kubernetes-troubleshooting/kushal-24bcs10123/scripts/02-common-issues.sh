#!/usr/bin/env bash
# 02-common-issues: folders 06-09 plus the states the doc lists that have no folder
# (ErrImagePull, ContainerCreating, pod networking, configuration). Identify -> investigate -> root cause -> fix -> verify.
. "$(dirname "$0")/lib.sh"
N=s14-issues; K="kubectl -n $N"
ns_reset $N
watch_start "$L/02-common-issues-watch.txt" $K get pods

hr "A. CrashLoopBackOff (06-crashloopbackoff)"
x "cat 06-crashloopbackoff/broken-pod.yaml"
x "$K apply -f 06-crashloopbackoff/broken-pod.yaml"
x "sleep 60; $K get pod crash-demo"
x "$K describe pod crash-demo | grep -E 'State|Reason|Exit Code|Restart Count|Back-off' | sed 's/^ *//'"
x "$K logs crash-demo"
x "$K logs crash-demo --previous"
x "$K get pod crash-demo -o jsonpath='restartPolicy={.spec.restartPolicy} exitCode={.status.containerStatuses[0].lastState.terminated.exitCode}{\"\\n\"}'"
echo "ROOT CAUSE: the container command runs 'exit 1' after printing the error, so the process ends with a non-zero code and restartPolicy Always restarts it with growing back-off."
x "diff 06-crashloopbackoff/broken-pod.yaml 06-crashloopbackoff/fixed-pod.yaml"
x "$K delete pod crash-demo && $K apply -f 06-crashloopbackoff/fixed-pod.yaml && wait_ready $N crash-demo"
x "$K get pod crash-demo; $K logs crash-demo"

hr "B. ErrImagePull -> ImagePullBackOff (07-imagepullbackoff)"
x "cat 07-imagepullbackoff/broken-pod.yaml"
x "$K apply -f 07-imagepullbackoff/broken-pod.yaml"
x "for i in 1 2 3 4 5 6; do sleep 5; $K get pod image-demo --no-headers; done     # ErrImagePull first, then ImagePullBackOff"
x "$K describe pod image-demo | sed -n '/^Events/,\$p'"
x "$K get pod image-demo -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}: {.status.containerStatuses[0].state.waiting.message}{\"\\n\"}'"
x "docker manifest inspect nginx:this-image-does-not-exist 2>&1 | head -2       # confirm from outside the cluster: the tag does not exist"
echo "ROOT CAUSE: image tag nginx:this-image-does-not-exist is not in the registry. ErrImagePull is the single failed attempt, ImagePullBackOff is kubelet waiting before retrying."
x "$K delete pod image-demo && $K apply -f 07-imagepullbackoff/fixed-pod.yaml && wait_ready $N image-demo && $K get pod image-demo"
hr "B2. same symptom, different cause: private registry without credentials"
x "$K run private-demo --image=ghcr.io/kushaltalati/does-not-exist:1.0 --restart=Never; sleep 20; $K get pod private-demo"
x "$K describe pod private-demo | grep -E 'Failed to pull|unauthorized|denied|not found' | sed 's/^ *//' | head -2"
x "$K delete pod private-demo --wait=false"

hr "C. Pending (08-pending-pods) - nodeSelector that matches nothing"
x "cat 08-pending-pods/broken-pod.yaml"
x "$K apply -f 08-pending-pods/broken-pod.yaml; sleep 10; $K get pod pending-demo"
x "$K describe pod pending-demo | sed -n '/^Events/,\$p'"
x "kubectl get nodes --show-labels | tr ',' '\n' | grep hostname"
echo "ROOT CAUSE: nodeSelector kubernetes.io/hostname=node-that-does-not-exist; no node carries that label so the scheduler has 0 candidates."
x "$K delete pod pending-demo && $K apply -f 08-pending-pods/fixed-pod.yaml && wait_ready $N pending-demo && $K get pod pending-demo -o wide"
hr "C2. Pending because of resources (scenarios/scenario-3-pending)"
x "$K apply -f scenarios/scenario-3-pending/broken.yaml; sleep 10; $K get pod fail-3-pending-pod"
x "$K describe pod fail-3-pending-pod | grep -A2 '^Events' | tail -1 | sed 's/^ *//'"
x "kubectl get nodes -o custom-columns='NODE:.metadata.name,ALLOC_CPU:.status.allocatable.cpu,ALLOC_MEM:.status.allocatable.memory'"
echo "ROOT CAUSE: the pod requests 500 CPUs and 1000Gi; every node has 6 CPUs / ~15Gi allocatable -> 'Insufficient cpu, Insufficient memory'."
x "sed 's/cpu: \"500\"/cpu: \"100m\"/; s/memory: \"1000Gi\"/memory: \"64Mi\"/' scenarios/scenario-3-pending/broken.yaml | $K apply -f -   # fixing requests in place is allowed? no:"
x "$K delete pod fail-3-pending-pod; sed 's/cpu: \"500\"/cpu: \"100m\"/; s/memory: \"1000Gi\"/memory: \"64Mi\"/' scenarios/scenario-3-pending/broken.yaml | $K apply -f - && wait_ready $N fail-3-pending-pod 180 && $K get pod fail-3-pending-pod"

hr "D. ContainerCreating - a volume that points at a missing ConfigMap"
cat > /tmp/cc-$$.yaml <<Y
apiVersion: v1
kind: Pod
metadata: { name: creating-demo }
spec:
  containers:
    - name: nginx
      image: nginx:1.27
      volumeMounts: [{ name: cfg, mountPath: /etc/app }]
  volumes:
    - name: cfg
      configMap: { name: app-config }
Y
x "cat /tmp/cc-$$.yaml"
x "$K apply -f /tmp/cc-$$.yaml; sleep 15; $K get pod creating-demo"
x "$K describe pod creating-demo | sed -n '/^Events/,\$p'"
x "$K get configmap app-config"
echo "ROOT CAUSE: the pod mounts configMap app-config, which does not exist, so kubelet cannot build the container sandbox volumes and the pod stays ContainerCreating (no restart, no crash)."
x "$K create configmap app-config --from-literal=MODE=prod"
x "wait_ready $N creating-demo 90; $K get pod creating-demo; $K exec creating-demo -- cat /etc/app/MODE; echo"
rm -f /tmp/cc-$$.yaml

hr "E. Service connectivity (09-service-dns-troubleshooting)"
x "$K apply -f 09-service-dns-troubleshooting/deployment.yaml && $K rollout status deploy/web --timeout=120s"
x "cat 09-service-dns-troubleshooting/service.yaml"
x "$K apply -f 09-service-dns-troubleshooting/service.yaml"
x "$K get svc web-service; $K get endpoints web-service"
x "docker manifest inspect registry.k8s.io/e2e-test-images/dnsutils:1.3 2>&1 | tail -1    # the course image does not resolve any more, so I use busybox (has nslookup/wget)"
x "sed 's#registry.k8s.io/e2e-test-images/dnsutils:1.3#busybox:1.36#' 09-service-dns-troubleshooting/dns-test-pod.yaml | $K apply -f - && wait_ready $N dns-test 180"
x "$K exec dns-test -- sh -c 'wget -qO- -T 3 http://web-service 2>&1 | head -2 || echo CONNECTION FAILED'"
x "$K describe svc web-service | grep -E 'Selector|Endpoints|TargetPort'"
x "$K get pods -l app=web --show-labels"
echo "ROOT CAUSE: the Service selector is app=web-ahsgdf but the pods carry app=web, so the endpoint list is empty and the ClusterIP has nowhere to send traffic."
x "$K patch svc web-service -p '{\"spec\":{\"selector\":{\"app\":\"web\"}}}'"
x "sleep 2; $K get endpoints web-service"
x "$K exec dns-test -- sh -c 'wget -qO- -T 3 http://web-service | grep title'"
hr "E2. endpoints exist but targetPort is wrong"
x "$K patch svc web-service -p '{\"spec\":{\"ports\":[{\"port\":80,\"targetPort\":8080}]}}'"
x "$K get endpoints web-service    # endpoints now say :8080 - nothing listens there"
x "$K exec dns-test -- sh -c 'wget -qO- -T 3 http://web-service 2>&1 | tail -1'"
x "$K exec web-\$($K get pods -l app=web -o jsonpath='{.items[0].metadata.name}' | cut -d- -f2-) -- sh -c 'cat /proc/net/tcp | awk \"NR>1{print \\\$2}\" | cut -d: -f2 | sort -u | while read p; do echo listening on \$((16#\$p)); done'"
x "$K patch svc web-service -p '{\"spec\":{\"ports\":[{\"port\":80,\"targetPort\":80}]}}' && sleep 2 && $K exec dns-test -- sh -c 'wget -qO- -T 3 http://web-service | grep title'"
x "$K apply -f 09-service-dns-troubleshooting/broken-service.yaml; $K get endpoints broken-service; $K describe svc broken-service | grep Selector"

hr "F. DNS"
x "$K exec dns-test -- nslookup web-service"
x "$K exec dns-test -- nslookup web-service.$N.svc.cluster.local"
x "$K exec dns-test -- cat /etc/resolv.conf"
x "kubectl get svc -n kube-system kube-dns"
x "kubectl get pods -n kube-system -l k8s-app=kube-dns"
x "$K exec dns-test -- nslookup web-service.default.svc.cluster.local 2>&1 | tail -2     # wrong namespace -> NXDOMAIN"
x "$K exec dns-test -- nslookup kubernetes.default"
x "$K apply -f scenarios/scenario-4-dns-failure/broken.yaml && wait_ready $N fail-4-dns-failure-pod 180"
x "$K logs fail-4-dns-failure-pod"
x "$K exec fail-4-dns-failure-pod -- sh -c 'nslookup postgres-db-wrong-name.production.svc.cluster.local 2>&1 | tail -2'"
x "kubectl logs -n kube-system -l k8s-app=kube-dns --tail=3"
echo "ROOT CAUSE: the client asks for postgres-db-wrong-name in namespace production; neither the service nor the namespace exists, CoreDNS correctly answers NXDOMAIN. Fix = point the client at the real service name (shown in 03-scenarios)."

hr "G. Pod networking - reach the pod IP directly, bypassing the Service"
x "$K get pods -l app=web -o wide --no-headers | awk '{print \$1, \$6, \$7}'"
IP=$($K get pods -l app=web -o jsonpath='{.items[0].status.podIP}')
x "$K exec dns-test -- sh -c 'wget -qO- -T 3 http://$IP | grep title'      # pod-to-pod across nodes works (kindnet CNI)"
x "$K exec dns-test -- sh -c 'wget -qO- -T 3 http://$IP:8080 2>&1 | tail -1'   # wrong port on the pod itself"
x "kubectl get pods -n kube-system -l app=kindnet -o wide --no-headers | awk '{print \$1, \$3, \$7}'"
x "kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers | awk '{print \$1, \$3}'"

hr "H. Configuration issues"
x "$K create configmap web-config --from-literal=GREETING=hello"
cat > /tmp/cfg-$$.yaml <<Y
apiVersion: v1
kind: Pod
metadata: { name: config-demo }
spec:
  restartPolicy: Never
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh","-c","echo GREETING=\$GREETING; sleep 3600"]
      env:
        - name: GREETING
          valueFrom: { configMapKeyRef: { name: web-config, key: GRETING } }
Y
x "cat /tmp/cfg-$$.yaml"
x "$K apply -f /tmp/cfg-$$.yaml; sleep 15; $K get pod config-demo"
x "$K describe pod config-demo | sed -n '/^Events/,\$p'"
echo "ROOT CAUSE: the env var references key GRETING (typo) in ConfigMap web-config; the key is GREETING. CreateContainerConfigError = the container cannot even be created."
x "$K delete pod config-demo; sed 's/GRETING/GREETING/' /tmp/cfg-$$.yaml | $K apply -f - && wait_ready $N config-demo && $K logs config-demo"
hr "H2. wrong command"
x "$K run bad-cmd --image=nginx:1.27 --restart=Never --command -- /usr/bin/does-not-exist; sleep 10; $K get pod bad-cmd"
x "$K describe pod bad-cmd | grep -E 'Reason|Message|Exit Code' | sed 's/^ *//' | head -4"
rm -f /tmp/cfg-$$.yaml

watch_stop
x "cat $L/02-common-issues-watch.txt"
shot_text 02-common-issues-watch "kubectl get pods -w  (s14-issues)" "$L/02-common-issues-watch.txt" 900
hr "cleanup"
x "kubectl delete ns $N --wait=false"
