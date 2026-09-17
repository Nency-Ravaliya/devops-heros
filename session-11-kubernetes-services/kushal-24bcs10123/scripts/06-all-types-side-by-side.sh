#!/usr/bin/env bash
# One deployment exposed as all five Service types at once, to compare the columns of `kubectl get svc`.
. "$(dirname "$0")/lib.sh"
x "kubectl create deployment cmp --image=nginx:1.25-alpine --replicas=2"
x "kubectl rollout status deployment/cmp"
x "kubectl expose deployment cmp --name=cmp-clusterip    --port=80 --type=ClusterIP"
x "kubectl expose deployment cmp --name=cmp-nodeport     --port=80 --type=NodePort"
x "kubectl expose deployment cmp --name=cmp-loadbalancer --port=80 --type=LoadBalancer"
x "kubectl create service externalname cmp-externalname --external-name=nencyravaliya.me"
x "kubectl create service clusterip cmp-headless --clusterip=None --tcp=80 && kubectl set selector svc cmp-headless app=cmp"
x "kubectl get svc -l app=cmp; kubectl get svc cmp-externalname cmp-headless"
x "kubectl get endpointslices -o custom-columns='SERVICE:.metadata.labels.kubernetes\\.io/service-name,ADDRESSES:.endpoints[*].addresses[0]' | grep cmp"
x "kubectl delete deployment cmp; kubectl delete svc cmp-clusterip cmp-nodeport cmp-loadbalancer cmp-externalname cmp-headless"
