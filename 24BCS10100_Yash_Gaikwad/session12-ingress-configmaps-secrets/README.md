# Session 12: Kubernetes Ingress, ConfigMaps and Secrets

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

| Task | Topic | Where |
|---|---|---|
| 1 | ConfigMap: create, inject, verify | [Task 1](#task-1-configmap) |
| 2 | Secret: create, inject, verify, why not in Git | [Task 2](#task-2-secret) |
| 3 | Ingress: full demo with routing | [Task 3](#task-3-ingress) |
| 4 | Ingress vs Ingress Controller | [ingress-vs-controller/README.md](ingress-vs-controller/README.md) |
| 5 | Troubleshooting (the trailing-newline Secret bug), before/after | [Task 5](#task-5-troubleshooting) |

**Deliverables:** ConfigMap YAML, Secret YAML (template), Ingress YAML, troubleshooting documentation, command output, this README.

**Environment:** Minikube (Docker driver) on Windows 11, Kubernetes v1.37.0, ingress-nginx addon. All output is real. Each result is shown as the exact command and its terminal output.

---

## Task 1: ConfigMap

A **ConfigMap** keeps non-sensitive configuration outside the container image, so the same image runs in dev, staging and production with different settings.

_The ConfigMap: three simple settings, plus a whole properties file stored under one key._

```console
$ cat 01-configmap/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # simple key/value settings (used as environment variables)
  APP_ENV: "staging"
  LOG_LEVEL: "info"
  APP_PORT: "8080"
  # a whole file stored under one key (used as a mounted file)
  app.properties: |
    greeting=Hello from a ConfigMap
    max_items=25
```

_**Create the ConfigMap** and look at it._

```console
$ kubectl apply -f 01-configmap/configmap.yaml && kubectl get configmap app-config && kubectl describe configmap app-config
configmap/app-config created
NAME         DATA   AGE
app-config   4      0s
Name:         app-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
APP_ENV:
----
staging

APP_PORT:
----
8080

LOG_LEVEL:
----
info

app.properties:
----
greeting=Hello from a ConfigMap
max_items=25



BinaryData
====

Events:  <none>
```

_A Pod that uses it in the three usual ways: one key as a named variable (`configMapKeyRef`), all keys as variables (`envFrom`), and a key as a mounted file (`volume`)._

```console
$ cat 01-configmap/pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-demo
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      env:
        # one key from the ConfigMap, under a name I choose
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_ENV
      envFrom:
        # every key of the ConfigMap as an environment variable
        - configMapRef:
            name: app-config
      volumeMounts:
        - name: config-volume
          mountPath: /etc/app-config
  volumes:
    - name: config-volume
      configMap:
        name: app-config
        items:
          - key: app.properties
            path: app.properties
```

_**Inject the ConfigMap into the Pod.**_

```console
$ kubectl apply -f 01-configmap/pod.yaml && kubectl wait --for=condition=Ready pod/config-demo --timeout=120s
pod/config-demo created
pod/config-demo condition met
```

_**Verify the values inside the container (environment).** ENVIRONMENT comes from the single key, the others from `envFrom`._

```console
$ kubectl exec config-demo -- env | grep -E "^(ENVIRONMENT|APP_ENV|APP_PORT|LOG_LEVEL)=" | sort
APP_ENV=staging
APP_PORT=8080
ENVIRONMENT=staging
LOG_LEVEL=info
```

_**Verify the mounted file**: the key `app.properties` became a file with the stored text._

```console
$ kubectl exec config-demo -- ls -l /etc/app-config; kubectl exec config-demo -- cat /etc/app-config/app.properties
total 0
lrwxrwxrwx    1 root     root            21 Oct 18 14:01 app.properties -> ..data/app.properties
greeting=Hello from a ConfigMap
max_items=25
```

### What happens when the ConfigMap changes

I apply a changed version (`configmap-v2.yaml`: APP_ENV production, new file content) and look again **without restarting the Pod**:

_After about a minute the **mounted file** shows the new text, but the **environment variable** still has the old value. Environment variables are fixed when the container starts; mounted ConfigMap files are refreshed by the kubelet._

```console
$ kubectl apply -f 01-configmap/configmap-v2.yaml && sleep 75 && echo "--- environment variable:" && kubectl exec config-demo -- sh -c "echo APP_ENV=\$APP_ENV" && echo "--- mounted file:" && kubectl exec config-demo -- cat /etc/app-config/app.properties
configmap/app-config configured
--- environment variable:
APP_ENV=staging
--- mounted file:
greeting=Hello after the update
max_items=50
```

_Restarting the Pod picks up the new environment value._

```console
$ kubectl delete pod config-demo && kubectl apply -f 01-configmap/pod.yaml && kubectl wait --for=condition=Ready pod/config-demo --timeout=120s && kubectl exec config-demo -- sh -c "echo APP_ENV=\$APP_ENV"
pod "config-demo" deleted from default namespace
pod/config-demo created
pod/config-demo condition met
APP_ENV=production
```

_Cleanup._

```console
$ kubectl delete pod config-demo --wait=false; kubectl delete configmap app-config
pod "config-demo" deleted from default namespace
configmap "app-config" deleted from default namespace
```

---

## Task 2: Secret

A **Secret** holds sensitive values (passwords, tokens, keys). It works like a ConfigMap but is stored base64-encoded, can be restricted with RBAC, can be encrypted at rest, and its values are hidden from `kubectl describe`.

### The manifest is a template only

_The file in this repository holds placeholders only. The real Secret is created from the command line with values that are never written to Git._

```console
$ cat 02-secret/secret.example.yaml
# TEMPLATE ONLY. Never commit a real Secret manifest to Git: base64 is an encoding, not encryption,
# so anyone who can read the repository can read the value. Create the real Secret with
#   kubectl create secret generic db-secret --from-literal=DB_USER=... --from-literal=DB_PASSWORD=...
# or from a secret manager / sealed secret, and keep this file with placeholders only.
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  DB_USER: "REPLACE_ME"
  DB_PASSWORD: "REPLACE_ME"
```

_**Create the Secret.** (The values are obviously fake demo values.)_

```console
$ kubectl create secret generic db-secret --from-literal=DB_USER=demo_user --from-literal=DB_PASSWORD=demo-password-123
secret/db-secret created
```

_describe shows the keys and sizes, never the values._

```console
$ kubectl get secret db-secret && kubectl describe secret db-secret
NAME        TYPE     DATA   AGE
db-secret   Opaque   2      0s
Name:         db-secret
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
DB_PASSWORD:  17 bytes
DB_USER:      9 bytes
```

_**Store sensitive values:** what is stored is base64. Anyone who can read the Secret object (or this YAML in Git) decodes it in one command: **base64 is encoding, not encryption.**_

```console
$ kubectl get secret db-secret -o jsonpath="{.data}"; echo; kubectl get secret db-secret -o jsonpath="{.data.DB_PASSWORD}" | base64 -d; echo
{"DB_PASSWORD":"ZGVtby1wYXNzd29yZC0xMjM=","DB_USER":"ZGVtb191c2Vy"}
demo-password-123
```

_A Pod that takes both values as environment variables (`secretKeyRef`) and also mounts the Secret as files._

```console
$ cat 02-secret/pod.yaml | head -n 24
apiVersion: v1
kind: Pod
metadata:
  name: secret-demo
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: DB_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: DB_PASSWORD
      volumeMounts:
        - name: secret-volume
          mountPath: /etc/db-secret
          readOnly: true
```

_**Inject the Secret into the Pod.**_

```console
$ kubectl apply -f 02-secret/pod.yaml && kubectl wait --for=condition=Ready pod/secret-demo --timeout=120s
pod/secret-demo created
pod/secret-demo condition met
```

_**Verify the values inside the container (environment).** The application sees the decoded values._

```console
$ kubectl exec secret-demo -- sh -c "echo DB_USER=\$DB_USER; echo DB_PASSWORD=\$DB_PASSWORD"
DB_USER=demo_user
DB_PASSWORD=demo-password-123
```

_**Verify the mounted files.** Each key is a file; the volume is a memory-backed filesystem (tmpfs), so the values are not written to the node disk._

```console
$ kubectl exec secret-demo -- ls -l /etc/db-secret; kubectl exec secret-demo -- cat /etc/db-secret/DB_USER; echo; kubectl exec secret-demo -- mount | grep db-secret
total 0
lrwxrwxrwx    1 root     root            18 Oct 18 14:03 DB_PASSWORD -> ..data/DB_PASSWORD
lrwxrwxrwx    1 root     root            14 Oct 18 14:03 DB_USER -> ..data/DB_USER
demo_user
tmpfs on /etc/db-secret type tmpfs (ro,relatime,size=11853004k,noswap)
```

### Why Secrets must not be committed to Git

- A Secret manifest stores the value **base64-encoded**, which anyone can reverse (shown above).
- Git **never forgets**: even after the file is deleted, the value stays in the history, in every clone and every fork. Rotating the password is then the only cure.
- Public or shared repositories, CI logs and backups multiply the exposure.

What to do instead:

| Practice | How |
|---|---|
| Keep only a **template** with placeholders in Git | `secret.example.yaml` (above) and `.gitignore` for real files |
| Create the Secret out of band | `kubectl create secret ...`, or from CI secrets (GitHub Actions secrets) |
| Encrypt it so it *can* live in Git | Sealed Secrets, SOPS (with KMS/age) |
| Fetch it from a secret manager at runtime | External Secrets Operator, Vault, AWS Secrets Manager |
| Protect it in the cluster | RBAC on `secrets`, encryption at rest in etcd, short-lived credentials |

_Cleanup._

```console
$ kubectl delete pod secret-demo --wait=false; kubectl delete secret db-secret
pod "secret-demo" deleted from default namespace
secret "db-secret" deleted from default namespace
```

---

## Task 3: Ingress

An **Ingress** is a set of HTTP routing rules (host and path -> Service). It does nothing on its own: an **Ingress controller** (here ingress-nginx) watches the rules and configures a reverse proxy. See [ingress-vs-controller](ingress-vs-controller/README.md).

### Step 1: Enable the Ingress controller (Minikube addon)

_The addon deploys the ingress-nginx controller into the ingress-nginx namespace._

```console
$ minikube addons enable ingress 2>&1 | tail -n 6
* After the addon is enabled, please run "minikube tunnel" and your ingress resources would be available at "127.0.0.1"
  - Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
  - Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
  - Using image registry.k8s.io/ingress-nginx/controller:v1.15.1
* Verifying ingress addon...
* The 'ingress' addon is enabled
```

_The controller is running and registered the IngressClass `nginx`._

```console
$ kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=300s && kubectl get pods -n ingress-nginx && kubectl get ingressclass
Waiting for deployment "ingress-nginx-controller" rollout to finish: 0 of 1 updated replicas are available...
deployment "ingress-nginx-controller" successfully rolled out
NAME                                       READY   STATUS      RESTARTS       AGE
ingress-nginx-admission-create-zx7lf       0/1     Completed   0              2m3s
ingress-nginx-admission-patch-zpp6m        0/1     Completed   2 (110s ago)   2m3s
ingress-nginx-controller-d7cd8c989-4x5kj   1/1     Running     0              2m3s
NAME              CONTROLLER             PARAMETERS   AGE
nginx (default)   k8s.io/ingress-nginx   <none>       2m3s
```

### Step 2: Deploy the applications and Services

_**Deploy the application and create the Services:** two small apps, each with 2 Pods and a ClusterIP Service._

```console
$ kubectl apply -f 03-ingress/apps.yaml && kubectl rollout status deployment/app-a --timeout=180s && kubectl rollout status deployment/app-b --timeout=180s && kubectl get deployments,svc,pods -l "app in (app-a,app-b)" 2>/dev/null; kubectl get svc app-a app-b
deployment.apps/app-a created
service/app-a created
deployment.apps/app-b created
service/app-b created
Waiting for deployment "app-a" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "app-a" rollout to finish: 1 of 2 updated replicas are available...
deployment "app-a" successfully rolled out
deployment "app-b" successfully rolled out
NAME                         READY   STATUS    RESTARTS   AGE
pod/app-a-b598dccdc-5f77k    1/1     Running   0          2s
pod/app-a-b598dccdc-97lkq    1/1     Running   0          2s
pod/app-b-56cd4479d5-dwrj2   1/1     Running   0          2s
pod/app-b-56cd4479d5-k64x7   1/1     Running   0          2s
NAME    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
app-a   ClusterIP   10.96.102.16     <none>        80/TCP    3s
app-b   ClusterIP   10.102.252.224   <none>        80/TCP    3s
```

_Each app answers on its Service name with its own text (tested from a temporary busybox Pod, because the http-echo image itself has no shell or wget)._

```console
$ kubectl run check --rm -i --restart=Never --image=busybox:1.36 -q -- sh -c "wget -qO- http://app-a; wget -qO- http://app-b" 2>&1 | grep -v "deleted"
Hello from APP-A
Hello from APP-B
```

### Step 3: Configure the Ingress

_Two rules: **path-based** (`demo.local/app-a` and `demo.local/app-b`) and **host-based** (`blog.demo.local` goes to app-b)._

```console
$ cat 03-ingress/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
spec:
  ingressClassName: nginx # handled by the ingress-nginx controller
  rules:
    # path-based routing: one host, two paths
    - host: demo.local
      http:
        paths:
          - path: /app-a
            pathType: Prefix
            backend:
              service:
                name: app-a
                port:
                  number: 80
          - path: /app-b
            pathType: Prefix
            backend:
              service:
                name: app-b
                port:
                  number: 80
    # host-based routing: a second host name goes to app-b
    - host: blog.demo.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-b
                port:
                  number: 80
```

_The controller picks the rules up (CLASS nginx, both hosts, port 80). On the Docker driver the ADDRESS column stays empty, because there is no cloud load balancer in front of the controller; it is reached through the node, as the next step shows._

```console
$ kubectl apply -f 03-ingress/ingress.yaml && sleep 15 && kubectl get ingress demo-ingress
ingress.networking.k8s.io/demo-ingress created
NAME           CLASS   HOSTS                        ADDRESS   PORTS   AGE
demo-ingress   nginx   demo.local,blog.demo.local             80      16s
```

_The rules and the backends (the Pod IPs behind each Service)._

```console
$ kubectl describe ingress demo-ingress | sed -n "/^Rules:/,/^Annotations:/p"
Rules:
  Host             Path  Backends
  ----             ----  --------
  demo.local       
                   /app-a   app-a:80 (10.244.0.164:5678,10.244.0.163:5678)
                   /app-b   app-b:80 (10.244.0.165:5678,10.244.0.166:5678)
  blog.demo.local  
                   /   app-b:80 (10.244.0.165:5678,10.244.0.166:5678)
Annotations:       <none>
```

### Step 4: Access through the Ingress and verify the routing

The controller listens on port 80 of the Minikube node. I call it with different `Host` headers and paths (a real DNS name is not needed, the `Host` header is what the routing uses). First from inside the node:

_Path `/app-a` -> app-a, path `/app-b` -> app-b, host `blog.demo.local` -> app-b._

```console
$ minikube ssh -- "curl -s -H \"Host: demo.local\" http://localhost/app-a; curl -s -H \"Host: demo.local\" http://localhost/app-b; curl -s -H \"Host: blog.demo.local\" http://localhost/"
Hello from APP-A
Hello from APP-B
Hello from APP-B
```

_Anything that matches no rule gets the controller default backend: 404._

```console
$ minikube ssh -- "curl -s -o /dev/null -w \"unknown path: HTTP %{http_code}\n\" -H \"Host: demo.local\" http://localhost/other; curl -s -o /dev/null -w \"unknown host: HTTP %{http_code}\n\" -H \"Host: nothing.example\" http://localhost/"
unknown path: HTTP 404
unknown host: HTTP 404
```

And from my Windows machine, through a port-forward to the controller Service:

_Three requests from Windows with the Host header set, each routed to the right application._

```console
$ kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /tmp/pf.txt 2>&1 & sleep 4; for t in 'demo.local/app-a' 'demo.local/app-b' 'blog.demo.local/'; do host=${t%%/*}; path=/${t#*/}; printf '%-22s -> ' "$host$path"; curl -s -H "Host: $host" http://localhost:8080$path; done; kill %1
demo.local/app-a       -> Hello from APP-A
demo.local/app-b       -> Hello from APP-B
blog.demo.local/       -> Hello from APP-B
```

| Request (Host + path) | Routed to |
|---|---|
| `demo.local` `/app-a` | Service `app-a` |
| `demo.local` `/app-b` | Service `app-b` |
| `blog.demo.local` `/` | Service `app-b` |
| anything else | default backend (404) |

_Cleanup of the demo (the controller stays enabled)._

```console
$ kubectl delete -f 03-ingress/ingress.yaml -f 03-ingress/apps.yaml
ingress.networking.k8s.io "demo-ingress" deleted from default namespace
deployment.apps "app-a" deleted from default namespace
service "app-a" deleted from default namespace
deployment.apps "app-b" deleted from default namespace
service "app-b" deleted from default namespace
```

---

## Task 4: Ingress vs Ingress Controller

Written up in [ingress-vs-controller/README.md](ingress-vs-controller/README.md): what each one is, the difference, why both are required, and examples.

---

## Task 5: Troubleshooting

Using the course's troubleshooting scenario: **"The Trailing Newline Secret Bug"**. *Symptom:* the database rejects the application's password although "I verified it is correct". The developer created the Secret value with `echo "mypassword" | base64`.

### 1. Identify the problem (before)

_The Pod stands in for the application. The password it received is **11** characters long and the authentication check fails, although the Secret "looks right"._

```console
$ kubectl apply -f troubleshooting/secret-bad.yaml -f troubleshooting/check-pod.yaml && kubectl wait --for=condition=Ready pod/check-pod --timeout=120s && sleep 2 && kubectl logs check-pod
secret/db-pass created
pod/check-pod created
pod/check-pod condition met
password length seen by the app: 11
AUTH CHECK: FAILED (password does not match)
```

_The Pod itself is Running: nothing in the Pod status hints at the problem, it is a data problem._

```console
$ kubectl get pod check-pod
NAME        READY   STATUS    RESTARTS   AGE
check-pod   1/1     Running   0          4s
```

### 2. Run troubleshooting commands (investigate)

_Read the stored (base64) value._

```console
$ kubectl get secret db-pass -o jsonpath="{.data.password}"; echo
bXlwYXNzd29yZAo=
```

_Decode it and dump the bytes: the last byte is `\n`, a **newline** (hex 0a) that is not part of the password._

```console
$ kubectl get secret db-pass -o jsonpath="{.data.password}" | base64 -d | od -c
0000000   m   y   p   a   s   s   w   o   r   d  \n
0000013
```

_Reproduce the cause: plain `echo` appends a newline (11 bytes, base64 ends in `Ao=`), `echo -n` does not (10 bytes, base64 ends in `==`)._

```console
$ echo "mypassword" | base64; echo -n "mypassword" | base64; echo "mypassword" | wc -c; echo -n "mypassword" | wc -c
bXlwYXNzd29yZAo=
bXlwYXNzd29yZA==
11
10
```

### 3. Root cause

The value was encoded with `echo "mypassword" | base64`. `echo` adds a trailing newline, so the Secret holds `mypassword\n` (11 bytes) instead of `mypassword` (10 bytes). The application sends the newline too and the database correctly rejects it.

### 4. Fix the issue

Encode without the newline (`echo -n`), or better, avoid manual base64 altogether with `kubectl create secret generic --from-literal` or `stringData`.

_Apply the corrected Secret and recreate the Pod (environment variables from a Secret are read only when the container starts, so a running Pod does not see the change)._

```console
$ kubectl apply -f troubleshooting/secret-fixed.yaml && kubectl delete pod check-pod --wait=true && kubectl apply -f troubleshooting/check-pod.yaml && kubectl wait --for=condition=Ready pod/check-pod --timeout=120s
secret/db-pass configured
pod "check-pod" deleted from default namespace
pod/check-pod created
pod/check-pod condition met
```

### 5. Capture before/after output

_**After:** the application now sees 10 characters and the check passes; the decoded bytes end with the last letter, with no `\n`._

```console
$ sleep 2; kubectl logs check-pod; echo "---"; kubectl get secret db-pass -o jsonpath="{.data.password}" | base64 -d | od -c
password length seen by the app: 10
AUTH CHECK: OK
---
0000000   m   y   p   a   s   s   w   o   r   d
0000012
```

_The safest way: let kubectl do the encoding. The value is the same correct `bXlwYXNzd29yZA==`._

```console
$ kubectl create secret generic db-pass-literal --from-literal=password=mypassword && kubectl get secret db-pass-literal -o jsonpath="{.data.password}"; echo
secret/db-pass-literal created
bXlwYXNzd29yZA==
```

| | Before | After |
|---|---|---|
| Stored value | `bXlwYXNzd29yZAo=` | `bXlwYXNzd29yZA==` |
| Decoded length | 11 bytes (`mypassword\n`) | 10 bytes (`mypassword`) |
| Application check | FAILED | OK |
| Cause | `echo` added a newline | `echo -n` / `--from-literal` |

_Cleanup._

```console
$ kubectl delete pod check-pod --wait=false; kubectl delete secret db-pass db-pass-literal
pod "check-pod" deleted from default namespace
secret "db-pass" deleted from default namespace
secret "db-pass-literal" deleted from default namespace
```

## What I learned

- **ConfigMaps** configure applications without rebuilding images. Mounted files update live (after about a minute); environment variables only change when the Pod restarts.
- **Secrets** are base64-encoded, not encrypted: never commit real values, keep a template, create them out of band or encrypt them (Sealed Secrets, SOPS) or fetch them from a secret manager.
- **Ingress** = routing rules, **Ingress controller** = the proxy that implements them; both are needed. Host and path rules send traffic to different Services behind one entry point.
- A Secret value can be wrong in an invisible way (a trailing newline). `echo -n`, `--from-literal` or `stringData` avoid it, and `base64 -d | od -c` finds it.
