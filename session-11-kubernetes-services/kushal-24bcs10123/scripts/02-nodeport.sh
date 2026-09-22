#!/usr/bin/env bash
# NodePort: the same port opened on every node.
. "$(dirname "$0")/lib.sh"
x "kubectl apply -f 02-nodeport/app-deployment.yaml"
x "kubectl rollout status deployment/web-app-nodeport"
x "kubectl get pods -l app=web-nodeport -o wide"
x "kubectl apply -f 02-nodeport/service.yaml"
x "kubectl get svc web-service-nodeport"
sleep 5   # give kube-proxy on every node a moment to program the new NodePort rules
x "kubectl get nodes -o wide | awk '{print \$1, \$6}'"
hr "From the Mac (kind maps the control-plane's 30080 to localhost:30080, like minikube ip:30080)"
x "curl -s http://localhost:30080 | grep -o '<title>.*</title>'"
x "curl -sI http://localhost:30080 | head -2"
hr "Every node answers on 30080 - even one that runs no pod of this app"
for n in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  ip=$(kubectl get node "$n" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
  x "docker run --rm --network kind curlimages/curl:8.5.0 -s -m 5 -o /dev/null -w \"$n ($ip):30080 -> HTTP %{http_code}\\n\" http://$ip:30080"
done
x "docker exec kushal-lab-control-plane iptables -t nat -S KUBE-NODEPORTS | grep 30080"
hr "The three ports of a NodePort service"
x "kubectl get svc web-service-nodeport -o jsonpath='port={.spec.ports[0].port} targetPort={.spec.ports[0].targetPort} nodePort={.spec.ports[0].nodePort} clusterIP={.spec.clusterIP}{\"\\n\"}'"
hr "Cleanup"
x "kubectl delete -f 02-nodeport/service.yaml -f 02-nodeport/app-deployment.yaml"
