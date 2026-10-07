# Session 12 — Kubernetes Ingress, ConfigMaps & Secrets (Homework)

**Name:** Chhavi Ahlawat
**Enrollment Number:** 24BCS10201
**Email:** chhavi.24bcs10201@sst.scaler.com

---

## Homework Tasks

| Task | Description | Status |
|---|---|---|
| 1 | ConfigMap — externalize plain-text config | ✅ |
| 2 | Secret — store Base64-encoded credentials | ✅ |
| 3 | Ingress — single entry point, path-based routing (+ TLS) | ✅ |
| 4 | Full demo — ConfigMap + Secret + Ingress wired together | ✅ |
| 5 | Troubleshooting — Secret base64 gotcha | ✅ |

---

## Folder Guide

| Folder | Covers |
|---|---|
| [`01-configmap/`](01-configmap/README.md) | ConfigMap |
| [`02-secret/`](02-secret/README.md) | Secret |
| [`03-ingress/`](03-ingress/README.md) | Ingress rules + TLS |
| [`04-full-demo/`](04-full-demo/README.md) | Frontend + Backend behind one Ingress, using both ConfigMap & Secret |
| [`troubleshooting/`](troubleshooting) | Base64 encode/decode gotcha |

Full walkthrough with expected output: [`lab.md`](lab.md)

---

## 1. ConfigMap
```bash
kubectl apply -f 01-configmap/app-config.yaml
kubectl get configmap yatri-app-config -o yaml
```
![ConfigMap created and its data visible via kubectl get](screenshots/configmap.png)

## 2. Secret
```bash
kubectl apply -f 02-secret/db-secret.yaml
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
```
![Secret created and the database password decoded from base64](screenshots/secret.png)

## 3. Ingress
```bash
minikube addons enable ingress
kubectl apply -f 03-ingress/ingress-routes.yaml
kubectl get ingress yatri-ingress
```
![Ingress rules applied and the yatri-ingress resource listed](screenshots/ingress.png)

## 4. Full Demo (ConfigMap + Secret + Ingress)
```bash
cd 04-full-demo
bash run-demo.sh
curl http://yatri.local
curl http://yatri.local/api/
```
![Full demo — frontend and backend both responding through the one Ingress](screenshots/full-demo.png)

## 5. Troubleshooting — Secret Base64 Gotcha
```bash
echo -n "secretpassword" | base64        # correct
echo "secretpassword" | base64           # WRONG — trailing newline corrupts the value
```
![Troubleshooting — correct vs incorrect base64 encoding of a secret value](screenshots/troubleshooting.png)

Details: [`troubleshooting/secret-base64-gotcha.md`](troubleshooting/secret-base64-gotcha.md)

---

## Cleanup
```bash
cd 04-full-demo && bash cleanup.sh
cd ..
kubectl delete -f 03-ingress/ingress-routes.yaml
kubectl delete -f 02-secret/db-secret.yaml
kubectl delete -f 01-configmap/app-config.yaml
```

---

## Resources
- https://kubernetes.io/docs/concepts/configuration/configmap/
- https://kubernetes.io/docs/concepts/configuration/secret/
- https://kubernetes.io/docs/concepts/services-networking/ingress/
