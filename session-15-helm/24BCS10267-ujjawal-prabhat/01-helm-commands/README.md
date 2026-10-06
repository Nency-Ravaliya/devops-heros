# Task 1 - Helm commands (run and explained)

**Ujjawal Prabhat - 24BCS10267 - Session 15 (Helm)**

Helm is the package manager for Kubernetes. A **chart** is a package: templates plus default values. A **release** is one installed copy of a chart in a namespace. Every install, upgrade or rollback creates a new numbered **revision**. Helm stores each revision as a Secret in the release's namespace, and that history is what makes `history` and `rollback` work.

All commands ran against the kind cluster in namespace `s15`. The chart `hello-helm` was made with `helm create` in a scratch directory. It is the standard generated chart, so I did not commit it. My own chart is in `03-mini-project/notes-chart`.

---

## 1. `helm create` - scaffold a new chart

```console
$ kubectl create namespace s15
namespace/s15 created

$ helm create hello-helm
Creating hello-helm

$ find hello-helm -type f | sort
hello-helm/.helmignore
hello-helm/Chart.yaml
hello-helm/templates/NOTES.txt
hello-helm/templates/_helpers.tpl
hello-helm/templates/deployment.yaml
hello-helm/templates/hpa.yaml
hello-helm/templates/httproute.yaml
hello-helm/templates/ingress.yaml
hello-helm/templates/service.yaml
hello-helm/templates/serviceaccount.yaml
hello-helm/templates/tests/test-connection.yaml
hello-helm/values.yaml

$ grep -E '^(name|version|appVersion)' hello-helm/Chart.yaml
name: hello-helm
version: 0.1.0
appVersion: "1.16.0"

$ sed -n '1,12p' hello-helm/values.yaml
# Default values for hello-helm.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

# This will set the replicaset count more information can be found here: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
replicaCount: 1

# This sets the container image more information can be found here: https://kubernetes.io/docs/concepts/containers/images/
image:
  repository: nginx
  # This sets the pull policy for images.
  pullPolicy: IfNotPresent
```

`helm create` writes a working chart skeleton:
- `Chart.yaml` holds the chart metadata. `version` is the chart's own version and `appVersion` is the version of the app it packages.
- `values.yaml` holds the default values.
- `templates/` holds Go-templated manifests.
- `_helpers.tpl` holds reusable named templates such as names and labels.
- `NOTES.txt` is the text printed after an install.
- `tests/` holds the `helm test` hooks.

## 2. `helm lint` - static checks on a chart

```console
$ helm lint hello-helm
==> Linting hello-helm
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

`[INFO]` lines are only suggestions. An `[ERROR]` would fail the lint.

## 3. `helm install` - create a release

```console
$ helm install hello hello-helm -n s15 --wait --timeout 3m
NAME: hello
LAST DEPLOYED: Tue Oct  6 19:28:47 2026
NAMESPACE: s15
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace s15 -l "app.kubernetes.io/name=hello-helm,app.kubernetes.io/instance=hello" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace s15 $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace s15 port-forward $POD_NAME 8080:$CONTAINER_PORT
```

The syntax is `helm install <release-name> <chart>`. `--wait` blocks until the Deployment's pods are ready, and `--timeout` limits how long it waits. The NOTES come from `templates/NOTES.txt`.

## 4. `helm list` - list releases

```console
$ helm list -n s15
NAME 	NAMESPACE	REVISION	UPDATED                              	STATUS  	CHART           	APP VERSION
hello	s15      	1       	2026-10-06 19:28:47.730818 +0800 WITA	deployed	hello-helm-0.1.0	1.16.0     

$ helm list -A
NAME      	NAMESPACE 	REVISION	UPDATED                              	STATUS  	CHART                       	APP VERSION
hello     	s15       	1       	2026-10-06 19:28:47.730818 +0800 WITA	deployed	hello-helm-0.1.0            	1.16.0     
kps       	monitoring	1       	2026-10-06 18:55:34.240507 +0800 WITA	deployed	kube-prometheus-stack-91.9.0	v0.94.1    
stockpilot	final     	2       	2026-10-06 19:10:28.949838 +0800 WITA	deployed	stockpilot-0.1.0            	1.0.1      
```

`-n` picks one namespace and `-A` covers all namespaces. The other two releases belong to other work on the shared cluster. I did not touch them.

## 5. `helm status` - state of one release

```console
$ helm status hello -n s15
NAME: hello
LAST DEPLOYED: Tue Oct  6 19:28:47 2026
NAMESPACE: s15
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
RESOURCES:
==> v1/ServiceAccount
NAME               AGE
hello-hello-helm   20s

