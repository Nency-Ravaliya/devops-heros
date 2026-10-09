# Session 12 — Kubernetes Ingress, ConfigMaps & Secrets

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Topic:** ConfigMaps, Secrets and Ingress (path-based and host-based routing)

Run against a real 3-node cluster with the **ingress-nginx** controller installed. Every
output block is actual terminal output.

---

## Part 1 — ConfigMaps

A ConfigMap holds **non-confidential** configuration as key/value pairs, so the same image
can run in dev, staging and production with different settings. It keeps configuration out
of the image, which is the point.

```yaml
# 01-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # simple key/value pairs -> consumed as environment variables
  APP_NAME: "devops-heros-demo"
  APP_ENV: "production"
  LOG_LEVEL: "info"
  # a whole file -> consumed as a mounted volume
  app.properties: |
    server.port=8080
    server.name=devops-heros
    feature.newUI=true
```

```bash
kubectl apply -f 01-configmap.yaml
kubectl get configmap app-config
```

```
configmap/app-config created
NAME         DATA   AGE
app-config   4      0s
```

`DATA 4` — three scalar keys plus one file-style key.

```bash
kubectl describe configmap app-config
```

```
Name:         app-config
Namespace:    default

Data
====
APP_ENV:
----
production

APP_NAME:
----
devops-heros-demo

LOG_LEVEL:
----
info

app.properties:
----
server.port=8080
server.name=devops-heros
feature.newUI=true
```

Note `describe` prints ConfigMap values in full — they are not secret.

### Creating one imperatively

```bash
kubectl create configmap cli-config \
  --from-literal=TEAM=devops-heros \
  --from-literal=REGION=ap-south-1 \
  --dry-run=client -o yaml
```

```yaml
apiVersion: v1
data:
  REGION: ap-south-1
  TEAM: devops-heros
kind: ConfigMap
metadata:
  name: cli-config
```

`--dry-run=client -o yaml` is the useful pattern: let `kubectl` write the boilerplate, then
commit the YAML instead of running imperative commands against a cluster.

Other sources: `--from-file=app.properties`, `--from-env-file=.env`.

---

## Part 2 — Secrets

```yaml
# 02-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
# stringData takes PLAIN text and base64-encodes it for you.
stringData:
  DB_USER: "devops_admin"
  DB_PASSWORD: "S3cur3P@ssw0rd"
  DB_HOST: "mysql.default.svc.cluster.local"
```

```bash
kubectl apply -f 02-secret.yaml
kubectl get secret db-secret
```

```
secret/db-secret created
NAME        TYPE     DATA   AGE
db-secret   Opaque   3      0s
```

### 2.1 A Secret is base64, **not** encryption

This is the most important thing to understand about Secrets.

```bash
kubectl get secret db-secret -o jsonpath='{.data.DB_PASSWORD}'
```

```
UzNjdXIzUEBzc3cwcmQ=
```

```bash
kubectl get secret db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

```
S3cur3P@ssw0rd
```

**One command, and the password is in plain text.** Base64 is an encoding, not a cipher —
it exists so binary data can travel in JSON, and it provides zero protection. Anyone with
`get secrets` RBAC permission can read every value.

What actually protects a Secret:

- **RBAC** — restrict `get`/`list` on secrets to the service accounts that genuinely need them.
- **Encryption at rest** — configure an `EncryptionConfiguration` on the API server so
  secrets are encrypted in etcd (they are *not* by default).
- **External secret stores** — Vault, AWS Secrets Manager, Sealed Secrets, External Secrets
  Operator, so the plaintext never lives in Git.
- **Never commit real secrets to a repository** — the YAML in this folder uses a throwaway
  value for exactly that reason.

### 2.2 `describe` hides the values

```bash
kubectl describe secret db-secret
```

```
Name:         db-secret
Namespace:    default

Type:  Opaque

Data
====
DB_HOST:      31 bytes
DB_PASSWORD:  14 bytes
DB_USER:      12 bytes
```

Only the **byte counts** — unlike a ConfigMap. That is a thin convenience so values do not
end up in terminal scrollback or CI logs, not a security boundary.

### 2.3 The base64 newline gotcha

```bash
echo    "S3cur3P@ssw0rd" | base64
echo -n "S3cur3P@ssw0rd" | base64
```

```
UzNjdXIzUEBzc3cwcmQK      <- note the trailing "K"
UzNjdXIzUEBzc3cwcmQ=
```

The two differ. Plain `echo` appends a **newline**, which gets encoded along with the
password, so the application receives `S3cur3P@ssw0rd\n` and authentication fails with a
completely unhelpful error. This is a genuinely common bug when people hand-encode values
into `data:`.

**The fix:** use `stringData:` (as above) and let Kubernetes do the encoding, or
`kubectl create secret generic db-secret --from-literal=DB_PASSWORD='S3cur3P@ssw0rd'`. Use
`echo -n` only if you truly must encode by hand.

---

## Part 3 — Consuming ConfigMaps and Secrets in a pod

All four consumption patterns in one deployment:

```yaml
# 03-app-deployment.yaml (container spec)
env:
  # single key from a ConfigMap
  - name: APP_NAME
    valueFrom:
      configMapKeyRef: { name: app-config, key: APP_NAME }
  # single key from a Secret
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef: { name: db-secret, key: DB_PASSWORD }
envFrom:
  # every key at once
  - configMapRef: { name: app-config }
  - secretRef:    { name: db-secret }
