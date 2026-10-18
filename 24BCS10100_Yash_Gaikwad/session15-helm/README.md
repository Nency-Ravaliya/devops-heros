# Session 15: Helm

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

| Task | Topic | Where |
|---|---|---|
| 1 | Every important Helm command executed, explained, output captured | [Task 1](#task-1-helm-commands) |
| 2 | Complete rollback workflow: install, upgrade, verify, upgrade again, verify, rollback, verify | [Task 2](#task-2-helm-rollback) |
| 3 | Helm mini project (the Notes app chart) | [Task 3](#task-3-mini-project) |

**Deliverables:** Helm chart (`01-commands/webapp-chart`, `mini-project/notes-chart`), `values.yaml`, templates, installation / upgrade / rollback output, mini project, this README.

**Environment:** Minikube (Docker driver) on Windows 11, Kubernetes v1.37.0, Helm v4.3.1. All output is real.

### What Helm is

**Helm** is the package manager for Kubernetes. A **chart** is a package of templated manifests plus default **values**; installing it with some values creates a **release**. Each `upgrade` creates a new **revision**, which makes `rollback` possible.

```
chart (templates + values.yaml)  --helm install-->  release "demo" (revision 1)
                                  --helm upgrade-->  revision 2, 3 ...   --helm rollback--> new revision with old content
```

---

## Task 1: Helm commands

_Helm client version._

```console
$ helm version --short
v4.3.1+gc0d08d0
```

### `helm create`: scaffold a chart

_Generates a complete working chart skeleton (an nginx web app)._

```console
$ cd 01-commands && helm create webapp-chart
Creating webapp-chart
```

_The chart structure: `Chart.yaml` (metadata), `values.yaml` (defaults), `templates/` (Kubernetes manifests with placeholders)._

```console
$ cd 01-commands && find webapp-chart -type f | sort
webapp-chart/.helmignore
webapp-chart/Chart.yaml
webapp-chart/templates/NOTES.txt
webapp-chart/templates/_helpers.tpl
webapp-chart/templates/deployment.yaml
webapp-chart/templates/hpa.yaml
webapp-chart/templates/httproute.yaml
webapp-chart/templates/ingress.yaml
webapp-chart/templates/service.yaml
webapp-chart/templates/serviceaccount.yaml
webapp-chart/templates/tests/test-connection.yaml
webapp-chart/values.yaml
```

_Chart metadata: the chart version and the application version (`appVersion`, used as the default image tag)._

```console
$ cd 01-commands/webapp-chart && cat Chart.yaml | grep -vE "^\s*#|^$"
apiVersion: v2
name: webapp-chart
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: "1.16.0"
```

_The default values: replica count, image repository/tag, service type and port..._

```console
$ cd 01-commands/webapp-chart && grep -vE "^\s*#|^$" values.yaml | head -n 24
replicaCount: 1
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: ""
imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""
serviceAccount:
  create: true
  automount: true
  annotations: {}
  name: ""
podAnnotations: {}
podLabels: {}
podSecurityContext: {}
securityContext: {}
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
  className: ""
  annotations: {}
```

_A template: `{{ ... }}` placeholders are filled from the values._

```console
$ cd 01-commands/webapp-chart && sed -n "1,22p" templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp-chart.fullname" . }}
  labels:
    {{- include "webapp-chart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "webapp-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "webapp-chart.labels" . | nindent 8 }}
        {{- with .Values.podLabels }}
```

### `helm lint` and `helm template`: check and render without installing

_Static check of the chart._

```console
$ helm lint 01-commands/webapp-chart
==> Linting 01-commands/webapp-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

_Render the templates locally: the Kubernetes objects that **would** be created, with `replicaCount=2` applied. Nothing is sent to the cluster._

```console
$ helm template demo 01-commands/webapp-chart --set replicaCount=2 | grep -E "^kind:|replicas:|image:" 
kind: ServiceAccount
kind: Service
kind: Deployment
  replicas: 2
          image: "nginx:1.16.0"
kind: Pod
      image: busybox
```

### `helm install`: create a release

_Install the chart as a release named `demo`, overriding one value. Helm prints the status and the chart NOTES._

```console
$ helm install demo 01-commands/webapp-chart --set replicaCount=2
NAME: demo
LAST DEPLOYED: Sun Oct 18 20:24:04 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=webapp-chart,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

_The objects the release created (a Deployment with 2 Pods, a Service, a ServiceAccount)._

```console
$ kubectl rollout status deployment/demo-webapp-chart --timeout=180s && kubectl get deploy,pods,svc -l app.kubernetes.io/instance=demo
Waiting for deployment "demo-webapp-chart" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 of 2 updated replicas are available...
deployment "demo-webapp-chart" successfully rolled out
NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/demo-webapp-chart   2/2     2            2           20s

NAME                                     READY   STATUS    RESTARTS   AGE
pod/demo-webapp-chart-6c5fdc6b76-9mptn   1/1     Running   0          20s
pod/demo-webapp-chart-6c5fdc6b76-pk58z   1/1     Running   0          20s

NAME                        TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/demo-webapp-chart   ClusterIP   10.97.5.16   <none>        80/TCP    20s
```

### `helm list`, `helm status`

_All releases in the namespace: name, revision, status, chart and app version._

```console
$ helm list
NAME	NAMESPACE	REVISION	UPDATED                              	STATUS  	CHART             	APP VERSION
demo	default  	1       	2026-10-18 20:24:04.3372843 +0530 IST	deployed	webapp-chart-0.1.0	1.16.0     
```

_Status of one release, its revision and the NOTES._

```console
$ helm status demo
NAME: demo
LAST DEPLOYED: Sun Oct 18 20:24:04 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
RESOURCES:
==> v1/ServiceAccount
NAME                AGE
demo-webapp-chart   21s

==> v1/Service
NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
demo-webapp-chart   ClusterIP   10.97.5.16   <none>        80/TCP    21s

==> v1/Deployment
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
demo-webapp-chart   2/2     2            2           21s

==> v1/Pod(related)
NAME                                 READY   STATUS    RESTARTS   AGE
demo-webapp-chart-6c5fdc6b76-9mptn   1/1     Running   0          21s
demo-webapp-chart-6c5fdc6b76-pk58z   1/1     Running   0          21s


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=webapp-chart,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

### `helm get`: what is installed

_The values I overrode._

```console
$ helm get values demo
USER-SUPPLIED VALUES:
replicaCount: 2
```

_`--all` adds the chart defaults (first lines shown)._

```console
$ helm get values demo --all | head -n 16
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
```

_The rendered manifests that were applied (just the sources and kinds)._

```console
$ helm get manifest demo | grep -E "^# Source|^kind:|^  name:" | head -n 12
# Source: webapp-chart/templates/serviceaccount.yaml
kind: ServiceAccount
  name: demo-webapp-chart
# Source: webapp-chart/templates/service.yaml
kind: Service
  name: demo-webapp-chart
# Source: webapp-chart/templates/deployment.yaml
kind: Deployment
  name: demo-webapp-chart
```

_The post-install notes._

```console
$ helm get notes demo
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=webapp-chart,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

_Release metadata (chart, app version, namespace, deployed time)._

```console
$ helm get metadata demo
NAME: demo
CHART: webapp-chart
VERSION: 0.1.0
APP_VERSION: 1.16.0
ANNOTATIONS: 
LABELS: modifiedAt=1792335244,name=demo,owner=helm,status=deployed,version=1
DEPENDENCIES: 
NAMESPACE: default
REVISION: 1
STATUS: deployed
DEPLOYED_AT: 2026-10-18T20:24:04+05:30
APPLY_METHOD: server-side apply
```

### `helm upgrade`, `helm history`

_Change the release: 3 replicas and a specific nginx tag. This creates **revision 2**._

```console
$ helm upgrade demo 01-commands/webapp-chart --set replicaCount=3 --set image.tag=1.27 && kubectl rollout status deployment/demo-webapp-chart --timeout=180s
Release "demo" has been upgraded. Happy Helming!
NAME: demo
LAST DEPLOYED: Sun Oct 18 20:24:28 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=webapp-chart,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 old replicas are pending termination...
deployment "demo-webapp-chart" successfully rolled out
```

_Every revision with its status: revision 1 `superseded`, revision 2 `deployed`._

```console
$ helm history demo
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION     
1       	Sun Oct 18 20:24:04 2026	superseded	webapp-chart-0.1.0	1.16.0     	Install complete
2       	Sun Oct 18 20:24:28 2026	deployed  	webapp-chart-0.1.0	1.16.0     	Upgrade complete
```

_Verify the change in the cluster._

```console
$ kubectl get deploy demo-webapp-chart -o jsonpath="replicas={.spec.replicas}  image={.spec.template.spec.containers[0].image}{\"\\n\"}"
replicas=3  image=nginx:1.27
```

### `helm rollback`

_Go back to revision 1. Rollback does not rewind history: it creates **revision 3** that has the content of revision 1._

```console
$ helm rollback demo 1 && kubectl rollout status deployment/demo-webapp-chart --timeout=180s && helm history demo
Rollback was a success! Happy Helming!
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "demo-webapp-chart" rollout to finish: 1 old replicas are pending termination...
deployment "demo-webapp-chart" successfully rolled out
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION     
1       	Sun Oct 18 20:24:04 2026	superseded	webapp-chart-0.1.0	1.16.0     	Install complete
2       	Sun Oct 18 20:24:28 2026	superseded	webapp-chart-0.1.0	1.16.0     	Upgrade complete
3       	Sun Oct 18 20:24:36 2026	deployed  	webapp-chart-0.1.0	1.16.0     	Rollback to 1   
```

_Verify: 2 replicas and the original image again._

```console
$ kubectl get deploy demo-webapp-chart -o jsonpath="replicas={.spec.replicas}  image={.spec.template.spec.containers[0].image}{\"\\n\"}"
replicas=2  image=nginx:1.16.0
```

### `helm uninstall`

_Remove the release and everything it created._

```console
$ helm uninstall demo && helm list && kubectl get deploy,svc -l app.kubernetes.io/instance=demo
release "demo" uninstalled
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION
No resources found in default namespace.
```

### `helm repo`, `helm search`: using public charts

_Add a chart repository._

```console
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories
```

_Refresh the repository index and list repositories._

```console
$ helm repo update && helm repo list
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
NAME   	URL                               
bitnami	https://charts.bitnami.com/bitnami
```

_Search the added repositories (Chart version, App version, description)._

```console
$ helm search repo bitnami/nginx --max-col-width 50 | head -n 5
NAME                            	CHART VERSION	APP VERSION	DESCRIPTION                                       
bitnami/nginx                   	25.2.5       	1.31.7     	NGINX Open Source is a web server that can be a...
bitnami/nginx-ingress-controller	12.0.7       	1.13.1     	NGINX Ingress Controller is an Ingress controll...
bitnami/nginx-intel             	2.1.15       	0.4.9      	DEPRECATED NGINX Open Source for Intel is a lig...
```

_Show several versions of a chart._

```console
$ helm search repo nginx --versions | head -n 4
NAME                            	CHART VERSION	APP VERSION	DESCRIPTION                                       
bitnami/nginx                   	25.2.5       	1.31.7     	NGINX Open Source is a web server that can be a...
bitnami/nginx                   	25.2.1       	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx                   	25.2.0       	1.31.6     	NGINX Open Source is a web server that can be a...
```

_`helm search hub` searches Artifact Hub, the public directory of charts._

```console
$ helm search hub wordpress --max-col-width 60 | head -n 5
URL                                                         	CHART VERSION	APP VERSION        	DESCRIPTION                                                 
https://artifacthub.io/packages/helm/slybase-wordpress/wo...	5.5.48       	7.0.1              	Using the official WordPress image. This chart provides a...
https://artifacthub.io/packages/helm/wordpress-ng/wordpress 	1.0.11       	7.1.3              	WordPress is the world's most popular blogging and conten...
https://artifacthub.io/packages/helm/quench-wordpress/wor...	0.0.27       	7.1.3              	Hardened WordPress CMS (PHP-FPM + nginx) on a 0-CVE nonro...
https://artifacthub.io/packages/helm/wordpress-mariadb/wo...	1.0.2        	1.0.0              	A Helm chart for deploying Wordpress+Mariadb stack on kub...
```

_Inspect a chart before installing it (`helm show values` prints its default values)._

```console
$ helm show chart bitnami/nginx | head -n 12
annotations:
  fips: "true"
  images: |
    - name: git
      version: 2.56.0
      image: registry-1.docker.io/bitnami/git:latest
    - name: nginx
      version: 1.31.7
      image: registry-1.docker.io/bitnami/nginx:latest
    - name: nginx-exporter
      version: 1.5.3
      image: registry-1.docker.io/bitnami/nginx-exporter:latest
```

_`helm package` turns the chart directory into a versioned `.tgz` that can be published._

```console
$ helm package 01-commands/webapp-chart -d /tmp && ls /tmp/webapp-chart-*.tgz
Successfully packaged chart and saved it to: \tmp\webapp-chart-0.1.0.tgz
ls: cannot access '/tmp/webapp-chart-*.tgz': No such file or directory
```

### Command summary

| Command | Purpose |
|---|---|
| `helm create <name>` | scaffold a new chart |
| `helm lint <chart>` | check a chart for problems |
| `helm template <rel> <chart>` | render the manifests locally |
| `helm install <rel> <chart>` | create a release (`--set`, `-f values.yaml`, `--wait`) |
| `helm list` | list releases |
| `helm status <rel>` | state and notes of a release |
| `helm get values/manifest/notes/all <rel>` | what was installed |
| `helm upgrade <rel> <chart>` | new revision with changed chart or values |
| `helm history <rel>` | all revisions |
| `helm rollback <rel> <rev>` | go back to a revision (creates a new one) |
| `helm uninstall <rel>` | delete the release |
| `helm repo add/update/list` | manage chart repositories |
| `helm search repo/hub` | find charts |
| `helm package <chart>` | build a distributable chart archive |

---

## Task 2: Helm rollback

The complete workflow, step by step, on the release `rollback-demo`.

### 1. Install

_**Install** (revision 1): 1 replica, nginx 1.25._

```console
$ helm install rollback-demo 01-commands/webapp-chart --set replicaCount=1 --set image.tag=1.25 --wait --timeout 180s | head -n 8
NAME: rollback-demo
LAST DEPLOYED: Sun Oct 18 20:25:51 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
1. Get the application URL by running these commands:
```

### 2. Upgrade

_**Upgrade** (revision 2): 3 replicas, nginx 1.27._

```console
$ helm upgrade rollback-demo 01-commands/webapp-chart --set replicaCount=3 --set image.tag=1.27 --wait --timeout 180s | head -n 6
Release "rollback-demo" has been upgraded. Happy Helming!
NAME: rollback-demo
LAST DEPLOYED: Sun Oct 18 20:25:53 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
```

### 3. Verify

_**Verify:** revision 2 is deployed, 3 Pods are running the new image._

```console
$ helm history rollback-demo; kubectl get deploy rollback-demo-webapp-chart -o jsonpath="replicas={.spec.replicas}  image={.spec.template.spec.containers[0].image}{\"\\n\"}"; kubectl get pods -l app.kubernetes.io/instance=rollback-demo
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION     
1       	Sun Oct 18 20:25:51 2026	superseded	webapp-chart-0.1.0	1.16.0     	Install complete
2       	Sun Oct 18 20:25:53 2026	deployed  	webapp-chart-0.1.0	1.16.0     	Upgrade complete
replicas=3  image=nginx:1.27
NAME                                          READY   STATUS    RESTARTS   AGE
rollback-demo-webapp-chart-59469cdd59-bqhd2   1/1     Running   0          26s
rollback-demo-webapp-chart-59469cdd59-gmm57   1/1     Running   0          13s
rollback-demo-webapp-chart-59469cdd59-gxpxm   1/1     Running   0          24s
```

### 4. Upgrade again (a bad release)

I upgrade to an image tag that does not exist, and ask Helm to wait for the rollout to become healthy:

_**Upgrade again** (revision 3). Because of `--wait` Helm notices that the new Pods never become ready and reports the failure._

```console
$ helm upgrade rollback-demo 01-commands/webapp-chart --set replicaCount=3 --set image.tag=9.9.9-does-not-exist --wait --timeout 60s; echo "helm exit code: $?"
level=WARN msg="upgrade failed" name=rollback-demo error="resource Deployment/default/rollback-demo-webapp-chart not ready. status: InProgress, message: Updated: 1/3\ncontext deadline exceeded"
Error: UPGRADE FAILED: resource Deployment/default/rollback-demo-webapp-chart not ready. status: InProgress, message: Updated: 1/3
context deadline exceeded
helm exit code: 1
```

### 5. Verify (the problem)

_**Verify:** revision 3 has status `failed`. One new Pod is stuck in ImagePullBackOff, while the previous Pods keep serving (rolling update)._

```console
$ helm history rollback-demo; kubectl get pods -l app.kubernetes.io/instance=rollback-demo
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION                                                                                                                                
1       	Sun Oct 18 20:25:51 2026	superseded	webapp-chart-0.1.0	1.16.0     	Install complete                                                                                                                           
2       	Sun Oct 18 20:25:53 2026	deployed  	webapp-chart-0.1.0	1.16.0     	Upgrade complete                                                                                                                           
3       	Sun Oct 18 20:26:19 2026	failed    	webapp-chart-0.1.0	1.16.0     	Upgrade "rollback-demo" failed: resource Deployment/default/rollback-demo-webapp-chart not ready. status: InProgress, message: Updated: ...
NAME                                          READY   STATUS         RESTARTS   AGE
rollback-demo-webapp-chart-59469cdd59-bqhd2   1/1     Running        0          88s
rollback-demo-webapp-chart-59469cdd59-gmm57   1/1     Running        0          75s
rollback-demo-webapp-chart-59469cdd59-gxpxm   1/1     Running        0          86s
rollback-demo-webapp-chart-7bb54b98c4-vkf4c   0/1     ErrImagePull   0          61s
```

### 6. Rollback

_**Rollback** to revision 2, the last good one._

```console
$ helm rollback rollback-demo 2 --wait --timeout 180s
Rollback was a success! Happy Helming!
```

### 7. Verify (the repair)

_**Verify:** a new revision 4 (`deployed`) carries the content of revision 2: 3 replicas, nginx 1.27, all Pods Running. Revision 3 stays in the history as `failed`._

```console
$ helm history rollback-demo; kubectl get deploy rollback-demo-webapp-chart -o jsonpath="replicas={.spec.replicas}  image={.spec.template.spec.containers[0].image}{\"\\n\"}"; kubectl get pods -l app.kubernetes.io/instance=rollback-demo
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION                                                                                                                                
1       	Sun Oct 18 20:25:51 2026	superseded	webapp-chart-0.1.0	1.16.0     	Install complete                                                                                                                           
2       	Sun Oct 18 20:25:53 2026	superseded	webapp-chart-0.1.0	1.16.0     	Upgrade complete                                                                                                                           
3       	Sun Oct 18 20:26:19 2026	failed    	webapp-chart-0.1.0	1.16.0     	Upgrade "rollback-demo" failed: resource Deployment/default/rollback-demo-webapp-chart not ready. status: InProgress, message: Updated: ...
4       	Sun Oct 18 20:27:21 2026	deployed  	webapp-chart-0.1.0	1.16.0     	Rollback to 2                                                                                                                              
replicas=3  image=nginx:1.27
NAME                                          READY   STATUS    RESTARTS   AGE
rollback-demo-webapp-chart-59469cdd59-bqhd2   1/1     Running   0          89s
rollback-demo-webapp-chart-59469cdd59-gmm57   1/1     Running   0          76s
rollback-demo-webapp-chart-59469cdd59-gxpxm   1/1     Running   0          87s
```

_Cleanup._

```console
$ helm uninstall rollback-demo
release "rollback-demo" uninstalled
```

### The whole workflow in one picture

| Step | Command | Revision | Status in history | Result |
|---|---|---|---|---|
| Install | `helm install` | 1 | superseded (later) | 1 replica, nginx 1.25 |
| Upgrade | `helm upgrade` | 2 | superseded (later) | 3 replicas, nginx 1.27 |
| Upgrade again | `helm upgrade` (bad tag) | 3 | **failed** | new Pod cannot pull the image |
| Rollback | `helm rollback 2` | 4 | **deployed** | back to the working state of revision 2 |

---

## Task 3: Mini project

**Package and deploy the Notes app with Helm.** The chart is the one from the course mini project, used unchanged: `mini-project/notes-chart` with `values.yaml` (development), `values-prod.yaml` (production), and templates for a ConfigMap, a Deployment and a NodePort Service.

_The chart files and the two values files: replicas, nginx tag and the environment name differ._

```console
$ find mini-project/notes-chart -type f | sort; echo; cat mini-project/notes-chart/values.yaml; echo ---; cat mini-project/notes-chart/values-prod.yaml
mini-project/notes-chart/Chart.yaml
mini-project/notes-chart/templates/configmap.yaml
mini-project/notes-chart/templates/deployment.yaml
mini-project/notes-chart/templates/service.yaml
mini-project/notes-chart/values-prod.yaml
mini-project/notes-chart/values.yaml

replicaCount: 1

image:
  repository: nginx
  tag: "1.24"

service:
  port: 80
  nodePort: 30090

app:
  name: notes-app
  environment: development
---
replicaCount: 3

image:
  repository: nginx
  tag: "1.25"

service:
  port: 80
  nodePort: 30090

app:
  name: notes-app
  environment: production
```

_The Service template (NodePort, port from the values)._

```console
$ cat mini-project/notes-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-svc
spec:
  type: NodePort
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
      nodePort: {{ .Values.service.nodePort }}
```

_Lint, and render with the default (development) values._

```console
$ helm lint mini-project/notes-chart && helm template notes mini-project/notes-chart | grep -E "^kind:|replicas:|image:|ENVIRONMENT|nodePort"
==> Linting mini-project/notes-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
kind: ConfigMap
  ENVIRONMENT: "development"
kind: Service
      nodePort: 30090
kind: Deployment
  replicas: 1
          image: "nginx:1.24"
```

### Installation (development values)

_**Install** the release `notes` with the default values._

```console
$ helm install notes mini-project/notes-chart && kubectl rollout status deployment/notes-deploy --timeout=180s
NAME: notes
LAST DEPLOYED: Sun Oct 18 20:27:24 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
Waiting for deployment "notes-deploy" rollout to finish: 0 of 1 updated replicas are available...
deployment "notes-deploy" successfully rolled out
```

_One Pod, nginx 1.24, ConfigMap with ENVIRONMENT=development._

```console
$ kubectl get deploy,pods,svc,cm -l "app=notes" 2>/dev/null; kubectl get svc notes-svc 2>/dev/null; kubectl get cm notes-config -o jsonpath="{.data}{\"\\n\"}"; helm list
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/notes-deploy   1/1     1            1           1s

NAME                                READY   STATUS    RESTARTS   AGE
pod/notes-deploy-6bdbd76d95-jqlxb   1/1     Running   0          1s
NAME        TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
notes-svc   NodePort   10.102.84.113   <none>        80:30090/TCP   1s
{"APP_NAME":"notes-app","ENVIRONMENT":"development"}
NAME 	NAMESPACE	REVISION	UPDATED                              	STATUS  	CHART            	APP VERSION
notes	default  	1       	2026-10-18 20:27:24.7694865 +0530 IST	deployed	notes-chart-0.1.0	1.0        
```

_The application answers (through a port-forward to the Service)._

```console
$ kubectl port-forward svc/$(kubectl get svc -l app=notes -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo notes-svc) 8092:80 > /tmp/pf-notes.txt 2>&1 & sleep 4; curl -s -I http://localhost:8092 | head -n 3; kill %1
HTTP/1.1 200 OK
Server: nginx/1.24.0
Date: Sun, 18 Oct 2026 14:57:31 GMT
```

### Upgrade (production values)

_**Upgrade** to the production values: 3 replicas, nginx 1.25, ENVIRONMENT=production._

```console
$ helm upgrade notes mini-project/notes-chart -f mini-project/notes-chart/values-prod.yaml && kubectl rollout status deployment/notes-deploy --timeout=180s
Release "notes" has been upgraded. Happy Helming!
NAME: notes
LAST DEPLOYED: Sun Oct 18 20:27:31 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
TEST SUITE: None
Waiting for deployment "notes-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "notes-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "notes-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "notes-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "notes-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "notes-deploy" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "notes-deploy" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "notes-deploy" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "notes-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "notes-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "notes-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "notes-deploy" rollout to finish: 1 old replicas are pending termination...
deployment "notes-deploy" successfully rolled out
```

_Verify: revision 2, the production values are in use, three Pods, and the new environment is visible inside the container._

```console
$ helm history notes; helm get values notes; kubectl get deploy notes-deploy -o jsonpath="replicas={.spec.replicas}  image={.spec.template.spec.containers[0].image}{\"\\n\"}"; kubectl get pods -l app=notes; kubectl exec deploy/notes-deploy -- printenv ENVIRONMENT APP_NAME
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Sun Oct 18 20:27:24 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Sun Oct 18 20:27:31 2026	deployed  	notes-chart-0.1.0	1.0        	Upgrade complete
USER-SUPPLIED VALUES:
app:
  environment: production
  name: notes-app
image:
  repository: nginx
  tag: "1.25"
replicaCount: 3
service:
  nodePort: 30090
  port: 80
replicas=3  image=nginx:1.25
NAME                            READY   STATUS    RESTARTS   AGE
notes-deploy-54f799c6f6-9l7kk   1/1     Running   0          2s
notes-deploy-54f799c6f6-qq7kw   1/1     Running   0          4s
notes-deploy-54f799c6f6-x2njm   1/1     Running   0          3s
production
notes-app
```

### Rollback

_**Rollback** to revision 1 (development): 1 replica, nginx 1.24 again. (The ConfigMap is part of the release, so ENVIRONMENT is back to development too.)_

```console
$ helm rollback notes 1 && kubectl rollout status deployment/notes-deploy --timeout=180s && helm history notes && kubectl get deploy notes-deploy -o jsonpath="replicas={.spec.replicas}  image={.spec.template.spec.containers[0].image}{\"\\n\"}"; kubectl exec deploy/notes-deploy -- printenv ENVIRONMENT
Rollback was a success! Happy Helming!
Waiting for deployment "notes-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "notes-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "notes-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "notes-deploy" rollout to finish: 1 old replicas are pending termination...
deployment "notes-deploy" successfully rolled out
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Sun Oct 18 20:27:24 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Sun Oct 18 20:27:31 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
3       	Sun Oct 18 20:27:37 2026	deployed  	notes-chart-0.1.0	1.0        	Rollback to 1   
replicas=1  image=nginx:1.24
development
```

_Uninstall: the release and all its objects are removed._

```console
$ helm uninstall notes && helm list && kubectl get all 2>/dev/null | head -n 4
release "notes" uninstalled
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION
NAME                                READY   STATUS      RESTARTS   AGE
pod/notes-deploy-6bdbd76d95-ml2l4   0/1     Completed   0          3s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
```

## What I learned

- A chart separates **templates** from **values**: one chart, many environments (`-f values-prod.yaml`, `--set`).
- `helm template` and `helm lint` catch mistakes before anything reaches the cluster.
- Every upgrade is a numbered **revision**; `helm rollback` creates a new revision with the old content, so the history is never lost (the failed revision stays visible).
- `--wait` makes Helm wait for the Pods to become ready, so a bad image is reported as a failed upgrade instead of silently "succeeding".
