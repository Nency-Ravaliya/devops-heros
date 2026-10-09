# Session 12 — Ingress, ConfigMaps and Secrets

## 1. ConfigMap

Create `yatri-app-config`, inspect its keys, read a single value with JSONPath,
and delete it.

![Applying the app-config ConfigMap, describing yatri-app-config with its five keys, reading LOG_LEVEL with jsonpath, and deleting it](../assets/ss14.png)

## 2. Secret

Base64 encode/decode a value, create `yatri-db-secret`, read the stored password
back, and delete it.

![echo piped to base64 and back, applying db-secret.yaml, getting yatri-db-secret and decoding POSTGRES_PASSWORD with jsonpath](../assets/ss15.png)

## 3. Ingress

Create the host/path routing rules for `yatri.local`, then generate a self-signed
certificate and add a TLS-enabled Ingress.

![Applying ingress-routes.yaml, describing yatri-ingress rules, generating a self-signed cert with openssl, creating the campus-tls-cert TLS secret and applying ingress-tls.yaml](../assets/ss16.png)

## 4. Full Demo

End-to-end: enable the NGINX ingress addon, then deploy the ConfigMap, Secret,
frontend, backend and Ingress together.

**ConfigMap, Secret and frontend**

![Enabling the minikube ingress addon, then applying and describing the full-demo ConfigMap and Secret, and deploying the yatri-frontend Deployment and Service](../assets/ss17.png)

**Backend, Ingress routing and host entry**

![Deploying the yatri-backend Deployment and Service, applying and describing yatri-ingress with /api and / rules, and adding yatri.local to /etc/hosts](../assets/ss18.png)
