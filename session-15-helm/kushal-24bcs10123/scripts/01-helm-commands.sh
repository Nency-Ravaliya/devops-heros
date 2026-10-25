#!/usr/bin/env bash
# 01-helm-commands: every helm command from the session, run once each against the kind cluster.
. "$(dirname "$0")/lib.sh"
WORK=$(mktemp -d /tmp/s15-helm-XXXX); cd "$WORK"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

hr "helm version / helm env"
x "helm version"
x "helm env | grep -E 'HELM_NAMESPACE|HELM_REPOSITORY_CONFIG|HELM_CACHE_HOME'"

hr "helm repo - add, update, list"
x "helm repo add bitnami https://charts.bitnami.com/bitnami"
x "helm repo update"
x "helm repo list"

hr "helm search - repo (local index) vs hub (Artifact Hub)"
x "helm search repo nginx --max-col-width 60 | head -8"
x "helm search repo prometheus-community/kube-prometheus-stack --versions | head -4"
x "helm search hub nginx --max-col-width 55 | head -8"

hr "helm create - scaffold a new chart"
x "helm create demo-chart"
x "find demo-chart -type f | sort"
x "cat demo-chart/Chart.yaml"
x "grep -nE '^(replicaCount|image:|  repository|  tag|service:|  type|  port)' demo-chart/values.yaml"

hr "helm lint / helm template / helm show - all without touching the cluster"
x "helm lint demo-chart"
x "helm template demo demo-chart --set image.tag=1.27-alpine | grep -E '^(kind:|  name:|        image:|  replicas:)'"
x "helm show chart demo-chart"
x "helm show values demo-chart | sed -n '1,12p'"

hr "helm package - a chart is just a .tgz"
x "helm package demo-chart"
x "ls -la demo-chart-0.1.0.tgz && tar tzf demo-chart-0.1.0.tgz | head -5"

hr "helm install (from the packaged .tgz)"
x "helm install demo ./demo-chart-0.1.0.tgz --set image.tag=1.27-alpine"
x "kubectl -n $NS rollout status deployment/demo-demo-chart --timeout=120s"

hr "helm list / helm status / helm get"
x "helm list"
x "helm list --all-namespaces | grep -E 'NAME|demo|kube-prometheus'"
x "helm status demo | sed -n '1,8p'"
x "helm get values demo"
x "helm get values demo --all | sed -n '1,15p'"
x "helm get manifest demo | grep -E '^(kind:|  name:|        image:)'"
x "helm get notes demo | head -5"
x "helm get all demo | wc -l"
x "kubectl -n $NS get secret -l owner=helm -o custom-columns='NAME:.metadata.name,TYPE:.type'      # this is where helm stores each revision"

hr "helm upgrade / helm history"
x "helm upgrade demo ./demo-chart-0.1.0.tgz --set image.tag=1.27-alpine --set replicaCount=2"
x "kubectl -n $NS rollout status deployment/demo-demo-chart --timeout=120s"
x "kubectl -n $NS get pods -l app.kubernetes.io/instance=demo"
x "helm history demo"
x "helm upgrade --install demo ./demo-chart-0.1.0.tgz --set image.tag=1.27-alpine --set replicaCount=2 --reuse-values | head -3   # idempotent form used in CI"

hr "helm rollback"
x "helm rollback demo 1"
x "kubectl -n $NS rollout status deployment/demo-demo-chart --timeout=120s"
x "kubectl -n $NS get pods -l app.kubernetes.io/instance=demo"
x "helm history demo"

hr "helm uninstall"
x "helm uninstall demo"
x "helm list"
x "kubectl -n $NS get all"
x "helm uninstall demo 2>&1 || true     # second time: nothing left"

hr "helm install straight from a repo (no local chart at all)"
x "helm install metrics prometheus-community/prometheus-node-exporter --version 4.59.0 --set image.tag=v1.12.1-distroless --set hostRootFsMount.enabled=false --set hostNetwork=false | head -6    # the monitoring stack already runs a node-exporter on hostPort 9100 of every node, so no hostNetwork here"
x "kubectl -n $NS rollout status daemonset/metrics-prometheus-node-exporter --timeout=120s"
x "helm list"
x "helm uninstall metrics"
cd /; rm -rf "$WORK"