==> v1/Service
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
hello-hello-helm   ClusterIP   10.96.104.46   <none>        80/TCP    20s

==> v1/Deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
hello-hello-helm   1/1     1            1           20s

==> v1/Pod(related)
NAME                                READY   STATUS    RESTARTS   AGE
hello-hello-helm-7d4c4c6cb4-b86pd   1/1     Running   0          20s


NOTES:
...
```

`helm status` shows the current revision, its status, and a live view of every Kubernetes object the release owns.

## 6. `helm get` - read what is stored for a release

```console
$ helm get values hello -n s15
USER-SUPPLIED VALUES:
null

$ helm get values hello -n s15 --all | head -15
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

$ helm get manifest hello -n s15 | head -40
---
# Source: hello-helm/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: hello-hello-helm
  labels:
    helm.sh/chart: hello-helm-0.1.0
    app.kubernetes.io/name: hello-helm
    app.kubernetes.io/instance: hello
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
automountServiceAccountToken: true

---
# Source: hello-helm/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-hello-helm
  labels:
    helm.sh/chart: hello-helm-0.1.0
    app.kubernetes.io/name: hello-helm
    app.kubernetes.io/instance: hello
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
    app.kubernetes.io/name: hello-helm
    app.kubernetes.io/instance: hello

---
# Source: hello-helm/templates/deployment.yaml
apiVersion: apps/v1
...

$ helm get notes hello -n s15
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace s15 -l "app.kubernetes.io/name=hello-helm,app.kubernetes.io/instance=hello" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace s15 $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace s15 port-forward $POD_NAME 8080:$CONTAINER_PORT
```

`helm get all` prints everything in one go. Below are just its section headers with line numbers, to show the structure:

```console
$ helm get all hello -n s15 | grep -nE '^(NAME|LAST DEPLOYED|NAMESPACE|STATUS|REVISION|CHART|VERSION|APP_VERSION|USER-SUPPLIED VALUES|COMPUTED VALUES|HOOKS|MANIFEST|NOTES)'
1:NAME: hello
2:LAST DEPLOYED: Tue Oct  6 19:28:47 2026
3:NAMESPACE: s15
4:STATUS: deployed
5:REVISION: 1
6:CHART: hello-helm
7:VERSION: 0.1.0
8:APP_VERSION: 1.16.0
10:USER-SUPPLIED VALUES:
13:COMPUTED VALUES:
77:HOOKS:
100:MANIFEST:
184:NOTES:

$ helm get metadata hello -n s15
NAME: hello
CHART: hello-helm
VERSION: 0.1.0
APP_VERSION: 1.16.0
ANNOTATIONS: 
LABELS: modifiedAt=1791286147,name=hello,owner=helm,status=deployed,version=1
DEPENDENCIES: 
NAMESPACE: s15
REVISION: 1
STATUS: deployed
DEPLOYED_AT: 2026-10-06T19:28:47+08:00
APPLY_METHOD: server-side apply
```

| Command | Shows |
|---|---|
| `get values` | Only the values the user passed (`-f` / `--set`). Here that was nothing, so `null`. Add `--all` to see the computed values with the defaults merged in. |
| `get manifest` | The exact rendered YAML that Helm sent to Kubernetes for this revision |
| `get notes` | The rendered NOTES.txt |
| `get hooks` | Hook resources, such as the `helm test` pod |
| `get all` | Everything above, in one output |
| `get metadata` | Chart name and version, revision, status, and deploy time |

All of them accept `--revision N` to read an older revision (used in Task 2).

## 7. `helm upgrade` - roll out a new revision

```console
$ helm upgrade hello hello-helm -n s15 --set replicaCount=2 --wait
Release "hello" has been upgraded. Happy Helming!
NAME: hello
LAST DEPLOYED: Tue Oct  6 19:29:08 2026
NAMESPACE: s15
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
NOTES:
...

$ kubectl get deploy,pods -n s15
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-hello-helm   2/2     2            2           41s

NAME                                    READY   STATUS    RESTARTS   AGE
pod/hello-hello-helm-7d4c4c6cb4-9p5fc   1/1     Running   0          20s
pod/hello-hello-helm-7d4c4c6cb4-b86pd   1/1     Running   0          41s

