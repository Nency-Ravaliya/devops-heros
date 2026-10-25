# Task 2 – Rollback workflow

**Name:** Kushal Talati · **Enrollment No:** 24BCS10123 · chart: the professor's `07-install-upgrade/app-chart` (unmodified) · namespace `s15-helm`

Script: [`../scripts/02-rollback-workflow.sh`](../scripts/02-rollback-workflow.sh) · Raw log: [`../logs/02-rollback-workflow.txt`](../logs/02-rollback-workflow.txt)

```text
Install (v1)  ->  Upgrade (v2)  ->  Verify  ->  Upgrade again (v3)  ->  Verify  ->  Rollback 2  ->  Verify
 1 x 1.24          2 x 1.25                       3 x 1.26                            2 x 1.25
 REVISION 1        REVISION 2                     REVISION 3                          REVISION 4
```

One values file per step, so every revision is reproducible:

| File | replicaCount | image |
|---|---|---|
| [values-v1.yaml](values-v1.yaml) | 1 | nginx:1.24 |
| [values-v2.yaml](values-v2.yaml) | 2 | nginx:1.25 |
| [values-v3.yaml](values-v3.yaml) | 3 | nginx:1.26 |

## 1. Install

```text
$ helm install web-app 07-install-upgrade/app-chart -f values-v1.yaml
NAME: web-app
LAST DEPLOYED: Wed Oct  7 23:14:48 2026
NAMESPACE: s15-helm
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete

$ pods web-app
NAME                           IMAGE        STATUS    READY
web-app-app-5769cccf7c-p6f6b   nginx:1.24   Running   true

$ helm history web-app
REVISION	UPDATED                 	STATUS  	CHART          	APP VERSION	DESCRIPTION
1       	Wed Oct  7 23:14:48 2026	deployed	app-chart-0.1.0	1.0        	Install complete
```

## 2. Upgrade → 3. Verify

```text
$ helm upgrade web-app 07-install-upgrade/app-chart -f values-v2.yaml
Release "web-app" has been upgraded. Happy Helming!
STATUS: deployed
REVISION: 2

$ pods web-app                      # rolling update in progress: old 1.24 pods finishing, two 1.25 pods up
NAME                           IMAGE        STATUS      READY
web-app-app-5769cccf7c-p6f6b   nginx:1.24   Succeeded   false
web-app-app-5769cccf7c-pmnx7   nginx:1.24   Running     true
web-app-app-79bdc85c7d-8nqb2   nginx:1.25   Running     true
web-app-app-79bdc85c7d-lrhxb   nginx:1.25   Running     true

$ helm get values web-app
USER-SUPPLIED VALUES:
image:
  repository: nginx
  tag: "1.25"
replicaCount: 2

$ helm history web-app
REVISION	STATUS    	DESCRIPTION
1       	superseded	Install complete
2       	deployed  	Upgrade complete
```

## 4. Upgrade again → 5. Verify

```text
$ helm upgrade web-app 07-install-upgrade/app-chart -f values-v3.yaml
REVISION: 3

$ pods web-app
web-app-app-7f4f854d55-fflx7   nginx:1.26   Running     true
web-app-app-7f4f854d55-fs9zr   nginx:1.26   Running     true
web-app-app-7f4f854d55-hvl86   nginx:1.26   Running     true
(+ the 1.25 pods terminating)

$ kubectl -n s15-helm rollout history deployment/web-app-app      # the Deployment keeps its own, separate history
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>

$ helm history web-app
1	superseded	Install complete
2	superseded	Upgrade complete
3	deployed  	Upgrade complete
```

## 6. Rollback → 7. Verify

```text
$ helm rollback web-app 2
Rollback was a success! Happy Helming!

$ pods web-app
web-app-app-79bdc85c7d-9854r   nginx:1.25   Running     true
web-app-app-79bdc85c7d-pn2ll   nginx:1.25   Running     true
(+ the 1.26 pods terminating)

$ helm get values web-app           # the values of revision 2 are back
image:
  repository: nginx
  tag: "1.25"
replicaCount: 2

$ helm history web-app              # rollback did not delete anything, it added revision 4
REVISION	UPDATED                 	STATUS    	DESCRIPTION
1       	Wed Oct  7 23:14:48 2026	superseded	Install complete
2       	Wed Oct  7 23:14:49 2026	superseded	Upgrade complete
3       	Wed Oct  7 23:14:50 2026	superseded	Upgrade complete
4       	Wed Oct  7 23:14:52 2026	deployed  	Rollback to 2

$ helm get manifest web-app --revision 2 | diff - <(helm get manifest web-app) && echo 'manifest of revision 4 == manifest of revision 2'
manifest of revision 4 == manifest of revision 2
```

## Bonus: `--atomic` – Helm rolls back on its own

```text
$ helm upgrade web-app 07-install-upgrade/app-chart -f values-v2.yaml --set image.tag=doesnotexist --atomic --timeout 45s
Error: UPGRADE FAILED: release web-app failed, and has been rolled back due to rollback-on-failure being set:
resource Deployment/s15-helm/web-app-app not ready. status: InProgress, message: Updated: 1/2
context deadline exceeded

$ helm history web-app
4	superseded	Rollback to 2
5	failed    	Upgrade "web-app" failed: resource Deployment/s15-helm/web-app-app not ready ...
6	deployed  	Rollback to 4

$ pods web-app                      # the two healthy 1.25 pods never stopped serving; the bad pod is being removed
web-app-app-5c66747c-p9zkm     nginx:doesnotexist   Pending   false
web-app-app-79bdc85c7d-9854r   nginx:1.25           Running   true
web-app-app-79bdc85c7d-pn2ll   nginx:1.25           Running   true

$ helm uninstall web-app
release "web-app" uninstalled
```

## What I understood

* Each `install`/`upgrade`/`rollback` is a new revision; `superseded` just means "not the current one". History is append-only, which is what makes rollback safe.
* The rolling update means the service never went down at any step – there were always `READY=true` pods of the previous image while the new ones started.
* Without `--atomic`, a broken upgrade still shows `STATUS: deployed` (Helm only waits for the API server to accept it). With `--atomic`, Helm waits for the Deployment to be ready and reverts itself when the timeout passes – revision 5 `failed`, revision 6 `Rollback to 4`.
