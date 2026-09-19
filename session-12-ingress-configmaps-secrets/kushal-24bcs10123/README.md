# Session 12 – Kubernetes Ingress, ConfigMaps & Secrets

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Environment:** kind v0.33.0 cluster `kushal-lab` (Kubernetes v1.37.0, 1 control-plane + 2 workers) on Docker Desktop 29.0.1, macOS / Apple Silicon – the same cluster as sessions 9–11. Ingress controller: ingress-nginx v1.12.1.

The lab guide ([`lab.md`](../lab.md)) assumes minikube; the two minikube-specific steps (`minikube addons enable ingress` and adding `minikube ip` to `/etc/hosts`) are replaced below, everything else was run exactly as written with the professor's manifests **unmodified**. Raw output is in [`logs/`](logs), the exact commands in [`scripts/`](scripts).

```text
kushal-24bcs10123/
├── README.md
├── scripts/
│   ├── 00-install-ingress-nginx.sh   # replaces `minikube addons enable ingress`
│   ├── 01-configmap.sh               # 01-configmap folder
│   ├── 02-secret.sh                  # 02-secret folder
│   ├── 03-full-demo.sh               # lab.md parts 1-9 with 04-full-demo/
│   ├── 04-ingress-tls.sh             # 03-ingress hands-on: host-based routing + TLS
│   └── lib.sh
└── logs/                             # one .txt per script
```

## 0. Ingress controller on kind

Log: [logs/00-install-ingress-nginx.txt](logs/00-install-ingress-nginx.txt)

```bash
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
```

The kind flavour of ingress-nginx listens with `hostPort: 80/443` on the node it lands on. Only the control-plane node's 80/443 are published to my Mac (see [`kind-cluster.yaml`](../../session9-k8s/kushal-24bcs10123/kind-cluster.yaml)), and the controller first landed on a worker, so I pinned it with a `nodeSelector` on the `ingress-ready=true` label that node carries:

```text
$ kubectl -n ingress-nginx patch deploy ingress-nginx-controller -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"}}}}}'
$ kubectl get pods -n ingress-nginx -o wide
NAME                                        READY   STATUS      IP           NODE
ingress-nginx-admission-create-gmr2j        0/1     Completed   10.244.1.92  kushal-lab-worker2
ingress-nginx-admission-patch-bb9df         0/1     Completed   10.244.3.91  kushal-lab-worker
ingress-nginx-controller-56f5db4996-xz5qj   1/1     Running     10.244.0.5   kushal-lab-control-plane

$ kubectl get ingressclass
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       31s

$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost/
HTTP 404                                   <- the controller answers; no Ingress rules yet
```

From here on `http://localhost` **is** the Ingress, so `curl --resolve yatri.local:80:127.0.0.1 http://yatri.local/` does what `minikube ip` + `/etc/hosts` does in the lab, without `sudo`.

## 1. ConfigMap (`01-configmap/`)

Log: [logs/01-configmap.txt](logs/01-configmap.txt)

```text
$ kubectl apply -f 01-configmap/app-config.yaml
configmap/yatri-app-config created

$ kubectl get configmap yatri-app-config
NAME               DATA   AGE
yatri-app-config   5      0s

$ kubectl get configmap yatri-app-config -o jsonpath='{.data.ENVIRONMENT}'
production
```

A pod can consume the same ConfigMap two ways; I ran one throw-away busybox pod that does both:

```text
envFrom: [{configMapRef: {name: yatri-app-config}}]            -> ENV: ENVIRONMENT=production LOG_LEVEL=INFO
volumes:  configMap: {name: yatri-app-config} at /etc/config   -> FILES: DEFAULT_CURRENCY ENVIRONMENT LOG_LEVEL MAX_BOOKING_DAYS PORT
                                                                  cat /etc/config/DEFAULT_CURRENCY -> INR
```