$ helm get values hello -n s15
USER-SUPPLIED VALUES:
replicaCount: 2
```

`helm upgrade` renders the chart again with the new values, applies the difference, and records it as revision 2. The flag `--install` (as in `helm upgrade --install`) installs the release if it does not exist yet, which is common in CI.

## 8. `helm history` - list revisions

```console
$ helm history hello -n s15
REVISION	UPDATED                 	STATUS    	CHART           	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 19:28:47 2026	superseded	hello-helm-0.1.0	1.16.0     	Install complete
2       	Tue Oct  6 19:29:08 2026	deployed  	hello-helm-0.1.0	1.16.0     	Upgrade complete
```

Only one revision is `deployed` at a time. Older revisions become `superseded`.

## 9. `helm rollback` - go back to an earlier revision

```console
$ helm rollback hello 1 -n s15 --wait
Rollback was a success! Happy Helming!

$ helm history hello -n s15
REVISION	UPDATED                 	STATUS    	CHART           	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 19:28:47 2026	superseded	hello-helm-0.1.0	1.16.0     	Install complete
2       	Tue Oct  6 19:29:08 2026	superseded	hello-helm-0.1.0	1.16.0     	Upgrade complete
3       	Tue Oct  6 19:29:28 2026	deployed  	hello-helm-0.1.0	1.16.0     	Rollback to 1   

$ kubectl get deploy -n s15
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
hello-hello-helm   1/1     1            1           41s
```

A rollback does not delete history. It creates a **new** revision (3) that holds revision 1's manifest, so the Deployment returns to 1 replica.

## 10. `helm repo` - chart repositories

```console
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories

$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
"prometheus-community" already exists with the same configuration, skipping

$ helm repo list
NAME                	URL                                               
prometheus-community	https://prometheus-community.github.io/helm-charts
bitnami             	https://charts.bitnami.com/bitnami                

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "prometheus-community" chart repository
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
```

- `repo add` saves a name and URL in the local Helm config.
- `repo list` shows the configured repos. `prometheus-community` was already configured on this machine.
- `repo update` downloads each repo's latest `index.yaml`, the local catalog that `search repo` reads.
- `repo remove <name>` deletes a repo. I removed `bitnami` again at cleanup.

## 11. `helm search` - find charts

```console
$ helm search repo bitnami/nginx
NAME                            	CHART VERSION	APP VERSION	DESCRIPTION                                       
bitnami/nginx                   	25.2.1       	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx-ingress-controller	12.0.7       	1.13.1     	NGINX Ingress Controller is an Ingress controll...
bitnami/nginx-intel             	2.1.15       	0.4.9      	DEPRECATED NGINX Open Source for Intel is a lig...

$ helm search repo nginx --versions | head -6
NAME                                          	CHART VERSION	APP VERSION	DESCRIPTION                                       
bitnami/nginx                                 	25.2.1       	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx                                 	25.2.0       	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx                                 	25.1.15      	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx                                 	25.1.14      	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx                                 	25.1.13      	1.31.6     	NGINX Open Source is a web server that can be a...

$ helm search repo prometheus-community/prometheus | head -6
NAME                                              	CHART VERSION	APP VERSION	DESCRIPTION                                       
prometheus-community/prometheus                   	29.35.0      	v3.15.0    	Prometheus is a monitoring system and time seri...
prometheus-community/prometheus-adapter           	5.3.0        	v0.12.0    	A Helm chart for k8s prometheus adapter           
prometheus-community/prometheus-blackbox-exporter 	11.19.1      	v0.28.0    	Prometheus Blackbox Exporter                      
prometheus-community/prometheus-cloudwatch-expo...	0.28.2       	0.16.0     	A Helm chart for prometheus cloudwatch-exporter   
prometheus-community/prometheus-conntrack-stats...	0.5.40       	v0.4.48    	A Helm chart for conntrack-stats-exporter         

$ helm search hub nginx --max-col-width 60 | head -8
URL                                                         	CHART VERSION  	APP VERSION                                     	DESCRIPTION                                                 
https://artifacthub.io/packages/helm/cloudpirates-nginx/n...	0.16.12        	1.31.6                                          	Nginx is a high-performance HTTP server and reverse proxy.  
https://artifacthub.io/packages/helm/quench-nginx/nginx     	0.0.15         	1.30.5                                          	High-performance web server, reverse proxy, and load bala...
https://artifacthub.io/packages/helm/krakazyabra/nginx      	1.0.0          	1.19.0                                          	Nginx Helm chart for Kubernetes                             
https://artifacthub.io/packages/helm/dhinesh/nginx          	25.2.1         	1.31.6                                          	NGINX Open Source is a web server that can be also used a...
https://artifacthub.io/packages/helm/bitnami/nginx          	25.2.1         	1.31.6                                          	NGINX Open Source is a web server that can be also used a...
https://artifacthub.io/packages/helm/niceos/nginx           	1.31.1+niceos.2	1.31.1                                          	Bitnami-compatible NGINX Helm chart for NiceOS              
https://artifacthub.io/packages/helm/bitnami-aks/nginx      	13.2.12        	1.23.2                                          	NGINX Open Source is a web server that can be also used a...

