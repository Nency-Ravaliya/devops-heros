# HW Session 15

## Task 1: Helm Commands

Environment: Helm `v4.3.0+gbec5b06`, minikube profile `helm-hw` (Kubernetes v1.37.0, docker driver). All outputs below are real terminal captures. Working directory: `session15-helm/hw-demo`.

## 1. helm create

### helm create

Scaffolds a new chart named `webapp` with a default Chart.yaml, values.yaml and starter templates (deployment, service, ingress, hpa, serviceaccount, tests).

```bash
$ helm create webapp
Creating webapp
```

### Generated chart structure

The directory layout that `helm create` produced.

```bash
$ find webapp
webapp/charts
webapp/templates
webapp/.helmignore
webapp/Chart.yaml
webapp/values.yaml
webapp/templates/tests
webapp/templates/_helpers.tpl
webapp/templates/deployment.yaml
webapp/templates/hpa.yaml
webapp/templates/httproute.yaml
webapp/templates/ingress.yaml
webapp/templates/NOTES.txt
webapp/templates/service.yaml
webapp/templates/serviceaccount.yaml
webapp/templates/tests/test-connection.yaml
```

### helm lint (sanity check)

Validates the chart before installing it.

```bash
$ helm lint ./webapp
==> Linting ./webapp
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

## 2. helm repo and helm search

### helm repo add

Registers a remote chart repository (Bitnami) under a local name.

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" already exists with the same configuration, skipping
```

### helm repo update

Downloads the latest chart index from every configured repo (like `apt update`).

```bash
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
```

### helm repo list

Lists the configured repositories.

```bash
$ helm repo list
NAME   	URL
bitnami	https://charts.bitnami.com/bitnami
```

### helm search repo

Searches the charts of the locally added repos for a keyword.

```bash
$ helm search repo nginx --max-col-width 50
NAME                            	CHART VERSION	APP VERSION	DESCRIPTION
bitnami/nginx                   	25.2.1       	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx-ingress-controller	12.0.7       	1.13.1     	NGINX Ingress Controller is an Ingress controll...
bitnami/nginx-intel             	2.1.15       	0.4.9      	DEPRECATED NGINX Open Source for Intel is a lig...
```

### helm search repo --versions

Shows every available version of a specific chart, not just the latest.

```bash
$ helm search repo bitnami/nginx --versions --max-col-width 50
NAME                            	CHART VERSION	APP VERSION	DESCRIPTION
bitnami/nginx                   	25.2.1       	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx                   	25.2.0       	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx                   	25.1.15      	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx                   	25.1.14      	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx                   	25.1.13      	1.31.6     	NGINX Open Source is a web server that can be a...
... (output trimmed)
```

### helm search hub

Searches Artifact Hub (public registry of all charts) without needing to add a repo first.

```bash
$ helm search hub wordpress --max-col-width 50
URL                                               	CHART VERSION	APP VERSION        	DESCRIPTION
https://artifacthub.io/packages/helm/slybase-wo...	5.5.44       	7.0.1              	Using the official WordPress image. This chart ...
https://artifacthub.io/packages/helm/wordpress-...	1.0.11       	7.1.3              	WordPress is the world's most popular blogging ...
https://artifacthub.io/packages/helm/quench-wor...	0.0.25       	7.1.3              	Hardened WordPress CMS (PHP-FPM + nginx) on a 0...
https://artifacthub.io/packages/helm/wordpress-...	1.0.2        	1.0.0              	A Helm chart for deploying Wordpress+Mariadb st...
... (output trimmed)
```

## 3. helm install

### helm install

Deploys the chart as a release named `my-web`. Helm renders the templates, sends them to the cluster and records revision 1.

```bash
$ helm install my-web ./webapp --wait --timeout 120s
NAME: my-web
LAST DEPLOYED: Fri Oct  9 10:29:23 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=my-web" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

### Verify with kubectl

Confirms Kubernetes created the objects the chart described.

```bash
$ kubectl get deploy,svc,pods -l app.kubernetes.io/instance=my-web
NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-web-webapp   1/1     1            1           2s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/my-web-webapp   ClusterIP   10.107.99.125   <none>        80/TCP    2s

