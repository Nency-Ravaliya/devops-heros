# 03 — Mini Project: Notes App with Helm

**Submitted by:** Piyush Bansal
**Cluster:** Docker Desktop Kubernetes v1.36.1 (single node, arm64)
**Helm:** v4.3.0
**Namespace used:** `p15-notes`

I followed `session-15-helm/mini-project/README.md` step by step. All output below was
captured from a live run.

## The chart

```text
notes-chart/
  Chart.yaml
  values.yaml          # dev: 1 replica, nginx:1.24, environment=development
  values-prod.yaml     # prod: 3 replicas, nginx:1.25, environment=production
  templates/
    configmap.yaml     # APP_NAME / ENVIRONMENT
    deployment.yaml    # envFrom the ConfigMap
    service.yaml       # NodePort 30090
```

- [Chart.yaml](notes-chart/Chart.yaml)
- [values.yaml](notes-chart/values.yaml), [values-prod.yaml](notes-chart/values-prod.yaml)
- [templates/](notes-chart/templates/)

The chart is the same as in the course folder with one addition. I added a `resources`
block (10m CPU / 16Mi request, 64Mi limit) to both values files and to the Deployment
template, because the cluster is shared and the course asks for small requests.

I installed into my own namespace (`-n p15-notes`) instead of `default`. To reach the app I
used `kubectl port-forward svc/notes-dev-svc 18152:80` and checked the `Server` header with
`curl`. That header shows which nginx version is really running.

## Step 8: Lint

```text
$ helm lint notes-chart
==> Linting notes-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

## Step 9: Render locally

Every `{{ }}` was replaced correctly:

```text
$ helm template notes-dev notes-chart
---
# Source: notes-chart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: notes-dev-config
data:
  APP_NAME: "notes-app"
  ENVIRONMENT: "development"

---
# Source: notes-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: notes-dev-svc
spec:
  type: NodePort
  selector:
    app: notes-dev
  ports:
    - port: 80
      targetPort: 80
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
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notes-dev
  template:
    metadata:
      labels:
        app: notes-dev
    spec:
      containers:
        - name: notes
          image: "nginx:1.24"
          ports:
            - containerPort: 80
          resources:
            limits:
              memory: 64Mi
            requests:
              cpu: 10m
              memory: 16Mi
          envFrom:
            - configMapRef:
                name: notes-dev-config
```

## Step 10: Install (development)

```text
$ kubectl create namespace p15-notes
namespace/p15-notes created

$ helm install notes-dev notes-chart -n p15-notes --wait --timeout 6m
NAME: notes-dev
LAST DEPLOYED: Wed Oct  7 22:21:58 2026
NAMESPACE: p15-notes
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None

$ kubectl get pods -n p15-notes
NAME                                READY   STATUS    RESTARTS   AGE
notes-dev-deploy-784dc89c44-hvfll   1/1     Running   0          8s

$ kubectl get services -n p15-notes
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
notes-dev-svc   NodePort   10.96.176.12   <none>        80:30090/TCP   10s

$ kubectl get configmaps -n p15-notes
NAME               DATA   AGE
kube-root-ca.crt   1      12s
notes-dev-config   2      11s

$ kubectl exec -n p15-notes deploy/notes-dev-deploy -- sh -c 'echo APP_NAME=$APP_NAME ENVIRONMENT=$ENVIRONMENT'
APP_NAME=notes-app ENVIRONMENT=development

$ curl -sI --retry 5 --retry-all-errors --retry-delay 1 http://localhost:18152/ | grep -E 'HTTP|Server'
HTTP/1.1 200 OK
Server: nginx/1.24.0
```

## Step 11: Upgrade to production values

```text
$ helm upgrade notes-dev notes-chart -n p15-notes -f notes-chart/values-prod.yaml --wait --timeout 6m
Release "notes-dev" has been upgraded. Happy Helming!
NAME: notes-dev
LAST DEPLOYED: Wed Oct  7 22:22:16 2026
NAMESPACE: p15-notes
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
TEST SUITE: None

