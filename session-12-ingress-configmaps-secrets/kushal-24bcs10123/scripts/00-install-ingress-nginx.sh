#!/usr/bin/env bash
# The lab uses `minikube addons enable ingress`. On kind the equivalent is the ingress-nginx manifest for kind,
# which pins the controller to the node labelled ingress-ready=true and uses hostPort 80/443 (mapped to localhost).
. "$(dirname "$0")/lib.sh"
x "kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml"
x "kubectl -n ingress-nginx get deploy ingress-nginx-controller -o jsonpath='hostPorts={.spec.template.spec.containers[0].ports[*].hostPort} nodeSelector={.spec.template.spec.nodeSelector}{\"\\n\"}'"
# the controller uses hostPort 80/443, so it must run on the node whose 80/443 kind publishes to the Mac: the control-plane (labelled ingress-ready=true in kind-cluster.yaml)
x "kubectl -n ingress-nginx patch deploy ingress-nginx-controller -p '{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"ingress-ready\":\"true\"}}}}}'"
x "kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=180s"
x "kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s"
x "kubectl get pods -n ingress-nginx -o wide"
x "kubectl get ingressclass"
x "kubectl -n ingress-nginx get deploy ingress-nginx-controller -o jsonpath='{.spec.template.spec.containers[0].image}{\"\\n\"}'"
sleep 5
x "curl -s -o /dev/null -w 'http://localhost/ with no Ingress rules -> HTTP %{http_code}\\n' http://localhost/"
x "curl -s http://localhost/ | head -3"