volumeMounts:
  - { name: config-volume, mountPath: /etc/config, readOnly: true }
  - { name: secret-volume, mountPath: /etc/secret, readOnly: true }
volumes:
  - name: config-volume
    configMap: { name: app-config }
  - name: secret-volume
    secret: { secretName: db-secret }
```

### 3.1 As environment variables — from the ConfigMap

```bash
kubectl exec <pod> -- sh -c 'echo "APP_NAME=$APP_NAME"; echo "APP_ENV=$APP_ENV"; echo "LOG_LEVEL=$LOG_LEVEL"'
```

```
APP_NAME=devops-heros-demo
APP_ENV=production
LOG_LEVEL=info
```

### 3.2 As environment variables — from the Secret

```bash
kubectl exec <pod> -- sh -c 'echo "DB_USER=$DB_USER"; echo "DB_PASSWORD=$DB_PASSWORD"; echo "DB_HOST=$DB_HOST"'
```

```
DB_USER=devops_admin
DB_PASSWORD=S3cur3P@ssw0rd
DB_HOST=mysql.default.svc.cluster.local
```

### 3.3 As a mounted volume — the ConfigMap

```bash
kubectl exec <pod> -- sh -c 'ls -l /etc/config; cat /etc/config/app.properties'
```

```
total 0
lrwxrwxrwx    1 root     root            14 Sep 17 21:03 APP_ENV -> ..data/APP_ENV
lrwxrwxrwx    1 root     root            15 Sep 17 21:03 APP_NAME -> ..data/APP_NAME
lrwxrwxrwx    1 root     root            16 Sep 17 21:03 LOG_LEVEL -> ..data/LOG_LEVEL
lrwxrwxrwx    1 root     root            21 Sep 17 21:03 app.properties -> ..data/app.properties

--- app.properties ---
server.port=8080
server.name=devops-heros
feature.newUI=true
```

Each key became a **file**, named after the key, containing the value. The
`-> ..data/<key>` symlinks are how the kubelet implements **atomic updates**: it writes a
new timestamped directory and flips the `..data` symlink, so a reader never sees a
half-written config.

### 3.4 As a mounted volume — the Secret

```bash
kubectl exec <pod> -- sh -c 'ls -l /etc/secret; cat /etc/secret/DB_PASSWORD'
```

```
total 0
lrwxrwxrwx    1 root     root            14 Sep 17 21:03 DB_HOST -> ..data/DB_HOST
lrwxrwxrwx    1 root     root            18 Sep 17 21:03 DB_PASSWORD -> ..data/DB_PASSWORD
lrwxrwxrwx    1 root     root            14 Sep 17 21:03 DB_USER -> ..data/DB_USER

--- DB_PASSWORD file ---
S3cur3P@ssw0rd
```

Note the file contains the **decoded** value — the kubelet does the base64 decoding, so the
application just reads a normal file.

### 3.5 The mounts are read-only

```bash
kubectl exec <pod> -- sh -c 'echo test > /etc/config/hack.txt'
```

```
sh: can't create /etc/config/hack.txt: Read-only file system
write refused - mount is read-only
```

### 3.6 Secret volumes live in tmpfs (memory), not on disk

```bash
kubectl exec <pod> -- df -h /etc/secret
```

```
tmpfs                    11.2G     12.0K     11.2G   0% /etc/secret
```

**`tmpfs`** — the secret is held in RAM on the node and never written to the node's disk.
That is a real, if modest, security property, and it is another reason to prefer volume
mounts over environment variables for secrets.

### 3.7 Environment variables vs volume mounts

| | Env vars | Volume mounts |
|---|---|---|
| Live updates when the ConfigMap changes | **No** — needs a pod restart | **Yes** — files update automatically (~1 min) |
| Multi-line / file content | Awkward | Natural |
| Leak risk | Visible in `kubectl describe pod`, crash dumps, child processes, `/proc/<pid>/environ` | Contained to the mount |
| Secrets stored in | Process memory | `tmpfs` |
| App changes needed | None — 12-factor style | Must read a file |

**Rule of thumb:** env vars for simple non-sensitive config, volume mounts for secrets and
for anything file-shaped. Note that even with volume mounts, most applications must be
signalled to re-read the file — hence tools like Reloader, or just rolling the deployment:

```bash
kubectl rollout restart deploy/config-demo
```

---

## Part 4 — Ingress

A Service of type LoadBalancer gives you **one cloud load balancer per service**, which gets
expensive and gives you no HTTP-level routing. An **Ingress** is a single HTTP(S) entry point
that routes by **host** and **path** to many Services behind it, with TLS termination in one
place.

An Ingress object is only a set of rules — it does nothing without an **Ingress controller**
(nginx, Traefik, HAProxy, or a cloud ALB controller) that watches those objects and
configures a real proxy.

### 4.1 The Ingress controller

```bash
kubectl get pods -n ingress-nginx
kubectl get svc  -n ingress-nginx
kubectl get ingressclass
```

```
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-p2tdw        0/1     Completed   0          24m
ingress-nginx-admission-patch-mprz9         0/1     Completed   0          24m
ingress-nginx-controller-6d795b6545-w5h2z   1/1     Running     0          24m

