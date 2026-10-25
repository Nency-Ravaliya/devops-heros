#!/usr/bin/env bash
# 04-mini-project: deploy -> observe -> break -> investigate -> fix -> verify, from mini-project/README.md.
. "$(dirname "$0")/lib.sh"
N=s14-mini; K="kubectl -n $N"
ns_reset $N
cd mini-project
watch_start "$L/04-mini-project-watch.txt" $K get pods

hr "1. deploy"
x "$K apply -f deployment.yaml && $K apply -f service.yaml"
x "$K rollout status deploy/troubleshooting-app --timeout=120s"
x "$K get pods; $K get service"
hr "2. check the application"
x "$K get pods -o wide"
POD=$($K get pods -l app=troubleshooting-app -o jsonpath='{.items[0].metadata.name}')
x "$K describe pod $POD | sed -n '/^Containers/,/^Conditions/p' | grep -E 'Image:|State|Ready|Port'"
x "$K logs $POD | tail -3"
x "$K exec $POD -- curl -s localhost | grep title"
hr "3./4. service and endpoints"
x "$K describe service troubleshooting-service | grep -E 'Selector|TargetPort|Endpoints'"
x "$K get endpoints troubleshooting-service"
x "$K run client --image=busybox:1.36 --restart=Never -- sleep 3600; wait_ready $N client"
x "$K exec client -- wget -qO- -T 3 http://troubleshooting-service | grep title"

hr "5./6. broken pod"
x "cat broken-pod.yaml"
x "$K apply -f broken-pod.yaml"
x "for i in 1 2 3 4 5 6; do sleep 5; $K get pod project-broken-pod --no-headers; done"
x "$K describe pod project-broken-pod | sed -n '/^Events/,\$p'"
x "$K get pod project-broken-pod -o jsonpath='{.status.containerStatuses[0].state.waiting.message}{\"\\n\"}'"
x "curl -s 'https://hub.docker.com/v2/repositories/library/nginx/tags/this-tag-does-not-exist' | head -c 120; echo"
echo "ROOT CAUSE: nginx:this-tag-does-not-exist is not a tag of the nginx image. FIX: a real tag."
x "$K delete pod project-broken-pod; sed 's/nginx:this-tag-does-not-exist/nginx:1.27/' broken-pod.yaml | $K apply -f - && wait_ready $N project-broken-pod && $K get pod project-broken-pod"

hr "8./9. service selector challenge"
x "sed 's/app: troubleshooting-app/app: wrong-app/' service.yaml | sed -n '/selector/,+1p'"
x "sed '/selector:/{n;s/app: troubleshooting-app/app: wrong-app/;}' service.yaml | $K apply -f -"
x "$K get service troubleshooting-service"
x "$K get endpoints troubleshooting-service"
x "$K exec client -- sh -c 'wget -qO- -T 3 http://troubleshooting-service 2>&1 | tail -1'"
x "$K get pods --show-labels -l app=troubleshooting-app"
x "$K describe service troubleshooting-service | grep Selector"
echo "ROOT CAUSE: selector app=wrong-app vs pod label app=troubleshooting-app. FIX: re-apply the correct selector."
x "$K apply -f service.yaml; sleep 2; $K get endpoints troubleshooting-service"
x "$K exec client -- wget -qO- -T 3 http://troubleshooting-service | grep title"
x "$K exec client -- nslookup troubleshooting-service | tail -2"

hr "10. final checklist run"
x "$K get pods"
x "$K get events --types=Warning | head"
watch_stop
x "cat $L/04-mini-project-watch.txt"
shot_text 04-mini-project-watch "mini project: kubectl get pods -w  (s14-mini)" "$L/04-mini-project-watch.txt" 600
hr "cleanup"
x "kubectl delete ns $N --wait=false"
