# Session 12 – ConfigMaps, Secrets and Ingress (run on minikube)

## ConfigMap
Create `yatri-app-config`, inspect it with `describe`, and read a single key with jsonpath.

![configmap create, describe, jsonpath](/assets/s12-configmap.png)

## Secret
`describe secret` only shows byte counts. The value is base64-encoded, not encrypted – decoding `POSTGRES_PASSWORD` gives the plain text back.

![secret create, describe, base64 decode](/assets/s12-secret.png)

## Ingress
Enable the minikube NGINX ingress controller, apply `yatri-ingress`, and check the rules: `/api(/|$)(.*)` goes to the backend service (rewritten to `/$2`), `/` goes to the frontend. Requests are sent through the controller with `Host: yatri.local`; `/` returns the nginx frontend and `/api/` returns the Python backend, which prints the ConfigMap and Secret values it received.

![ingress controller, ingress rules, routing test](/assets/s12-ingress.png)

## Full demo (`04-full-demo/`)
ConfigMap + Secret + frontend Deployment/Service + backend Deployment/Service, all rolled out.

![full demo deploy](/assets/s12-fulldemo-01.png)

Inside the backend Pod, `env` shows the ConfigMap keys injected via `envFrom` and the Secret keys via `secretKeyRef`. Cleanup with `cleanup.sh`.

![env injection check and cleanup](/assets/s12-fulldemo-02.png)