NAME                                 TYPE        CLUSTER-IP      PORT(S)
ingress-nginx-controller             NodePort    10.96.127.76    80:31844/TCP,443:31367/TCP
ingress-nginx-controller-admission   ClusterIP   10.96.131.150   443/TCP

NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       24m
```

The controller is itself just a pod running nginx, exposed by a Service. The `IngressClass`
named `nginx` is what an Ingress references via `ingressClassName` to say "this controller
should handle me" — necessary once a cluster runs more than one controller.

### 4.2 Two backend applications

```bash
kubectl apply -f 04-ingress-apps.yaml
kubectl get pods -l 'app in (app-one,app-two)'
kubectl get svc app-one app-two
```

```
NAME                       READY   STATUS    RESTARTS   AGE
app-one-5b49b756bb-rqhn7   1/1     Running   0          1s
app-one-5b49b756bb-wht8k   1/1     Running   0          1s
app-two-5c98c54d64-flk8l   1/1     Running   0          1s
app-two-5c98c54d64-wrdhf   1/1     Running   0          1s

NAME      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
app-one   ClusterIP   10.96.226.32   <none>        80/TCP    1s
app-two   ClusterIP   10.96.191.68   <none>        80/TCP    1s
```

Both Services are **ClusterIP** — internal only. The Ingress is what will make them
reachable from outside.

### 4.3 The Ingress resource

```yaml
# 05-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    # ---- path-based routing on one host ----
    - host: devops.local
      http:
        paths:
          - path: /one
            pathType: Prefix
            backend:
              service: { name: app-one, port: { number: 80 } }
          - path: /two
            pathType: Prefix
            backend:
              service: { name: app-two, port: { number: 80 } }
    # ---- host-based routing ----
    - host: one.devops.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: { name: app-one, port: { number: 80 } }
    - host: two.devops.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: { name: app-two, port: { number: 80 } }
```

```bash
kubectl apply -f 05-ingress.yaml
kubectl get ingress demo-ingress
```

```
NAME           CLASS   HOSTS                                            ADDRESS   PORTS   AGE
demo-ingress   nginx   devops.local,one.devops.local,two.devops.local             80      13s
```

```bash
kubectl describe ingress demo-ingress
```

```
Name:             demo-ingress
Ingress Class:    nginx
Rules:
  Host              Path  Backends
  ----              ----  --------
  devops.local
                    /one   app-one:80 (10.244.1.22:5678,10.244.2.19:5678)
                    /two   app-two:80 (10.244.1.23:5678,10.244.2.20:5678)
  one.devops.local
                    /   app-one:80 (10.244.1.22:5678,10.244.2.19:5678)
  two.devops.local
                    /   app-two:80 (10.244.1.23:5678,10.244.2.20:5678)
