#!/usr/bin/env bash
# ClusterIP: internal-only virtual IP + DNS name in front of 3 nginx pods.
. "$(dirname "$0")/lib.sh"
hr "Deploy app, service and a curl client"
x "kubectl apply -f 01-clusterip/app-deployment.yaml"
x "kubectl apply -f 01-clusterip/service.yaml"
x "kubectl apply -f 01-clusterip/client-pod.yaml"
x "kubectl rollout status deployment/web-app-clusterip"
x "kubectl wait --for=condition=Ready pod/curl-client --timeout=120s"
x "kubectl get pods -l app=web-clusterip -o wide"
x "kubectl get svc web-service-clusterip"
x "kubectl get endpointslices -l kubernetes.io/service-name=web-service-clusterip"
sleep 5   # let kube-proxy program the rules on every node
hr "Reach it from inside the cluster (port 8080 -> targetPort 80)"
x "kubectl exec curl-client -- curl -s http://web-service-clusterip:8080 | grep -o '<title>.*</title>'"
x "kubectl exec curl-client -- nslookup web-service-clusterip 2>&1 | grep -A1 '^Name'"
x "kubectl exec curl-client -- cat /etc/resolv.conf"
x "kubectl exec curl-client -- curl -s http://web-service-clusterip.default.svc.cluster.local:8080 -o /dev/null -w 'FQDN -> HTTP %{http_code}\\n'"
hr "Not reachable from outside the cluster"
CIP=$(kubectl get svc web-service-clusterip -o jsonpath='{.spec.clusterIP}')
x "curl -s --max-time 3 http://$CIP:8080 || echo \"curl from the Mac to $CIP:8080 failed (exit \$?) - ClusterIP is internal only\""
hr "Load balancing across the 3 pods"
for p in $(kubectl get pods -l app=web-clusterip -o jsonpath='{.items[*].metadata.name}'); do
  kubectl exec "$p" -- sh -c "echo served-by-$p > /usr/share/nginx/html/index.html"
done
echo "(each pod's index.html now contains its own pod name)"
x "for i in \$(seq 1 12); do kubectl exec curl-client -- curl -s http://web-service-clusterip:8080; done | sort | uniq -c"
hr "How kube-proxy implements the VIP (iptables on a node)"
x "docker exec kushal-lab-worker iptables -t nat -S KUBE-SERVICES | grep $CIP"
x "docker exec kushal-lab-worker iptables -t nat -S | grep -E 'KUBE-SEP-.* -j DNAT' | grep web-service-clusterip"
hr "Cleanup"
x "kubectl delete -f 01-clusterip/client-pod.yaml -f 01-clusterip/service.yaml -f 01-clusterip/app-deployment.yaml"