Each key becomes an environment variable or a file whose content is the value. `kubectl create configmap from-cli --from-literal=MODE=demo ... --dry-run=client -o yaml` shows the imperative way to produce the same YAML.

## 2. Secret (`02-secret/`)

Log: [logs/02-secret.txt](logs/02-secret.txt)

```text
$ kubectl apply -f 02-secret/db-secret.yaml
$ kubectl describe secret yatri-db-secret | sed -n '/^Data/,$p'
Data
====
POSTGRES_DB:        19 bytes                <- describe hides the values ...
POSTGRES_PASSWORD:  14 bytes
POSTGRES_USER:      11 bytes

$ kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
secretpassword                              <- ... but anyone allowed to `get secrets` can decode them
```

base64 is encoding, not encryption – and `echo` without `-n` bakes a newline into the password:

```text
$ echo -n 'secretpassword' | base64
c2VjcmV0cGFzc3dvcmQ=
$ echo 'secretpassword' | base64
c2VjcmV0cGFzc3dvcmQK                        <- ends in "K": the \n got encoded too
$ echo 'c2VjcmV0cGFzc3dvcmQK' | base64 --decode | od -c | head -1
0000000    s   e   c   r   e   t   p   a   s   s   w   o   r   d  \n
```

To see where the value really ends up I read the raw key out of etcd (same trick as in session 9):

```text
$ etcdctl get /registry/secrets/default/yatri-db-secret | strings | grep -E 'yatri_admin|secretpassword'
secretpassword
yatri_admin                                 <- plain bytes in etcd: no encryption-at-rest configured on this cluster
```

So the real protection for Secrets is RBAC on who may read them, encryption at rest on etcd, and not committing the YAML to git – not the base64.

## 3. The full lab (`lab.md` parts 1–9 with `04-full-demo/`)

Log: [logs/03-full-demo.txt](logs/03-full-demo.txt)

```text
                          curl --resolve yatri.local:80:127.0.0.1
                                        │
                              localhost:80 (kind port map)
                                        │
                        ingress-nginx controller (control-plane node)
                         host: yatri.local
                    ┌──── path /api(/|$)(.*)  rewrite /$2 ────┐        ┌──── path / ────┐
                    ▼                                          │        ▼                │
      yatri-backend-service:80  (ClusterIP)                    │  yatri-frontend-service:80 (ClusterIP)
                    ▼                                          │        ▼
      2 × python http.server :5000                             │  2 × nginx:1.25-alpine
        envFrom  configMap yatri-app-config                    │    envFrom configMap yatri-app-config
        env      secretKeyRef yatri-db-secret                  │
```

**Parts 1–4 – config in, env vars out**

```text
$ kubectl exec deployment/yatri-backend -- env | grep -E 'ENVIRONMENT|LOG_LEVEL|APP_PORT|DEFAULT_CURRENCY|MAX_BOOKING_DAYS|POSTGRES' | sort
APP_PORT=5000                          ┐
DEFAULT_CURRENCY=INR                   │ from the ConfigMap (envFrom)
ENVIRONMENT=production                 │
LOG_LEVEL=INFO                         │
MAX_BOOKING_DAYS=30                    ┘
POSTGRES_DB=yatri_production_db        ┐
POSTGRES_PASSWORD=secretpassword       │ from the Secret (secretKeyRef) - already decoded inside the pod
POSTGRES_USER=yatri_admin              ┘

$ kubectl get svc yatri-frontend-service yatri-backend-service
NAME                     TYPE        CLUSTER-IP      PORT(S)
yatri-frontend-service   ClusterIP   10.96.242.144   80/TCP        <- both internal only; the Ingress is the single way in
yatri-backend-service    ClusterIP   10.96.37.32     80/TCP
```

**Parts 5–6 – one Ingress, two paths**

