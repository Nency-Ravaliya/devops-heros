# Task 3 - Mini project: package and deploy the Notes app with Helm

**Ujjawal Prabhat - 24BCS10267 - Session 15 (Helm)**

I followed the course spec in `session-15-helm/mini-project/README.md`, steps 1-15. I wrote the chart myself in `notes-chart/`. It produces exactly what the spec asks for (`<release>-deploy`, `<release>-svc`, `<release>-config`, label `app: <release>`, NodePort 30090, `APP_NAME` / `ENVIRONMENT` from a ConfigMap, dev and prod values files). I also added the following, so the chart is easier to configure and reuse:

| Addition | Why |
|---|---|
| `templates/_helpers.tpl` | Named templates `notes-chart.fullname`, `.labels`, `.selectorLabels`, `.chart`, `.image`, so names, labels and the image string are defined once |
| Standard labels (`helm.sh/chart`, `app.kubernetes.io/managed-by`, `app.kubernetes.io/version`) | Lets you tell which chart version and release owns an object |
| `app.message` -> `index.html` in the ConfigMap, mounted into nginx | Each environment and revision serves a visibly different page, so `curl` proves which version is live |
| `checksum/config` pod annotation | Changing only the ConfigMap still rolls the pods |
| `service.type` (NodePort or ClusterIP); `nodePort` rendered only for NodePort | The same chart works without a NodePort (Task 2 uses ClusterIP) |
| `resources`, readiness and liveness probes (`probes.enabled`, `probes.path`) | Production basics, all configurable |
| `NOTES.txt` | Prints image, replica count, revision and how to reach the app after install or upgrade |

Namespace: `s15-mini`, because the cluster is shared. The spec uses `default`.

## Chart files

```console
$ find notes-chart -type f | sort
notes-chart/Chart.yaml
notes-chart/templates/NOTES.txt
notes-chart/templates/_helpers.tpl
notes-chart/templates/configmap.yaml
notes-chart/templates/deployment.yaml
notes-chart/templates/service.yaml
notes-chart/values-prod.yaml
notes-chart/values.yaml
```

`values.yaml` (development defaults):

```yaml
replicaCount: 1
image:
  repository: nginx
  tag: "1.24"
  pullPolicy: IfNotPresent
service:
  type: NodePort
  port: 80
  nodePort: 30090
app:
  name: notes-app
  environment: development
  message: "Welcome to the Notes app"
resources:
  requests:
    cpu: 50m
    memory: 32Mi
  limits:
    cpu: 200m
    memory: 128Mi
probes:
  enabled: true
  path: /
```

`values-prod.yaml` overrides `replicaCount: 3`, `image.tag: "1.25"`, `app.environment: production` and `app.message`.

---

## Step 8 - Lint

```console
$ helm lint notes-chart
==> Linting notes-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

$ helm lint notes-chart -f notes-chart/values-prod.yaml
==> Linting notes-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

## Step 9 - Render locally (`helm template`)

```console
$ helm template notes-dev notes-chart
---
# Source: notes-chart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: notes-dev-config
  labels:
    app: notes-dev
    environment: development
    helm.sh/chart: notes-chart-0.1.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/version: "1.24"
data:
  APP_NAME: "notes-app"
  ENVIRONMENT: "development"
  index.html: |
    <h1>Welcome to the Notes app</h1>
    <p>app=notes-app env=development image=nginx:1.24 release=notes-dev revision=1</p>

---
# Source: notes-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: notes-dev-svc
  labels:
    app: notes-dev
    environment: development
    helm.sh/chart: notes-chart-0.1.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/version: "1.24"
spec:
  type: NodePort
  selector:
    app: notes-dev
  ports:
    - name: http
      port: 80
      targetPort: http
      nodePort: 30090

