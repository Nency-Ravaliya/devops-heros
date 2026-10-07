#!/usr/bin/env bash
# Smoke test for ShopEasy: calls the storefront Service from inside the cluster, like a user would.
# Usage: ./smoke-test.sh
set -u
NS=shopeasy
kubectl delete pod smoke-test -n "$NS" --ignore-not-found --now >/dev/null 2>&1
kubectl run smoke-test -n "$NS" --restart=Never --quiet \
  --image=registry.k8s.io/e2e-test-images/agnhost:2.53 --command -- sh -c '
for path in / /healthz /api/products; do
  code=$(curl -s -o /tmp/body -w "%{http_code}" --max-time 5 http://storefront-web$path)
  printf "GET %-14s -> HTTP %s  %s\n" "$path" "$code" "$(head -c 100 /tmp/body 2>/dev/null | tr -d "\n")"
done' >/dev/null
kubectl wait pod/smoke-test -n "$NS" --for=jsonpath='{.status.phase}'=Succeeded --timeout=60s >/dev/null
kubectl logs smoke-test -n "$NS"
kubectl delete pod smoke-test -n "$NS" --now >/dev/null
