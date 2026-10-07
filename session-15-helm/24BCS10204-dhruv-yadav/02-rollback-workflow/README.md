# Task 2 - Helm rollback workflow

**Dhruv Yadav - 24BCS10204 - Session 15 (Helm)**

Workflow: **Install -> Verify -> Upgrade -> Verify -> Upgrade again -> Verify -> Rollback -> Verify**

The chart is my own `../03-mini-project/notes-chart`. The release is `notes-demo` in namespace `s15`. The Service is ClusterIP here (`service.type: ClusterIP` in each values file), so it does not compete for NodePort 30090 with the mini project. Each revision differs in three ways you can see from outside the cluster:

| Revision | Values file | Replicas | Image | ConfigMap `ENVIRONMENT` | Page message (`app.message`) |
|---|---|---|---|---|---|
| 1 | `values-v1.yaml` | 1 | nginx:1.24 | development | v1 - first install |
| 2 | `values-v2.yaml` | 2 | nginx:1.24 | staging | v2 - scaled to two replicas |
| 3 | `values-v3.yaml` | 3 | nginx:1.25 | production | v3 - nginx 1.25 with three replicas |
| 4 | `helm rollback notes-demo 2` | 2 | nginx:1.24 | staging | v2 - scaled to two replicas |

The page is served from the chart's ConfigMap (`index.html`), so `curl` shows directly which revision is live. The verification commands are the same at every step:
```bash
kubectl get deploy notes-demo-deploy -n s15 -o wide                      # replicas + image
kubectl get pods -n s15 -l app=notes-demo
kubectl get configmap notes-demo-config -n s15 -o jsonpath='{.data.ENVIRONMENT}'
kubectl exec deploy/notes-demo-deploy -n s15 -- curl -s http://notes-demo-svc   # through the Service
```

---

## Step 1 - Install (revision 1)

```console
$ helm install notes-demo ../03-mini-project/notes-chart -n s15 -f values-v1.yaml --wait
NAME: notes-demo
LAST DEPLOYED: Tue Oct  6 19:31:15 2026
NAMESPACE: s15
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
NOTES:
notes-app (development) deployed as release "notes-demo" in namespace "s15".
Image: nginx:1.24   Replicas: 1   Revision: 1

Check it:
  kubectl get pods -n s15 -l app=notes-demo
  kubectl port-forward -n s15 svc/notes-demo-svc 8080:80
  curl http://localhost:8080
```

## Step 2 - Verify revision 1

```console
$ kubectl get deploy notes-demo-deploy -n s15 -o wide
NAME                READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR
notes-demo-deploy   1/1     1            1           22s   notes        nginx:1.24   app=notes-demo

$ kubectl get pods -n s15 -l app=notes-demo
NAME                                 READY   STATUS    RESTARTS   AGE
notes-demo-deploy-84755b6b58-5c8bl   1/1     Running   0          22s

$ kubectl get configmap notes-demo-config -n s15 -o jsonpath='{.data.ENVIRONMENT}{"\n"}'
development

$ kubectl exec deploy/notes-demo-deploy -n s15 -- curl -s http://notes-demo-svc
<h1>v1 - first install</h1>
<p>app=notes-app env=development image=nginx:1.24 release=notes-demo revision=1</p>

$ helm history notes-demo -n s15
REVISION	UPDATED                 	STATUS  	CHART            	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 19:31:15 2026	deployed	notes-chart-0.1.0	1.0        	Install complete
```

## Step 3 - Upgrade (revision 2)

```console
$ helm upgrade notes-demo ../03-mini-project/notes-chart -n s15 -f values-v2.yaml --wait
Release "notes-demo" has been upgraded. Happy Helming!
NAME: notes-demo
LAST DEPLOYED: Tue Oct  6 19:31:38 2026
NAMESPACE: s15
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
TEST SUITE: None
NOTES:
notes-app (staging) deployed as release "notes-demo" in namespace "s15".
Image: nginx:1.24   Replicas: 2   Revision: 2
...
```

