#!/usr/bin/env bash
# Session 9 / step 3: follow one `kubectl apply` through the control plane.
cd "$(dirname "$0")/.." && . scripts/lib.sh
cat > /tmp/s9-pod.yaml <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: trace-me
spec:
  containers:
    - name: web
      image: nginx:1.25-alpine
YAML
kubectl delete events --field-selector involvedObject.name=trace-me >/dev/null 2>&1 || true
hr "1. kubectl -> kube-apiserver (REST over HTTPS, -v=6 shows the calls)"
x "kubectl apply -f /tmp/s9-pod.yaml -v=6 2>&1 | grep -E 'GET|POST|PATCH|Response Status' | sed -E 's/^[IWE][0-9]+ [0-9:.]+ +[0-9]+ [a-z_]+\\.go:[0-9]+\\] //; s#https://127.0.0.1:[0-9]+#https://<apiserver>#; s/ in [0-9]+ milliseconds//'"
x "kubectl get pod trace-me -o wide"
hr "2. the object is now in etcd"
x "kubectl -n kube-system exec etcd-kushal-lab-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/pods/default/trace-me --keys-only"
hr "3. scheduler picked a node, kubelet pulled the image and started the container"
x "kubectl wait --for=condition=Ready pod/trace-me --timeout=120s"
x "kubectl get events --field-selector involvedObject.name=trace-me -o custom-columns='SOURCE:.source.component,REASON:.reason,MESSAGE:.message'"
x "kubectl get pod trace-me -o jsonpath='{.spec.nodeName}{\"\\n\"}'"
x "docker exec \$(kubectl get pod trace-me -o jsonpath='{.spec.nodeName}') crictl ps --name web    # the kubelet on that node started the container via containerd"
hr "4. cleanup"
x "kubectl delete pod trace-me"
