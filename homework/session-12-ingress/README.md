# Session 12 — ConfigMap, Secret, Ingress

Student: Viraj Bhanage, roll 24BCS10274

## Task 1 — ConfigMap

`configmap.yaml` stores `APP_ENV` and `APP_MESSAGE` and injects them with `envFrom`. After apply:

```bash
kubectl apply -f configmap.yaml
kubectl exec configmap-demo -- printenv APP_ENV APP_MESSAGE
```

Expected values: `lab` and `hello-from-configmap`.

## Task 2 — Secret

`secret.yaml` uses `stringData` so the lab file stays readable. Kubernetes stores the value base64-encoded in etcd. That encoding is not encryption. Do not commit real passwords. Use a secret manager or Sealed Secrets, and keep this file as a lab example only. The password here is `example-only-do-not-use`.

```bash
kubectl apply -f secret.yaml
kubectl exec secret-demo -- printenv DB_PASSWORD
```

### The newline bug from the session troubleshooting notes

`echo "mypassword" | base64` includes a trailing newline, so the decoded secret is `mypassword\n`. Postgres then rejects the password. `echo -n` omits the newline. `stringData` avoids hand-rolled base64.

## Task 3 — Ingress

`ingress.yaml` sends host `web.local` path `/` to Service `web-clusterip` from Session 11. You need an Ingress controller. On Minikube:

```bash
minikube addons enable ingress
kubectl apply -f ingress.yaml
echo "$(minikube ip) web.local" | sudo tee -a /etc/hosts
curl -H 'Host: web.local' http://$(minikube ip)
```

## Task 4 — Ingress vs Ingress controller

An **Ingress** is a routing rule: host, path, and backend Service. By itself it does nothing. An **Ingress controller** is the running proxy (ingress-nginx, Traefik, AWS load balancer controller) that watches Ingress objects and programs a real load balancer. You need both. The object declares the route. The controller implements it. Many Ingress objects can share one controller.

## Task 5 — Troubleshooting write-up

Problem: an app secret was created with `echo secret | base64`, and login failed with `password authentication failed`.

Investigation: `kubectl get secret app-secret -o yaml` showed the data key. Decoding it showed a trailing newline byte `0a`.

Root cause: `echo` appends `\n`, so the password the process received was not the password the database had.

Fix: recreate the secret with `echo -n` or with `stringData`.

Before: authentication failed. After: the same user connected.