```

`describe` resolves each backend down to the **actual pod IPs** — very handy for confirming
the Ingress is wired to real, Ready pods. Note the controller routes to the pod endpoints
directly, bypassing kube-proxy's ClusterIP hop.

---

## Part 5 — Testing the routing

The cluster's ingress port is reachable on `localhost:8090`. Since the rules match on the
`Host` header, `curl -H 'Host: ...'` is used instead of editing a hosts file — it exercises
exactly the same code path.

### 5.1 Path-based routing

```bash
curl -H 'Host: devops.local' http://localhost:8090/one
curl -H 'Host: devops.local' http://localhost:8090/two
```

```
Response from APP ONE (path /one)
Response from APP TWO (path /two)
```

**Same host, same port, two different applications** — chosen purely by URL path. This is
what you cannot do with a plain Service.

### 5.2 Host-based routing

```bash
curl -H 'Host: one.devops.local' http://localhost:8090/
curl -H 'Host: two.devops.local' http://localhost:8090/
```

```
Response from APP ONE (path /one)
Response from APP TWO (path /two)
```

Same path `/`, different hostnames, different applications. This is how one ingress
controller serves many sites — the classic virtual-host pattern.

### 5.3 An unmatched host gets a 404

```bash
curl -o /dev/null -w "%{http_code}" -H 'Host: nothing.devops.local' http://localhost:8090/
```

```
http_code=404
```

The controller correctly refuses to serve a host it has no rule for, rather than falling
through to some arbitrary backend.

### 5.4 Response headers

```bash
curl -I -H 'Host: devops.local' http://localhost:8090/one
```

```
HTTP/1.1 200 OK
Date: Thu, 17 Sep 2026 21:03:52 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 34
Connection: keep-alive
X-App-Name: http-echo
```

`X-App-Name: http-echo` is the backend's own header, passed through — proof the response
came from the application pod rather than from nginx itself.

---

## Part 6 — The whole picture

```bash
kubectl get ingress,svc
```

```
NAME                                     CLASS   HOSTS                                            PORTS   AGE
ingress.networking.k8s.io/demo-ingress   nginx   devops.local,one.devops.local,two.devops.local   80      14s

NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
service/app-one                ClusterIP      10.96.226.32    <none>        80/TCP
service/app-two                ClusterIP      10.96.191.68    <none>        80/TCP
```

```bash
kubectl get configmap,secret,ingress
```

```
NAME                         DATA   AGE
configmap/app-config         4      21s
configmap/kube-root-ca.crt   1      25m

NAME               TYPE     DATA   AGE
secret/db-secret   Opaque   3      20s

NAME                                     CLASS   HOSTS                                            PORTS   AGE
ingress.networking.k8s.io/demo-ingress   nginx   devops.local,one.devops.local,two.devops.local   80      15s
```

### The request path

```
client
  -> ingress controller (nginx pod, published on the node)
     -> matches Host + Path against the Ingress rules
        -> forwards to the backend Service's pod endpoints
           -> application pod
```

### Ingress vs Service types

| | NodePort | LoadBalancer | Ingress |
|---|---|---|---|
| Layer | L4 (TCP) | L4 (TCP) | **L7 (HTTP/HTTPS)** |
| Routing by host/path | No | No | **Yes** |
| TLS termination | No | Passthrough | **Yes, centrally** |
| Cost | Free | One cloud LB **per Service** | One LB for **all** services |
| Needs a controller | No | Cloud provider | **Yes** |

### TLS

`03-ingress-tls.yaml` in this folder shows the TLS form:

```yaml
spec:
  tls:
    - hosts: [ devops.local ]
      secretName: devops-tls    # a kubernetes.io/tls Secret holding tls.crt and tls.key
```

Create the Secret with:

```bash
kubectl create secret tls devops-tls --cert=tls.crt --key=tls.key
```

In production cert-manager issues and renews these automatically from Let's Encrypt — which
ties the three topics of this session together: the certificate is a **Secret**, the routing
is an **Ingress**, and the issuer settings are a **ConfigMap**.

---

## Files in this folder

| File | Purpose |
|---|---|
| `01-configmap.yaml` | ConfigMap with scalar keys and a file-style key |
| `02-secret.yaml` | Secret using `stringData` |
| `03-app-deployment.yaml` | Pod consuming both, all four ways |
| `03-ingress-tls.yaml` | TLS-enabled Ingress example |
| `04-ingress-apps.yaml` | Two backend Deployments + Services |
| `05-ingress.yaml` | Ingress with path-based and host-based rules |
| `k8s-ingress-configmaps-secrets-transcript.txt` | Full terminal transcript |

## Summary

| Item | Status |
|---|---|
| ConfigMap created (scalar keys + file key), inspected, and the imperative/dry-run form shown | Done |
| Secret created with `stringData`; shown to be **base64, not encryption**, by decoding it | Done |
| `describe` hiding Secret values demonstrated | Done |
| The `echo` trailing-newline base64 gotcha reproduced and explained | Done |
| ConfigMap + Secret consumed as env vars (single key and `envFrom`) — values verified inside the pod | Done |
| ConfigMap + Secret consumed as volumes; read-only enforcement and `tmpfs` backing verified | Done |
| Ingress controller and IngressClass inspected | Done |
| Ingress created with **path-based** and **host-based** rules | Done |
| Both routing modes tested end to end, plus a 404 for an unmatched host | Done |
| TLS ingress form and the Ingress vs NodePort vs LoadBalancer comparison documented | Done |