---
# Source: notes-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notes-dev-deploy
  labels:
    app: notes-dev
    environment: development
    helm.sh/chart: notes-chart-0.1.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/version: "1.24"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notes-dev
  template:
    metadata:
      labels:
        app: notes-dev
      annotations:
        # a change in the ConfigMap changes this hash and rolls the pods
        checksum/config: 56a7d0abbd8b657db1f7b4bc4aca831869ba2c4709e431bf8e40ed8df81ebf0b
    spec:
      containers:
        - name: notes
          image: "nginx:1.24"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 80
          envFrom:
            - configMapRef:
                name: notes-dev-config
          volumeMounts:
            - name: html
              mountPath: /usr/share/nginx/html/index.html
              subPath: index.html
          resources:
            limits:
              cpu: 200m
              memory: 128Mi
            requests:
              cpu: 50m
              memory: 32Mi
          readinessProbe:
            httpGet:
              path: /
              port: http
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
      volumes:
        - name: html
          configMap:
            name: notes-dev-config
            items:
              - key: index.html
                path: index.html
```

Check that every `{{ }}` was replaced, see what the prod values change, and confirm the ClusterIP switch drops the `nodePort`:

```console
$ helm template notes-dev notes-chart | grep -c '{{'
0

$ helm template notes-dev notes-chart -f notes-chart/values-prod.yaml | grep -E 'replicas:|image:|ENVIRONMENT'
  ENVIRONMENT: "production"
  replicas: 3
          image: "nginx:1.25"

$ helm template notes-dev notes-chart --set service.type=ClusterIP --show-only templates/service.yaml
---
# Source: notes-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: notes-dev-svc
  labels:
    app: notes-dev
    environment: development
    helm.sh/chart: notes-chart-0.1.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/version: "1.24"
spec:
  type: ClusterIP
  selector:
    app: notes-dev
  ports:
    - name: http
      port: 80
      targetPort: http
```

## Step 10 - Install (development)

```console
$ kubectl create namespace s15-mini
namespace/s15-mini created

$ helm install notes-dev notes-chart -n s15-mini --wait
NAME: notes-dev
LAST DEPLOYED: Tue Oct  6 19:33:59 2026
NAMESPACE: s15-mini
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
NOTES:
notes-app (development) deployed as release "notes-dev" in namespace "s15-mini".
Image: nginx:1.24   Replicas: 1   Revision: 1

Check it:
  kubectl get pods -n s15-mini -l app=notes-dev
  kubectl port-forward -n s15-mini svc/notes-dev-svc 8080:80
  curl http://localhost:8080

$ kubectl get pods -n s15-mini
NAME                                READY   STATUS    RESTARTS   AGE
notes-dev-deploy-6f58f888d4-q4rvf   1/1     Running   0          1s

$ kubectl get services -n s15-mini
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
notes-dev-svc   NodePort   10.96.242.19   <none>        80:30090/TCP   1s

$ kubectl get configmaps -n s15-mini
NAME               DATA   AGE
kube-root-ca.crt   1      2s
notes-dev-config   3      1s
```

In that run I curled NodePort 30090 on a node one second after the install, and the reply was empty because kube-proxy had not programmed the NodePort yet. After the whole run was finished, I installed the dev release again on its own, waited 5 seconds, verified it, and removed it:

```console
$ helm install notes-dev notes-chart -n s15-mini --wait | head -6
NAME: notes-dev
LAST DEPLOYED: Tue Oct  6 19:39:13 2026
NAMESPACE: s15-mini
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete

$ kubectl get pods,svc -n s15-mini
NAME                                    READY   STATUS    RESTARTS   AGE
pod/notes-dev-deploy-6f58f888d4-hbjcb   1/1     Running   0          7s

NAME                    TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
service/notes-dev-svc   NodePort   10.96.20.34   <none>        80:30090/TCP   7s

$ docker exec devops-heros-worker curl -s http://localhost:30090
<h1>Welcome to the Notes app</h1>
<p>app=notes-app env=development image=nginx:1.24 release=notes-dev revision=1</p>

$ kubectl exec deploy/notes-dev-deploy -n s15-mini -- printenv APP_NAME ENVIRONMENT
notes-app
development