$ kubectl rollout status deploy/notes-dev-deploy -n p15-notes --timeout 300s
deployment "notes-dev-deploy" successfully rolled out

$ kubectl get pods -n p15-notes
NAME                                READY   STATUS    RESTARTS   AGE
notes-dev-deploy-866f459f89-9g5js   1/1     Running   0          26s
notes-dev-deploy-866f459f89-jr2bc   1/1     Running   0          50s
notes-dev-deploy-866f459f89-wrfs9   1/1     Running   0          36s

$ kubectl get deploy notes-dev-deploy -n p15-notes -o wide --show-labels
NAME               READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR        LABELS
notes-dev-deploy   3/3     3            3           69s   notes        nginx:1.25   app=notes-dev   app.kubernetes.io/managed-by=Helm,app=notes-dev,environment=production

$ kubectl exec -n p15-notes deploy/notes-dev-deploy -- sh -c 'echo APP_NAME=$APP_NAME ENVIRONMENT=$ENVIRONMENT'
APP_NAME=notes-app ENVIRONMENT=production

$ curl -sI --retry 5 --retry-all-errors --retry-delay 1 http://localhost:18152/ | grep -E 'HTTP|Server'
HTTP/1.1 200 OK
Server: nginx/1.25.5
```

The release now has 3 pods running `nginx:1.25`, and `ENVIRONMENT=production` comes from the
ConfigMap.

## Step 12: Release history

```text
$ helm history notes-dev -n p15-notes
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Wed Oct  7 22:21:58 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Wed Oct  7 22:22:16 2026	deployed  	notes-chart-0.1.0	1.0        	Upgrade complete
```

## Step 13: Simulate a bad upgrade

```text
$ helm upgrade notes-dev notes-chart -n p15-notes --set image.tag=broken-tag-does-not-exist
Release "notes-dev" has been upgraded. Happy Helming!
NAME: notes-dev
LAST DEPLOYED: Wed Oct  7 22:23:18 2026
NAMESPACE: p15-notes
STATUS: deployed
REVISION: 3
DESCRIPTION: Upgrade complete
TEST SUITE: None

$ kubectl get pods -n p15-notes
NAME                                READY   STATUS         RESTARTS   AGE
notes-dev-deploy-7db5985bc-t8g6q    0/1     ErrImagePull   0          18s
notes-dev-deploy-866f459f89-jr2bc   1/1     Running        0          80s

$ kubectl get deploy notes-dev-deploy -n p15-notes -o wide
NAME               READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES                            SELECTOR
notes-dev-deploy   1/1     1            1           100s   notes        nginx:broken-tag-does-not-exist   app=notes-dev

$ kubectl get events -n p15-notes --field-selector reason=Failed -o custom-columns=REASON:.reason,MESSAGE:.message | head -3 | cut -c1-160
REASON   MESSAGE
Failed   Failed to pull image "nginx:broken-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:brok
Failed   Error: ErrImagePull

$ helm history notes-dev -n p15-notes
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Wed Oct  7 22:21:58 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Wed Oct  7 22:22:16 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
3       	Wed Oct  7 22:23:18 2026	deployed  	notes-chart-0.1.0	1.0        	Upgrade complete
```

Two things I noticed here:

1. **Helm said `deployed` / "Upgrade complete" even though the image cannot be pulled.** I did not
   pass `--wait`, and in Helm v4 the default wait strategy is `hookOnly`, so Helm does not check
   that the pods become ready. With `--wait` (or `--rollback-on-failure`) this upgrade would have failed.
2. **Replicas dropped from 3 to 1.** The command only had `--set image.tag=...` and no
   `-f values-prod.yaml`, so Helm used the chart defaults from `values.yaml` again
   (`replicaCount: 1`, `environment: development`) and only changed the tag. The old 1.25
   pod kept running because the new pod never became ready, so the rolling update could not
   replace it. That is why the Deployment still shows `1/1`.

## Step 14: Rollback to revision 2

```text
$ helm rollback notes-dev 2 -n p15-notes --wait --timeout 6m
Rollback was a success! Happy Helming!

