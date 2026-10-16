# Task 1 - ConfigMap

**Ujjawal Prabhat - 24BCS10267 - Session 12**

- [x] Create a ConfigMap from **literals** and from a **file**
- [x] Inject it as **environment variables** (`configMapKeyRef` and `envFrom`)
- [x] Mount it as a **volume** (each key becomes a file)
- [x] Verify inside the container
- [x] Bonus: show how updates reach volumes but not env vars

A ConfigMap stores **non-sensitive** configuration as key/value pairs, separate from the image. The same image can then run in dev, staging and prod
with different config.

Files: [`app.properties`](app.properties), [`pod-with-configmap.yaml`](pod-with-configmap.yaml)

## Create (literal + file)

```
$ cat app.properties
app.name=yatri-booking
app.currency=INR
feature.newCheckout=true
cache.ttlSeconds=300

$ kubectl -n s12 create configmap app-config --from-literal=APP_ENV=staging --from-literal=LOG_LEVEL=debug --from-file=app.properties
configmap/app-config created

$ kubectl -n s12 get configmap app-config
NAME         DATA   AGE
app-config   3      0s

$ kubectl -n s12 describe configmap app-config
Name:         app-config
Namespace:    s12
Labels:       <none>
Annotations:  <none>

Data
====
APP_ENV:
----
staging

LOG_LEVEL:
----
debug

app.properties:
----
app.name=yatri-booking
app.currency=INR
feature.newCheckout=true
cache.ttlSeconds=300



BinaryData
====

Events:  <none>

$ kubectl -n s12 get configmap app-config -o yaml
apiVersion: v1
data:
  APP_ENV: staging
  LOG_LEVEL: debug
  app.properties: |
    app.name=yatri-booking
    app.currency=INR
    feature.newCheckout=true
    cache.ttlSeconds=300
kind: ConfigMap
metadata:
  creationTimestamp: "2026-10-06T11:59:39Z"
  name: app-config
  namespace: s12
  resourceVersion: "21652"
  uid: f9cbbeb6-7b95-418c-9355-4ff9a66f7eef
```

`--from-literal` creates one key per value. `--from-file` creates a key named after the file (`app.properties`), whose value is the whole file.

## Inject as env + volume, and verify inside the container

```
$ kubectl apply -f pod-with-configmap.yaml
pod/config-demo created

### verify inside the container
$ kubectl -n s12 logs config-demo
started with CFG_APP_ENV=staging LOG_LEVEL=debug

$ kubectl -n s12 exec config-demo -- sh -c 'env | grep -E "^(CFG_|LOG_LEVEL)" | sort'
CFG_APP_ENV=staging
CFG_LOG_LEVEL=debug
CFG_app.properties=app.name=yatri-booking
LOG_LEVEL=debug

$ kubectl -n s12 exec config-demo -- ls -la /etc/config
total 12
drwxrwxrwx    3 root     root          4096 Oct  6 11:59 .
drwxr-xr-x    1 root     root          4096 Oct  6 11:59 ..
drwxr-xr-x    2 root     root          4096 Oct  6 11:59 ..2026_10_06_11_59_39.3276680260
lrwxrwxrwx    1 root     root            32 Oct  6 11:59 ..data -> ..2026_10_06_11_59_39.3276680260
lrwxrwxrwx    1 root     root            14 Oct  6 11:59 APP_ENV -> ..data/APP_ENV
lrwxrwxrwx    1 root     root            16 Oct  6 11:59 LOG_LEVEL -> ..data/LOG_LEVEL
lrwxrwxrwx    1 root     root            21 Oct  6 11:59 app.properties -> ..data/app.properties

$ kubectl -n s12 exec config-demo -- cat /etc/config/app.properties
app.name=yatri-booking
app.currency=INR
feature.newCheckout=true
cache.ttlSeconds=300

$ kubectl -n s12 exec config-demo -- cat /etc/config/APP_ENV
staging
```

- `LOG_LEVEL` came from a single key (`configMapKeyRef`). `CFG_*` came from `envFrom` with a prefix. On Kubernetes 1.37 even the key
  `app.properties` became a variable (`CFG_app.properties`, multi-line value), because env-var name validation was relaxed in 1.34.
- In the volume, every key is a file. The files are symlinks into a timestamped `..data` directory, so the kubelet can swap
  all files in one atomic step when the ConfigMap changes.

## Update behaviour: volume vs env

```
### update the ConfigMap: volume files refresh, env vars do not
$ kubectl -n s12 create configmap app-config --from-literal=APP_ENV=production --from-literal=LOG_LEVEL=warn --from-file=app.properties --dry-run=client -o yaml | kubectl apply -f -
Warning: resource configmaps/app-config is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
configmap/app-config configured

19:59:40
file updated after ~65s
$ kubectl -n s12 exec config-demo -- cat /etc/config/APP_ENV
production
$ kubectl -n s12 exec config-demo -- sh -c 'echo CFG_APP_ENV=$CFG_APP_ENV LOG_LEVEL=$LOG_LEVEL'
CFG_APP_ENV=staging LOG_LEVEL=debug

$ kubectl -n s12 delete pod config-demo --wait
pod "config-demo" deleted from s12 namespace

$ kubectl apply -f pod-with-configmap.yaml
pod/config-demo created

$ kubectl -n s12 exec config-demo -- sh -c 'echo CFG_APP_ENV=$CFG_APP_ENV LOG_LEVEL=$LOG_LEVEL'
CFG_APP_ENV=production LOG_LEVEL=warn
```

The ConfigMap change was written at 19:59:40. **The mounted file changed on its own after about 65 s** (kubelet sync period + cache TTL).
**The environment variables did not change** (`staging`/`debug`), because env vars are set only when the container starts. After I recreated the pod,
it got `production`/`warn`. Practical rule: mount config files if the app can reload them, otherwise roll the Deployment
(`kubectl rollout restart`, or a checksum annotation in Helm).