NAME                                 READY   STATUS    RESTARTS   AGE
pod/my-web-webapp-7bd9db9c59-t8kw6   1/1     Running   0          2s
```

## 4. helm list

### helm list

Lists the releases in the current namespace with revision, status, chart and app version.

```bash
$ helm list
NAME  	NAMESPACE	REVISION	UPDATED                              	STATUS  	CHART       	APP VERSION
my-web	default  	1       	2026-10-09 10:29:23.7525237 +0530 IST	deployed	webapp-0.1.0	1.16.0
```

### helm list -A

Lists releases in all namespaces.

```bash
$ helm list -A
NAME  	NAMESPACE	REVISION	UPDATED                              	STATUS  	CHART       	APP VERSION
my-web	default  	1       	2026-10-09 10:29:23.7525237 +0530 IST	deployed	webapp-0.1.0	1.16.0
```

## 5. helm status

### helm status

Shows the current state of a release: revision, deployment time, status, live resources and NOTES.

```bash
$ helm status my-web
NAME: my-web
LAST DEPLOYED: Fri Oct  9 10:29:23 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
RESOURCES:
==> v1/Service
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
my-web-webapp   ClusterIP   10.107.99.125   <none>        80/TCP    2s

==> v1/Deployment
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
my-web-webapp   1/1     1            1           2s

==> v1/Pod(related)
NAME                             READY   STATUS    RESTARTS   AGE
my-web-webapp-7bd9db9c59-t8kw6   1/1     Running   0          2s

==> v1/ServiceAccount
NAME            AGE
my-web-webapp   2s


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=my-web" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

## 6. helm get

### helm get values

Shows only the user-supplied overrides (none yet).

```bash
$ helm get values my-web
USER-SUPPLIED VALUES:
null
```

### helm get values --all

Shows computed values (chart defaults merged with overrides).

```bash
$ helm get values my-web --all
COMPUTED VALUES:
affinity: {}
autoscaling:
  enabled: false
  maxReplicas: 100
  minReplicas: 1
  targetCPUUtilizationPercentage: 80
fullnameOverride: ""
httpRoute:
  annotations: {}
  enabled: false
  hostnames:
  - chart-example.local
  parentRefs:
  - name: gateway
    sectionName: http
  rules:
  - matches:
    - path:
        type: PathPrefix
... (output trimmed)
```

### helm get manifest

Shows the final rendered Kubernetes YAML that was applied to the cluster.

```bash
$ helm get manifest my-web
---
# Source: webapp/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-web-webapp
  labels:
    helm.sh/chart: webapp-0.1.0
    app.kubernetes.io/name: webapp
    app.kubernetes.io/instance: my-web
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
automountServiceAccountToken: true

---
# Source: webapp/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-web-webapp
  labels:
    helm.sh/chart: webapp-0.1.0
    app.kubernetes.io/name: webapp
    app.kubernetes.io/instance: my-web
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: webapp
    app.kubernetes.io/instance: my-web

---
# Source: webapp/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-web-webapp
  labels:
    helm.sh/chart: webapp-0.1.0
... (output trimmed)
```

### helm get notes

Prints the NOTES.txt that was rendered at install time.

```bash
$ helm get notes my-web
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=my-web" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

### helm get hooks

Shows the hook manifests of the release. The only hook here is the `helm test` pod (`"helm.sh/hook": test`) that ships with the starter chart.

```bash
$ helm get hooks my-web
---
# Source: webapp/templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "my-web-webapp-test-connection"
  labels:
    helm.sh/chart: webapp-0.1.0
    app.kubernetes.io/name: webapp
    app.kubernetes.io/instance: my-web
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['my-web-webapp:80']
  restartPolicy: Never
```

### helm get all

Dumps everything: metadata, hooks, manifest, notes and values.

```bash
$ helm get all my-web
NAME: my-web
LAST DEPLOYED: Fri Oct  9 10:29:23 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
CHART: webapp
VERSION: 0.1.0
APP_VERSION: 1.16.0
DESCRIPTION: Install complete
USER-SUPPLIED VALUES:
null

COMPUTED VALUES:
affinity: {}
autoscaling:
  enabled: false
  maxReplicas: 100
  minReplicas: 1
  targetCPUUtilizationPercentage: 80