$ helm uninstall notes-dev -n s15-mini
release "notes-dev" uninstalled
```

(kind nodes are Docker containers, so `docker exec <node> curl localhost:30090` is how to reach a NodePort from the host.)

## Step 11 - Upgrade to production values

```console
$ helm upgrade notes-dev notes-chart -n s15-mini -f notes-chart/values-prod.yaml --wait
Release "notes-dev" has been upgraded. Happy Helming!
NAME: notes-dev
LAST DEPLOYED: Tue Oct  6 19:34:01 2026
NAMESPACE: s15-mini
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
TEST SUITE: None
NOTES:
notes-app (production) deployed as release "notes-dev" in namespace "s15-mini".
Image: nginx:1.25   Replicas: 3   Revision: 2
...

$ kubectl get pods -n s15-mini
NAME                                READY   STATUS      RESTARTS   AGE
notes-dev-deploy-6f58f888d4-2dgnq   0/1     Completed   0          4s
notes-dev-deploy-6f58f888d4-b98n7   0/1     Completed   0          4s
notes-dev-deploy-7494b8f867-f466c   1/1     Running     0          4s
notes-dev-deploy-7494b8f867-tgpjm   1/1     Running     0          2s
notes-dev-deploy-7494b8f867-zrlml   1/1     Running     0          1s

$ kubectl get deploy notes-dev-deploy -n s15-mini -o wide
NAME               READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR
notes-dev-deploy   3/3     3            3           5s    notes        nginx:1.25   app=notes-dev

$ docker exec devops-heros-worker curl -s http://localhost:30090
<h1>Notes app - production</h1>
<p>app=notes-app env=production image=nginx:1.25 release=notes-dev revision=2</p>
```

3 pods are running on `nginx:1.25`. The `Completed` pods are the old dev-ReplicaSet pods shutting down.

## Step 12 - Release history

```console
$ helm history notes-dev -n s15-mini
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 19:33:59 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Tue Oct  6 19:34:01 2026	deployed  	notes-chart-0.1.0	1.0        	Upgrade complete
```

## Step 13 - Simulate a bad upgrade

```console
$ helm upgrade notes-dev notes-chart -n s15-mini -f notes-chart/values-prod.yaml --set image.tag=broken-tag-does-not-exist
Release "notes-dev" has been upgraded. Happy Helming!
NAME: notes-dev
LAST DEPLOYED: Tue Oct  6 19:34:05 2026
NAMESPACE: s15-mini
STATUS: deployed
REVISION: 3
DESCRIPTION: Upgrade complete
TEST SUITE: None
NOTES:
notes-app (production) deployed as release "notes-dev" in namespace "s15-mini".
Image: nginx:broken-tag-does-not-exist   Replicas: 3   Revision: 3
...

$ kubectl get pods -n s15-mini        # 40 seconds later
NAME                                READY   STATUS         RESTARTS   AGE
notes-dev-deploy-5f85446c64-ft7fl   0/1     ErrImagePull   0          41s
notes-dev-deploy-7494b8f867-f466c   1/1     Running        0          45s
notes-dev-deploy-7494b8f867-tgpjm   1/1     Running        0          43s
notes-dev-deploy-7494b8f867-zrlml   1/1     Running        0          42s

$ helm history notes-dev -n s15-mini
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 19:33:59 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Tue Oct  6 19:34:01 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
3       	Tue Oct  6 19:34:05 2026	deployed  	notes-chart-0.1.0	1.0        	Upgrade complete