```text
$ kubectl apply -f ingress.yaml
$ kubectl get ingress yatri-ingress
NAME            CLASS   HOSTS         ADDRESS     PORTS   AGE
yatri-ingress   nginx   yatri.local   localhost   80      60s

$ kubectl describe ingress yatri-ingress | sed -n '/^Rules/,/^Annotations/p'
Rules:
  Host         Path  Backends
  yatri.local
               /api(/|$)(.*)   yatri-backend-service:80 (10.244.1.142:5000,10.244.3.168:5000)
               /               yatri-frontend-service:80 (10.244.1.143:80,10.244.3.169:80)
Annotations:   nginx.ingress.kubernetes.io/rewrite-target: /$2

$ curl -s --resolve yatri.local:80:127.0.0.1 http://yatri.local/ | grep -i '<title>'
<title>Welcome to nginx!</title>                          <- frontend

$ curl -s --resolve yatri.local:80:127.0.0.1 http://yatri.local/api/
Yatri Backend API
=================
ENVIRONMENT     : production
LOG_LEVEL       : INFO
DEFAULT_CURRENCY: INR
POSTGRES_USER   : yatri_admin
POSTGRES_DB     : yatri_production_db                     <- backend, ConfigMap + Secret values end to end

$ curl -H 'Host: nobody.local' http://127.0.0.1/   -> HTTP 404      <- host-based: an unknown Host header gets nginx's 404
$ curl http://localhost/                            -> HTTP 404
```

The `rewrite-target: /$2` annotation is why `/api/` reaches the Python server as `/`: the second regex group of `/api(/|$)(.*)` is what is left after `/api`.

**Part 8 – the newline bug, reproduced**

```text
$ echo 'secretpassword' | base64                     -> c2VjcmV0cGFzc3dvcmQK   (15 bytes when decoded)
$ echo -n 'secretpassword' | base64                  -> c2VjcmV0cGFzc3dvcmQ=   (14 bytes)
```

**Part 9 – a ConfigMap change does not reach a running pod**

```text
$ kubectl patch configmap yatri-app-config --type merge -p '{"data":{"ENVIRONMENT":"staging"}}'
$ kubectl exec deployment/yatri-backend -- env | grep ENVIRONMENT
ENVIRONMENT=production                                    <- env vars are read once, at container start

$ kubectl rollout restart deployment/yatri-backend && kubectl rollout status deployment/yatri-backend
$ kubectl exec deployment/yatri-backend -- env | grep ENVIRONMENT
ENVIRONMENT=staging
$ for i in 1 2 3 4; do curl -s --resolve yatri.local:80:127.0.0.1 http://yatri.local/api/ | grep ENVIRONMENT; done | sort | uniq -c
   4 ENVIRONMENT     : staging                            <- both new pods, through the Ingress
```

(Mounted ConfigMap *volumes* do get updated in place after a while; env vars never do – hence `rollout restart`, or a checksum annotation on the pod template in real projects.)

## 4. Host-based routing + TLS (`03-ingress/` hands-on)

Log: [logs/04-ingress-tls.txt](logs/04-ingress-tls.txt)

```text
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj '/CN=campus.local/O=CampusDevOps'
$ kubectl create secret tls campus-tls-cert --cert=tls.crt --key=tls.key
$ kubectl apply -f 03-ingress/ingress-tls.yaml
$ kubectl get ingress
NAME                 CLASS   HOSTS                                  ADDRESS     PORTS     AGE
campus-ingress-tls   nginx   portal.campus.local,api.campus.local   localhost   80, 443   ...
yatri-ingress        nginx   yatri.local                            localhost   80        ...

$ curl -sk --resolve portal.campus.local:443:127.0.0.1 https://portal.campus.local/ | grep -i '<title>'
<title>Welcome to nginx!</title>                              <- host 1 -> frontend
$ curl -sk --resolve api.campus.local:443:127.0.0.1 https://api.campus.local/api/ | head -3
Yatri Backend API                                             <- host 2 -> backend
$ curl -sk https://api.campus.local/            -> HTTP 404    <- api host has no rule for /
$ curl -s  http://portal.campus.local/          -> HTTP 308 redirect to https://portal.campus.local/   (ssl-redirect: "true")
```

