# Kubernetes Ingress, ConfigMaps & Secrets

**Name:** Shreyas S
**Enrollment number:** 10401
**GitHub:** [NeuralSynth](https://github.com/NeuralSynth)

> **Execution status:** Manifests and exercises prepared. Cluster execution and actual output are pending because Docker Desktop / Minikube is stopped. This page does not claim a successful cluster run.

This exercise follows the instructor's ConfigMap, Secret, backend/frontend and path-routing lab using an isolated namespace and self-contained application code.

| File | Purpose |
| --- | --- |
| [configmap.yaml](configmap.yaml) | Application settings and the frontend HTML file |
| [secret.yaml](secret.yaml) | Clearly labelled disposable demonstration values |
| [app.yaml](app.yaml) | Two frontend replicas, two Python API replicas, and ClusterIP Services |
| [ingress.yaml](ingress.yaml) | Routes `homework.local/api` to the API and `/` to the frontend |

## ConfigMap and Secret

The backend reads non-sensitive settings through `envFrom.configMapRef`, and selected Secret keys through `env.valueFrom.secretKeyRef`. The frontend mounts a ConfigMap as its document root. The API reports whether a password exists without returning it.

Kubernetes Secret `data` uses Base64, which is reversible encoding. `stringData` accepts plain text and the API converts it. RBAC and encryption at rest provide access control and storage protection. The values committed here are lab examples only.

```bash
printf 'mypassword' | base64
printf 'mypassword
' | base64
```

A trailing newline changes the encoded bytes and can cause authentication failures. `printf` makes this difference explicit. For a real application, create credentials outside source control. When an environment-backed ConfigMap or Secret changes, existing processes need restarted Pods to read new values. Mounted volumes update asynchronously; `subPath` mounts do not receive automatic updates.

## Ingress

An Ingress object needs an installed controller. These manifests use the `nginx` IngressClass provided by Minikube's ingress addon for this lab.

```bash
minikube addons enable ingress -p devops-homework
kubectl --context devops-homework -n ingress-nginx rollout status deployment/ingress-nginx-controller
kubectl --context devops-homework -n rudray-devops-hw describe ingress homework-ingress
```

The backend accepts `/api/...` directly, so no rewrite annotation is necessary. Prefix `/api` takes precedence over `/`. Both backend Services remain ClusterIP. HTTP Host must be `homework.local` to match the rule.

The runner requests both paths **through the ingress controller** from a Pod and checks the returned content and injected configuration. A direct request to the backend alone would not verify Ingress routing.

To view from macOS, keep this running in another terminal:

```bash
kubectl --context devops-homework -n ingress-nginx port-forward service/ingress-nginx-controller 18080:80
```

Then:

```bash
curl -H 'Host: homework.local' http://127.0.0.1:18080/
curl -H 'Host: homework.local' http://127.0.0.1:18080/api/health
```

This lab uses HTTP. HTTPS requires a TLS certificate Secret and a matching `spec.tls` entry; it is not enabled by these manifests.

## Run and capture actual output

From the repository root, after Docker Desktop is running:

```bash
minikube start -p devops-homework --driver=docker --cpus=2 --memory=3072
minikube addons enable ingress -p devops-homework
python3 scripts/run-kubernetes-labs.py --context devops-homework --topic 12
```

The runner saves commands, actual stdout/stderr and exit codes to `OUTPUT.md` in this folder. It marks success only after the checks finish. All resources are limited to the `rudray-devops-hw` namespace; the ingress addon is cluster-wide in this dedicated Minikube profile.

After finishing all four topics, remove the assignment resources:

```bash
kubectl --context devops-homework delete namespace rudray-devops-hw
```

## References

- [Instructor course repository](https://github.com/Nency-Ravaliya/devops-heros)
- [Kubernetes concepts](https://kubernetes.io/docs/concepts/)
- [Submission index](../../README.md)