fullnameOverride: ""
httpRoute:
  annotations: {}
  enabled: false
  hostnames:
  - chart-example.local
... (output trimmed)
```

## 7. helm upgrade

### helm upgrade (scale + new image)

Applies new configuration to the existing release and creates revision 2.

```bash
$ helm upgrade my-web ./webapp --set replicaCount=3 --set image.tag=1.27.0 --wait --timeout 120s
Release "my-web" has been upgraded. Happy Helming!
NAME: my-web
LAST DEPLOYED: Fri Oct  9 10:29:26 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=my-web" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

### Verify the upgrade

3 replicas running with the new image.

```bash
$ kubectl get deploy my-web-webapp -o wide
NAME            READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES         SELECTOR
my-web-webapp   3/3     3            3           7s    webapp       nginx:1.27.0   app.kubernetes.io/instance=my-web,app.kubernetes.io/name=webapp
```

### helm get values after upgrade

Shows the overrides that revision 2 carries.

```bash
$ helm get values my-web
USER-SUPPLIED VALUES:
image:
  tag: 1.27.0
replicaCount: 3
```

## 8. helm history

### helm history

Lists every revision of the release with status and description.

```bash
$ helm history my-web
REVISION	UPDATED                 	STATUS    	CHART       	APP VERSION	DESCRIPTION
1       	Fri Oct  9 10:29:23 2026	superseded	webapp-0.1.0	1.16.0     	Install complete
2       	Fri Oct  9 10:29:26 2026	deployed  	webapp-0.1.0	1.16.0     	Upgrade complete
```

### Simulating a bad release

To demonstrate rollback, a faulty upgrade is pushed with an image tag that does not exist. `--wait` makes Helm wait for readiness, so the release is marked `failed` when it times out.

### helm upgrade with a broken image

Revision 3 is created but the new pods never become ready.

```bash
$ helm upgrade my-web ./webapp --set replicaCount=3 --set image.tag=does-not-exist-999 --wait --timeout 40s
level=WARN msg="upgrade failed" name=my-web error="resource Deployment/default/my-web-webapp not ready. status: InProgress, message: Updated: 1/3\ncontext deadline exceeded"
Error: UPGRADE FAILED: resource Deployment/default/my-web-webapp not ready. status: InProgress, message: Updated: 1/3
context deadline exceeded
```

### kubectl get pods (broken)

New pods are in ErrImagePull/ImagePullBackOff while the old ones from revision 2 keep serving.

```bash
$ kubectl get pods -l app.kubernetes.io/instance=my-web
NAME                             READY   STATUS         RESTARTS   AGE
my-web-webapp-6698f7bb99-nn8s7   1/1     Running        0          45s
my-web-webapp-6698f7bb99-ssmvx   1/1     Running        0          44s
my-web-webapp-6698f7bb99-x4tf8   1/1     Running        0          43s
my-web-webapp-869c5d5bfd-xfg5l   0/1     ErrImagePull   0          41s
```

### helm history (failed revision)

Revision 3 shows `failed`.

```bash
$ helm history my-web
REVISION	UPDATED                 	STATUS    	CHART       	APP VERSION	DESCRIPTION
1       	Fri Oct  9 10:29:23 2026	superseded	webapp-0.1.0	1.16.0     	Install complete
2       	Fri Oct  9 10:29:26 2026	deployed  	webapp-0.1.0	1.16.0     	Upgrade complete
3       	Fri Oct  9 10:29:30 2026	failed    	webapp-0.1.0	1.16.0     	Upgrade "my-web" failed: resource Deployment/default/my-web-webapp not ready. status: InProgress, message: Updated: ...
```

## 9. helm rollback

### helm rollback

Reverts to revision 2 (last good). Helm creates a new revision 4 whose content is identical to revision 2.

```bash
$ helm rollback my-web 2 --wait --timeout 120s
Rollback was a success! Happy Helming!
```

### helm history after rollback

History is never rewritten; the rollback is recorded as revision 4.