### Something the lab did not mention: which certificate was actually served

```text
$ echo | openssl s_client -connect 127.0.0.1:443 -servername portal.campus.local | openssl x509 -noout -subject -issuer
subject=O=Acme Co, CN=Kubernetes Ingress Controller Fake Certificate
issuer=O=Acme Co, CN=Kubernetes Ingress Controller Fake Certificate

$ kubectl -n ingress-nginx logs deploy/ingress-nginx-controller | grep 'does not contain a Common Name' | tail -1
SSL certificate "default/campus-tls-cert" does not contain a Common Name or Subject Alternative Name for server "api.campus.local": x509: certificate is not valid for any names, but wanted to match api.campus.local
```

The routing worked only because `curl -k` skips verification. The lab's cert is `CN=campus.local` with **no Subject Alternative Name**, which matches neither `portal.campus.local` nor `api.campus.local`, so ingress-nginx refused it and served its built-in fake certificate. Re-issuing the cert with SANs fixes it and then HTTPS works *without* `-k`:

```text
$ openssl req ... -subj '/CN=campus.local/O=CampusDevOps' -addext 'subjectAltName=DNS:portal.campus.local,DNS:api.campus.local'
$ kubectl delete secret campus-tls-cert && kubectl create secret tls campus-tls-cert --cert=tls.crt --key=tls.key

$ echo | openssl s_client -connect 127.0.0.1:443 -servername portal.campus.local | openssl x509 -noout -subject -ext subjectAltName
subject=CN=campus.local, O=CampusDevOps
X509v3 Subject Alternative Name:
    DNS:portal.campus.local, DNS:api.campus.local

$ curl -s --cacert tls.crt --resolve portal.campus.local:443:127.0.0.1 https://portal.campus.local/   -> HTTP 200   (no -k)
```

Cleanup at the end ran the course's `04-full-demo/cleanup.sh`; every follow-up `get` returned `NotFound`.

## Lab completion checklist

- [x] Applied `configmap.yaml` and read a key using `-o jsonpath`.
- [x] Applied `secret.yaml` and decoded `POSTGRES_PASSWORD` with `base64 --decode`.
- [x] Applied `backend.yaml` and verified environment variables inside the pod with `kubectl exec`.
- [x] Applied `frontend.yaml` and confirmed both services are `ClusterIP` type.
- [x] Enabled the NGINX Ingress Controller and confirmed the controller pod is `Running`.
- [x] Applied `ingress.yaml` and confirmed an `ADDRESS` appeared in `kubectl get ingress`.
- [x] Tested path `/` returns Nginx HTML using `curl -H "Host: yatri.local"`.
- [x] Tested path `/api/` returns the backend config values using `curl -H "Host: yatri.local"`.
- [x] Demonstrated the `echo` vs `echo -n` newline bug difference.
- [x] Triggered a rolling restart after updating a ConfigMap value and confirmed the new value was loaded.

## What I understood

* ConfigMap and Secret are the same mechanism (key/value objects injected as env vars or files); the Secret only adds base64, a separate RBAC verb and the *option* of encryption at rest. Treat every Secret as readable by whoever can read Secrets.
* Env vars are frozen at container start; a config change needs a restart (or a mounted volume and an app that re-reads it).
* An Ingress is just a routing *rule*; the Ingress *controller* is the actual proxy pod, and there has to be one (`ingressClassName: nginx`). One controller, one IP/port, many hosts and paths – instead of one LoadBalancer per Service.
* TLS is terminated at the controller from a `kubernetes.io/tls` Secret, per host. The certificate has to actually name the host (SAN), or nginx silently falls back to a default cert – `curl -k` hides that.