$ kubectl describe pod -n s15-mini $(kubectl get pods -n s15-mini --no-headers | grep -v Running | head -1 | awk '{print $1}') | sed -n '/Events:/,$p' | tail -4
  Warning  Failed     19s (x2 over 37s)  kubelet            spec.containers{notes}: Failed to pull image "nginx:broken-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:broken-tag-does-not-exist": failed to resolve reference "docker.io/library/nginx:broken-tag-does-not-exist": docker.io/library/nginx:broken-tag-does-not-exist: not found
  Warning  Failed     19s (x2 over 37s)  kubelet            spec.containers{notes}: Error: ErrImagePull
  Normal   BackOff    5s (x2 over 37s)   kubelet            spec.containers{notes}: Back-off pulling image "nginx:broken-tag-does-not-exist"
  Warning  Failed     5s (x2 over 37s)   kubelet            spec.containers{notes}: Error: ImagePullBackOff

$ docker exec devops-heros-worker curl -s http://localhost:30090
<h1>Notes app - production</h1>
<p>app=notes-app env=production image=nginx:1.25 release=notes-dev revision=2</p>
```

Two things differ from the spec's expected output, and both are worth noting:
- **Helm reported revision 3 as `deployed`** even though the image does not exist. Without `--wait`, Helm only checks that the API server accepted the objects. `helm upgrade --wait` (or `--atomic` / `--rollback-on-failure`) would have caught the failure, and `--atomic` would also have rolled back automatically.
- **Only one pod is broken, and the app stayed up.** The Deployment uses the default RollingUpdate strategy (25% maxSurge and maxUnavailable). Kubernetes starts one new pod and waits for it to become Ready before removing any old pods. The new pod never becomes Ready, so the 3 old `nginx:1.25` pods keep serving, as the `curl` shows. The rollout is stuck, not down.

## Step 14 - Roll back to revision 2

```console
$ helm rollback notes-dev 2 -n s15-mini --wait
Rollback was a success! Happy Helming!

$ kubectl get pods -n s15-mini
NAME                                READY   STATUS    RESTARTS   AGE
notes-dev-deploy-7494b8f867-f466c   1/1     Running   0          50s
notes-dev-deploy-7494b8f867-tgpjm   1/1     Running   0          48s
notes-dev-deploy-7494b8f867-zrlml   1/1     Running   0          47s

$ helm history notes-dev -n s15-mini
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 19:33:59 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Tue Oct  6 19:34:01 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
3       	Tue Oct  6 19:34:05 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
4       	Tue Oct  6 19:34:46 2026	deployed  	notes-chart-0.1.0	1.0        	Rollback to 2   

$ kubectl get deploy notes-dev-deploy -n s15-mini -o wide
NAME               READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR
notes-dev-deploy   3/3     3            3           51s   notes        nginx:1.25   app=notes-dev

$ docker exec devops-heros-worker curl -s http://localhost:30090
<h1>Notes app - production</h1>
<p>app=notes-app env=production image=nginx:1.25 release=notes-dev revision=2</p>
```

The broken pod is gone. The three healthy pods from revision 2 (hash `7494b8f867`) were never restarted, because the rolled-back pod template is identical to theirs. The Deployment simply scaled the broken ReplicaSet down to 0.

## Step 15 - Clean up

```console
$ helm uninstall notes-dev -n s15-mini
release "notes-dev" uninstalled

$ kubectl get pods -n s15-mini
No resources found in s15-mini namespace.

$ kubectl get services -n s15-mini
No resources found in s15-mini namespace.

$ kubectl get configmaps -n s15-mini
NAME               DATA   AGE
kube-root-ca.crt   1      88s

$ helm list -n s15-mini
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION
```

All release resources are gone. `kube-root-ca.crt` is created automatically in every namespace and does not belong to the release.

## What I practiced

```text
[PASS] Created a Helm chart from scratch (with _helpers.tpl, labels, NOTES.txt, configurable values)
[PASS] Used values.yaml and values-prod.yaml
[PASS] Validated the chart with helm lint and rendered it with helm template
[PASS] Deployed to Kubernetes with helm install
[PASS] Upgraded the release with different values (1 -> 3 replicas, nginx 1.24 -> 1.25)
[PASS] Simulated a bad upgrade (broken image tag) and diagnosed it
[PASS] Rolled back to a healthy revision
[PASS] Cleaned up with helm uninstall
```