$ kubectl rollout status deploy/notes-dev-deploy -n p15-notes --timeout 300s
deployment "notes-dev-deploy" successfully rolled out

$ kubectl get pods -n p15-notes
NAME                                READY   STATUS        RESTARTS   AGE
notes-dev-deploy-7db5985bc-t8g6q    0/1     Terminating   0          70s
notes-dev-deploy-866f459f89-h2574   1/1     Running       0          32s
notes-dev-deploy-866f459f89-jr2bc   1/1     Running       0          2m12s
notes-dev-deploy-866f459f89-mx5jf   1/1     Running       0          44s

$ kubectl get deploy notes-dev-deploy -n p15-notes -o wide
NAME               READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES       SELECTOR
notes-dev-deploy   3/3     3            3           2m32s   notes        nginx:1.25   app=notes-dev

$ curl -sI --retry 5 --retry-all-errors --retry-delay 1 http://localhost:18152/ | grep -E 'HTTP|Server'
HTTP/1.1 200 OK
Server: nginx/1.25.5

$ helm history notes-dev -n p15-notes
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Wed Oct  7 22:21:58 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Wed Oct  7 22:22:16 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
3       	Wed Oct  7 22:23:18 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
4       	Wed Oct  7 22:23:44 2026	deployed  	notes-chart-0.1.0	1.0        	Rollback to 2   
```

Back to 3 healthy pods on `nginx:1.25`, and the broken pod is terminating.

## Step 15: Clean up

```text
$ helm uninstall notes-dev -n p15-notes --wait
release "notes-dev" uninstalled

$ kubectl get pods -n p15-notes
NAME                                READY   STATUS        RESTARTS   AGE
notes-dev-deploy-866f459f89-h2574   1/1     Terminating   0          44s
notes-dev-deploy-866f459f89-jr2bc   1/1     Terminating   0          2m24s
notes-dev-deploy-866f459f89-mx5jf   1/1     Terminating   0          56s

$ kubectl get services -n p15-notes
No resources found in p15-notes namespace.

$ kubectl get configmaps -n p15-notes
NAME               DATA   AGE
kube-root-ca.crt   1      2m46s
```

A moment later everything was gone and I deleted my namespaces:

```text
$ kubectl get all -n p15-notes
No resources found in p15-notes namespace.

$ kubectl delete namespace p15-cmds p15-rollback p15-notes
namespace "p15-cmds" deleted
namespace "p15-rollback" deleted
namespace "p15-notes" deleted
```

(`kube-root-ca.crt` is created by Kubernetes in every namespace. It is not part of the chart.)

## Notes from the run

On my first run of this project, Step 11 (`helm upgrade ... --wait --timeout 3m`) failed with
`resource Deployment/p15-notes/notes-dev-deploy not ready ... context deadline exceeded`.
The shared cluster was busy and the new pods were not all ready within 3 minutes, so Helm marked
revision 2 as `failed`. The rollout finished a little later anyway. I deleted the namespace and
ran the whole project again with `--timeout 6m`. The output above is from that clean run.

## What I practised

```text
[PASS] Created a Helm chart (Chart.yaml, values.yaml, values-prod.yaml, 3 templates)
[PASS] Linted and rendered it locally with helm lint / helm template
[PASS] Installed it (dev values) and checked pods, service, configmap, env vars, HTTP
[PASS] Upgraded with values-prod.yaml (1 -> 3 replicas, nginx 1.24 -> 1.25, env -> production)
[PASS] Simulated a bad upgrade (ErrImagePull)
[PASS] Rolled back to the healthy revision 2
[PASS] Cleaned up with helm uninstall and deleted my namespaces
```

## What I learned

- One chart with different values files gives you dev and prod setups without copying any YAML.
- `helm upgrade` without `-f` or `--reuse-values` goes back to the chart defaults. That is how
  my "only change the tag" upgrade also cut prod from 3 replicas to 1.
- Without `--wait`, Helm marks a broken release as `deployed`. I should use `--wait` or `--rollback-on-failure` for real deploys.
- When a release goes bad, `helm history` plus `helm rollback <rev>` fixes it quickly.
