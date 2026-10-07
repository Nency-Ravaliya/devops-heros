#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-}" in
  tests)
    docker compose run --rm --no-deps -v "$PWD/backend/tests:/app/tests:ro" -v "$PWD/backend/pytest.ini:/app/pytest.ini:ro" backend python -m pytest -v --disable-warnings -p no:cacheprovider tests
    docker compose ps
    ;;
  cluster)
    kubectl get deploy,pods,svc,ingress,hpa,pvc -n taskboard
    helm list -n taskboard
    ;;
  troubleshoot)
    echo 'SESSION 21: Service selector mismatch - diagnose and repair'
    kubectl apply -f troubleshooting/broken-service.yaml
    echo 'BEFORE: selector matches no pods'
    kubectl get svc broken-service -n taskboard -o jsonpath='{.spec.selector}{"\n"}'
    kubectl get endpointslices -n taskboard -l kubernetes.io/service-name=broken-service
    kubectl get pods -n taskboard -l app=taskboard-backend --show-labels
    echo 'FIX: correct the selector AND targetPort (8080 -> 8000)'
    kubectl patch svc broken-service -n taskboard --type merge -p '{"spec":{"selector":{"app":"taskboard-backend"},"ports":[{"port":8080,"targetPort":8000}]}}'
    for attempt in {1..20}; do
      addresses=$(kubectl get endpointslices -n taskboard -l kubernetes.io/service-name=broken-service -o jsonpath='{.items[*].endpoints[*].addresses}')
      if [[ -n "$addresses" ]]; then break; fi
      sleep 1
    done
    [[ -n "$addresses" ]]
    echo 'AFTER: endpoints restored; verify HTTP through the repaired Service'
    kubectl get endpointslices -n taskboard -l kubernetes.io/service-name=broken-service
    kubectl exec -n taskboard deploy/taskboard-backend -- python -c 'import urllib.request; print(urllib.request.urlopen("http://broken-service:8080/health").read().decode())'
    echo 'SESSION 21: Invalid image tag - diagnose and repair'
    kubectl apply -f troubleshooting/broken-image.yaml
    sleep 10
    kubectl get pods -n taskboard -l app=broken-image
    kubectl get events -n taskboard --field-selector involvedObject.kind=Pod --sort-by=.lastTimestamp | tail -5
    kubectl set image -n taskboard deploy/taskboard-broken-image backend=taskboard-backend:session21
    kubectl set env -n taskboard deploy/taskboard-broken-image DATABASE_URL=postgresql+psycopg://taskboard:taskboard@taskboard-postgres:5432/taskboard
    kubectl rollout status -n taskboard deploy/taskboard-broken-image --timeout=180s
    kubectl exec -n taskboard deploy/taskboard-broken-image -- python -c 'import urllib.request; print(urllib.request.urlopen("http://localhost:8000/ready").read().decode())'
    ;;
  *) echo 'Usage: bash homework/check.sh {tests|cluster|troubleshoot}'; exit 2 ;;
esac