$ helm show chart bitnami/nginx | head -15
annotations:
  fips: "true"
  images: |
    - name: git
      version: 2.56.0
      image: registry-1.docker.io/bitnami/git:latest
    - name: nginx
      version: 1.31.6
      image: registry-1.docker.io/bitnami/nginx:latest
    - name: nginx-exporter
      version: 1.5.3
      image: registry-1.docker.io/bitnami/nginx-exporter:latest
  licenses: Apache-2.0
  tanzuCategory: clusterUtility
apiVersion: v2
```

- `search repo` searches only the repos you have added, offline, using the cached index. `--versions` lists every chart version, not just the latest.
- `search hub` queries Artifact Hub (artifacthub.io) online, which covers charts from every public repo.
- `show chart|values|readme|all <chart>` inspects a chart before you install it.

## 12. `helm uninstall` - remove a release

First run, on the release from steps 3-9:

```console
$ helm uninstall hello -n s15 --keep-history
release "hello" uninstalled

$ helm history hello -n s15
REVISION	UPDATED                 	STATUS     	CHART           	APP VERSION	DESCRIPTION            
1       	Tue Oct  6 19:28:47 2026	superseded 	hello-helm-0.1.0	1.16.0     	Install complete       
2       	Tue Oct  6 19:29:08 2026	superseded 	hello-helm-0.1.0	1.16.0     	Upgrade complete       
3       	Tue Oct  6 19:29:28 2026	uninstalled	hello-helm-0.1.0	1.16.0     	Uninstallation complete

$ helm uninstall hello -n s15
release "hello" uninstalled
```

During that first run I also tried `helm list -n s15 --all`. Helm v4 rejected it (`Error: unknown flag: --all`), because Helm v4 lists all states by default and uses status filters instead. So I ran the keep-history flow again on a fresh install:

```console
$ helm install hello hello-helm -n s15 --wait | head -6
NAME: hello
LAST DEPLOYED: Tue Oct  6 19:30:15 2026
NAMESPACE: s15
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete

$ helm uninstall hello -n s15 --keep-history
release "hello" uninstalled

$ helm list -n s15
NAME 	NAMESPACE	REVISION	UPDATED                              	STATUS     	CHART           	APP VERSION
hello	s15      	1       	2026-10-06 19:30:15.281834 +0800 WITA	uninstalled	hello-helm-0.1.0	1.16.0     

$ helm list -n s15 --uninstalled
NAME 	NAMESPACE	REVISION	UPDATED                              	STATUS     	CHART           	APP VERSION
hello	s15      	1       	2026-10-06 19:30:15.281834 +0800 WITA	uninstalled	hello-helm-0.1.0	1.16.0     

$ helm history hello -n s15
REVISION	UPDATED                 	STATUS     	CHART           	APP VERSION	DESCRIPTION            
1       	Tue Oct  6 19:30:15 2026	uninstalled	hello-helm-0.1.0	1.16.0     	Uninstallation complete

$ helm uninstall hello -n s15
release "hello" uninstalled

$ helm list -n s15 --uninstalled
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION

$ helm history hello -n s15
Error: release: not found

$ kubectl get all -n s15
No resources found in s15 namespace.
```

`helm uninstall` deletes every Kubernetes object in the release. With `--keep-history`, Helm keeps the revision records with status `uninstalled`, so you can still inspect the release or roll it back. A plain `uninstall` removes the history too, so `helm history` returns `release: not found`.

## Summary

| Command | Purpose |
|---|---|
| `helm create <name>` | Scaffold a new chart |
| `helm lint <chart>` | Check a chart for errors and best practices |
| `helm template <rel> <chart>` | Render manifests locally without installing (used in Task 3) |
| `helm install <rel> <chart>` | Create a release, revision 1 |
| `helm list [-n ns / -A]` | List releases |
| `helm status <rel>` | Show a release's status and the objects it owns |
| `helm get values/manifest/notes/hooks/all/metadata <rel>` | Show what is stored for a revision |
| `helm upgrade <rel> <chart>` | Roll out new values or a new chart version as a new revision |
| `helm history <rel>` | List all revisions |
| `helm rollback <rel> <rev>` | Create a new revision that copies an older one |
| `helm uninstall <rel> [--keep-history]` | Delete the release |
| `helm repo add/list/update/remove` | Manage chart repositories |
| `helm search repo/hub <kw>` | Search the added repos or Artifact Hub |
| `helm show chart/values <chart>` | Inspect a chart before installing it |