## Step 4 - Verify revision 2

```console
$ kubectl get deploy notes-demo-deploy -n s15 -o wide
NAME                READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR
notes-demo-deploy   2/2     2            2           47s   notes        nginx:1.24   app=notes-demo

$ kubectl get pods -n s15 -l app=notes-demo
NAME                                 READY   STATUS        RESTARTS   AGE
notes-demo-deploy-5c5d9ddbcd-gpgz9   1/1     Running       0          24s
notes-demo-deploy-5c5d9ddbcd-hxp89   1/1     Running       0          2s
notes-demo-deploy-84755b6b58-5c8bl   1/1     Terminating   0          47s

$ kubectl get configmap notes-demo-config -n s15 -o jsonpath='{.data.ENVIRONMENT}{"\n"}'
staging

$ kubectl exec deploy/notes-demo-deploy -n s15 -- curl -s http://notes-demo-svc
<h1>v2 - scaled to two replicas</h1>
<p>app=notes-app env=staging image=nginx:1.24 release=notes-demo revision=2</p>

$ helm get values notes-demo -n s15
USER-SUPPLIED VALUES:
app:
  environment: staging
  message: v2 - scaled to two replicas
image:
  tag: "1.24"
replicaCount: 2
service:
  type: ClusterIP
```

The image did not change, but the pods were still replaced: the pod-template hash changed from `84755b6b58` to `5c5d9ddbcd`. This is because the chart puts `checksum/config` (a sha256 of the ConfigMap) into the pod annotations. When the ConfigMap content changes, the pods roll, so they always serve the new config.

## Step 5 - Upgrade again (revision 3)

```console
$ helm upgrade notes-demo ../03-mini-project/notes-chart -n s15 -f values-v3.yaml --wait
Release "notes-demo" has been upgraded. Happy Helming!
NAME: notes-demo
LAST DEPLOYED: Tue Oct  6 19:32:02 2026
NAMESPACE: s15
STATUS: deployed
REVISION: 3
DESCRIPTION: Upgrade complete
TEST SUITE: None
NOTES:
notes-app (production) deployed as release "notes-demo" in namespace "s15".
Image: nginx:1.25   Replicas: 3   Revision: 3
...
```

## Step 6 - Verify revision 3

```console
$ kubectl get deploy notes-demo-deploy -n s15 -o wide
NAME                READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES       SELECTOR
notes-demo-deploy   3/3     3            3           2m5s   notes        nginx:1.25   app=notes-demo

$ kubectl get pods -n s15 -l app=notes-demo
NAME                                 READY   STATUS        RESTARTS   AGE
notes-demo-deploy-5c5d9ddbcd-gpgz9   0/1     Completed     0          102s
notes-demo-deploy-5c5d9ddbcd-hxp89   1/1     Terminating   0          80s
notes-demo-deploy-78954cdb7c-54bmz   1/1     Running       0          78s
notes-demo-deploy-78954cdb7c-774gg   1/1     Running       0          1s
notes-demo-deploy-78954cdb7c-wz4t5   1/1     Running       0          45s

$ kubectl get configmap notes-demo-config -n s15 -o jsonpath='{.data.ENVIRONMENT}{"\n"}'
production

$ kubectl exec deploy/notes-demo-deploy -n s15 -- curl -s http://notes-demo-svc
<h1>v3 - nginx 1.25 with three replicas</h1>
<p>app=notes-app env=production image=nginx:1.25 release=notes-demo revision=3</p>

$ helm history notes-demo -n s15
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 19:31:15 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Tue Oct  6 19:31:38 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
3       	Tue Oct  6 19:32:02 2026	deployed  	notes-chart-0.1.0	1.0        	Upgrade complete
```

Before rolling back, compare the stored values of the two revisions:

```console
$ helm get values notes-demo -n s15 --revision 2
USER-SUPPLIED VALUES:
app:
  environment: staging
  message: v2 - scaled to two replicas
image:
  tag: "1.24"
replicaCount: 2
service:
  type: ClusterIP

$ helm get values notes-demo -n s15 --revision 3
USER-SUPPLIED VALUES:
app:
  environment: production
  message: v3 - nginx 1.25 with three replicas
image:
  tag: "1.25"
replicaCount: 3
service:
  type: ClusterIP
```

## Step 7 - Roll back to revision 2

```console
$ helm rollback notes-demo 2 -n s15 --wait
Rollback was a success! Happy Helming!
```

## Step 8 - Verify the rollback

```console
$ kubectl get deploy notes-demo-deploy -n s15 -o wide
NAME                READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES       SELECTOR
notes-demo-deploy   2/2     2            2           2m13s   notes        nginx:1.24   app=notes-demo

$ kubectl get pods -n s15 -l app=notes-demo
NAME                                 READY   STATUS    RESTARTS   AGE
notes-demo-deploy-5c5d9ddbcd-d4wh9   1/1     Running   0          8s
notes-demo-deploy-5c5d9ddbcd-w4p76   1/1     Running   0          6s

$ kubectl get configmap notes-demo-config -n s15 -o jsonpath='{.data.ENVIRONMENT}{"\n"}'
staging

$ kubectl exec deploy/notes-demo-deploy -n s15 -- curl -s http://notes-demo-svc
<h1>v2 - scaled to two replicas</h1>
<p>app=notes-app env=staging image=nginx:1.24 release=notes-demo revision=2</p>

$ helm history notes-demo -n s15
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 19:31:15 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Tue Oct  6 19:31:38 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
3       	Tue Oct  6 19:32:02 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
4       	Tue Oct  6 19:33:20 2026	deployed  	notes-chart-0.1.0	1.0        	Rollback to 2   

$ helm get values notes-demo -n s15
USER-SUPPLIED VALUES:
app:
  environment: staging
  message: v2 - scaled to two replicas
image:
  tag: "1.24"
replicaCount: 2
service:
  type: ClusterIP

$ helm status notes-demo -n s15
NAME: notes-demo
LAST DEPLOYED: Tue Oct  6 19:33:20 2026
NAMESPACE: s15
STATUS: deployed
REVISION: 4
DESCRIPTION: Rollback to 2
RESOURCES:
==> v1/Pod(related)
NAME                                 READY   STATUS    RESTARTS   AGE
notes-demo-deploy-5c5d9ddbcd-d4wh9   1/1     Running   0          9s
notes-demo-deploy-5c5d9ddbcd-w4p76   1/1     Running   0          7s

==> v1/ConfigMap
NAME                DATA   AGE
notes-demo-config   3      2m14s

==> v1/Service
NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
notes-demo-svc   ClusterIP   10.96.153.76   <none>        80/TCP    2m14s

==> v1/Deployment
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
notes-demo-deploy   2/2     2            2           2m14s


TEST SUITE: None
NOTES:
notes-app (staging) deployed as release "notes-demo" in namespace "s15".
Image: nginx:1.24   Replicas: 2   Revision: 2
...
```

## What the rollback shows

1. **Rollback creates a revision.** History grew to 4 (`Rollback to 2`). Revision 3 is kept as `superseded`, so you could still roll *forward* to it with `helm rollback notes-demo 3`.
2. **Rollback re-applies the stored manifest. It does not re-render the chart.** The page says `revision=2` while the release is at revision 4. The ConfigMap template contains `{{ .Release.Revision }}`, and Helm re-applied the manifest it saved for revision 2 exactly as rendered then.
3. **The Deployment returned to the identical pod template.** The new pods have hash `5c5d9ddbcd` again, the same as revision 2: 2 replicas, nginx:1.24, ConfigMap `staging`.
4. `--wait` makes `helm upgrade` and `helm rollback` return only once the pods are ready. Without it, Helm marks the revision `deployed` as soon as the API server accepts the objects (see the bad-upgrade step in Task 3).

Cleanup: `helm uninstall notes-demo -n s15` (done at the end of the session).