```bash
$ helm history my-web
REVISION	UPDATED                 	STATUS    	CHART       	APP VERSION	DESCRIPTION
1       	Fri Oct  9 10:29:23 2026	superseded	webapp-0.1.0	1.16.0     	Install complete
2       	Fri Oct  9 10:29:26 2026	superseded	webapp-0.1.0	1.16.0     	Upgrade complete
3       	Fri Oct  9 10:29:30 2026	failed    	webapp-0.1.0	1.16.0     	Upgrade "my-web" failed: resource Deployment/default/my-web-webapp not ready. status: InProgress, message: Updated: ...
4       	Fri Oct  9 10:30:10 2026	deployed  	webapp-0.1.0	1.16.0     	Rollback to 2
```

### Verify the rollback

Healthy pods, image back to 1.27.0.

```bash
$ kubectl get pods -l app.kubernetes.io/instance=my-web; kubectl get deploy my-web-webapp -o jsonpath='{.spec.template.spec.containers[0].image}'
NAME                             READY   STATUS        RESTARTS   AGE
my-web-webapp-6698f7bb99-nn8s7   1/1     Running       0          46s
my-web-webapp-6698f7bb99-ssmvx   1/1     Running       0          45s
my-web-webapp-6698f7bb99-x4tf8   1/1     Running       0          44s
my-web-webapp-869c5d5bfd-xfg5l   0/1     Terminating   0          42s
nginx:1.27.0
```

## 10. helm uninstall

### helm uninstall --keep-history

Deletes all Kubernetes resources of the release. `--keep-history` retains the revision records so the release can still be inspected.

```bash
$ helm uninstall my-web --keep-history
release "my-web" uninstalled
```

### helm list --uninstalled

Shows the uninstalled release kept in history.

```bash
$ helm list --uninstalled
NAME  	NAMESPACE	REVISION	UPDATED                              	STATUS     	CHART       	APP VERSION
my-web	default  	4       	2026-10-09 10:30:10.6142261 +0530 IST	uninstalled	webapp-0.1.0	1.16.0
```

### helm history after uninstall

The last revision is marked `uninstalled`.

```bash
$ helm history my-web
REVISION	UPDATED                 	STATUS     	CHART       	APP VERSION	DESCRIPTION
1       	Fri Oct  9 10:29:23 2026	superseded 	webapp-0.1.0	1.16.0     	Install complete
2       	Fri Oct  9 10:29:26 2026	superseded 	webapp-0.1.0	1.16.0     	Upgrade complete
3       	Fri Oct  9 10:29:30 2026	failed     	webapp-0.1.0	1.16.0     	Upgrade "my-web" failed: resource Deployment/default/my-web-webapp not ready. status: InProgress, message: Updated: ...
4       	Fri Oct  9 10:30:10 2026	uninstalled	webapp-0.1.0	1.16.0     	Uninstallation complete
```

### Full removal

Uninstalling a second release (`temp-web`) without `--keep-history` removes its records too. Only the earlier `my-web` (kept on purpose) remains in `helm list`.

```bash
$ helm install temp-web ./webapp --wait
NAME: temp-web
LAST DEPLOYED: Fri Oct  9 10:30:25 2026
NAMESPACE: default
...

$ helm uninstall temp-web
release "temp-web" uninstalled

$ helm list
NAME  	NAMESPACE	REVISION	UPDATED                              	STATUS     	CHART       	APP VERSION
my-web	default  	4       	2026-10-09 10:30:10.6142261 +0530 IST	uninstalled	webapp-0.1.0	1.16.0

$ helm history temp-web
Error: release: not found

$ kubectl get deploy,svc
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5m36s
```

## Summary

| Command | Purpose |
|---|---|
| `helm create` | Scaffold a new chart |
| `helm install` | Deploy a chart as a release (revision 1) |
| `helm list` | List releases |
| `helm status` | Show release state and resources |
| `helm get values/manifest/notes/hooks/all` | Inspect what was deployed |
| `helm upgrade` | Apply new values or chart, creates a new revision |
| `helm history` | List revisions of a release |
| `helm rollback` | Revert to a previous revision (creates a new one) |
| `helm uninstall` | Remove a release (optionally keep history) |
| `helm repo add/update/list` | Manage chart repositories |
| `helm search repo/hub` | Find charts locally or on Artifact Hub |
