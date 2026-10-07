# Session 15: Helm

**Name:** Tejas Varshney  
**Tools:** Helm v3.16.2, minikube v1.39.0 (Kubernetes v1.37.0)

| Task | Where |
|---|---|
| 1. Helm commands | My chart [webapp/](webapp) (made with `helm create`, then customised) → output below |
| 2. Rollback workflow | Install → Upgrade → Verify → Upgrade again → Verify → Rollback → Verify |
| 3. Mini project | [03-mini-project/notes-chart](03-mini-project/notes-chart) |
| Raw outputs | [outputs/](outputs) |

---

## What Helm is (short notes)

Helm is the **package manager for Kubernetes**. A **chart** is a package of templated manifests plus default values. Installing a chart with your values creates a **release**, and every install/upgrade/rollback becomes a numbered **revision**. Helm stores revisions as Secrets (`sh.helm.release.v1.<release>.v<N>`) in the release's namespace, which is what makes `history` and `rollback` possible.

```
Chart (templates + values.yaml)  +  my values (-f / --set)
                    │ helm template / install / upgrade
                    ▼
       rendered Kubernetes YAML ──▶ API server
                    │
        Release "demo", revision 1, 2, 3 …  (stored as Secrets)
```

## My chart: `webapp`

Created with `helm create webapp`, then customised:

| File | What it does |
|---|---|
| [Chart.yaml](webapp/Chart.yaml) | `name: webapp`, chart `version: 0.1.0`, `appVersion: "1.27"` (used as the default nginx tag) |
| [values.yaml](webapp/values.yaml) | Defaults: `replicaCount: 2`, `image.repository: nginx`, service, probes… plus my `page.version/message/color` block |
| [templates/configmap.yaml](webapp/templates/configmap.yaml) | *(added)* Renders `index.html` from values, including `.Release.Name`, `.Release.Revision` and `.Chart.Version`, so every response shows which revision is live |
| [templates/deployment.yaml](webapp/templates/deployment.yaml) | *(edited)* Mounts that ConfigMap as nginx's web root, with a `checksum/site` annotation (`sha256sum` of the rendered ConfigMap) so Pods roll automatically when page values change |
| `templates/_helpers.tpl` | Named templates: `webapp.fullname`, `webapp.labels`, `webapp.selectorLabels` |
| `templates/service.yaml`, `serviceaccount.yaml`, `hpa.yaml`, `ingress.yaml`, `NOTES.txt` | From `helm create`; HPA and Ingress are off by default (`enabled: false`) |
| `templates/tests/test-connection.yaml` | Used by `helm test`: a busybox Pod that `wget`s the Service |

Template syntax used: `{{ .Values.x }}`, `{{ .Release.Name }}`, `{{ include "..." . }}`, pipelines (`| nindent 4`, `| quote`, `| sha256sum`, `| default`), `{{- with }}`, `{{- if }}`, `toYaml`.

---

## Task 1 – Helm commands

| Command | What it does |
|---|---|
| `helm create <name>` | Scaffolds a new chart (Chart.yaml, values.yaml, templates/, helpers, tests) |
| `helm lint` / `helm template` | Validate the chart / render the YAML locally without installing anything |
| `helm install <release> <chart>` | Renders + applies the chart → revision 1. `--create-namespace`, `--wait`, `-f values.yaml`, `--set k=v` |
| `helm list` | Releases in a namespace (`-A` for all), with status, revision, chart and app version |
| `helm status <release>` | Release state, last deployment time, revision and NOTES |
| `helm get values / manifest / notes / metadata / all` | What was actually deployed: user values (`--all` for computed), rendered manifest, notes |
| `helm upgrade <release> <chart>` | Applies a new chart version or new values → new revision. `--reuse-values`, `--install`, `--atomic` |
| `helm history <release>` | All revisions with status (deployed / superseded / failed) and description |
| `helm rollback <release> [rev]` | Re-applies an older revision's manifest **as a new revision** |
| `helm test <release>` | Runs the chart's test hooks |
| `helm uninstall <release>` | Deletes every resource of the release and its history |
| `helm repo add / update / list` | Manage chart repositories |
| `helm search repo / hub` | Search the added repos / Artifact Hub |
| `helm show chart / values` | Inspect a chart before installing it |

```text
################ helm create ################
$ helm create scratch-chart && find scratch-chart -type f | sort && rm -rf scratch-chart
Creating scratch-chart
scratch-chart/.helmignore
scratch-chart/Chart.yaml
scratch-chart/templates/NOTES.txt
scratch-chart/templates/_helpers.tpl
scratch-chart/templates/deployment.yaml
scratch-chart/templates/hpa.yaml
scratch-chart/templates/ingress.yaml
scratch-chart/templates/service.yaml
scratch-chart/templates/serviceaccount.yaml
scratch-chart/templates/tests/test-connection.yaml
scratch-chart/values.yaml

# (my customised chart "webapp" was created the same way: helm create webapp, then edited)
$ find webapp -type f | sort
webapp/.helmignore
webapp/Chart.yaml
webapp/templates/NOTES.txt
webapp/templates/_helpers.tpl
webapp/templates/configmap.yaml
webapp/templates/deployment.yaml
webapp/templates/hpa.yaml
webapp/templates/ingress.yaml
webapp/templates/service.yaml
webapp/templates/serviceaccount.yaml
webapp/templates/tests/test-connection.yaml
webapp/values.yaml

################ helm lint / helm template (render locally, nothing installed) ################
$ helm lint webapp
==> Linting webapp
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

$ helm template demo webapp --namespace helm-demo | grep -E '^kind:|^  name:|image:|replicas:'
kind: ServiceAccount
  name: demo-webapp
kind: ConfigMap
  name: demo-webapp-site
kind: Service
  name: demo-webapp
kind: Deployment
  name: demo-webapp
  replicas: 2
          image: "nginx:1.27"
kind: Pod
  name: "demo-webapp-test-connection"
      image: busybox

################ helm install ################
$ helm install demo webapp --namespace helm-demo --create-namespace --wait --timeout 3m
NAME: demo
LAST DEPLOYED: Thu Oct  8 01:30:13 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT

################ helm list ################
$ helm list -n helm-demo
NAME	NAMESPACE	REVISION	UPDATED                              	STATUS  	CHART       	APP VERSION
demo	helm-demo	1       	2026-10-08 01:30:13.1030599 +0530 IST	deployed	webapp-0.1.0	1.27       

$ helm list -A
NAME	NAMESPACE	REVISION	UPDATED                              	STATUS  	CHART       	APP VERSION
demo	helm-demo	1       	2026-10-08 01:30:13.1030599 +0530 IST	deployed	webapp-0.1.0	1.27       

################ helm status ################
$ helm status demo -n helm-demo
NAME: demo
LAST DEPLOYED: Thu Oct  8 01:30:13 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT

$ kubectl get all -n helm-demo
NAME                               READY   STATUS    RESTARTS   AGE
pod/demo-webapp-65d8d75cdf-6dqtx   1/1     Running   0          2s
pod/demo-webapp-65d8d75cdf-x2n5f   1/1     Running   0          2s

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/demo-webapp   ClusterIP   10.111.152.98   <none>        80/TCP    2s

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/demo-webapp   2/2     2            2           2s

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/demo-webapp-65d8d75cdf   2         2         2       2s

$ kubectl exec curl -- curl -s http://demo-webapp.helm-demo
<html><body style="font-family:sans-serif;color:#2563eb">
<h1>Hello from Helm</h1>
<p>version=v1 release=demo revision=1 chart=webapp-0.1.0</p>
</body></html>

################ helm get ################
$ helm get values demo -n helm-demo
USER-SUPPLIED VALUES:
null

$ helm get values demo -n helm-demo --all | head -20
COMPUTED VALUES:
affinity: {}
autoscaling:
  enabled: false
  maxReplicas: 100
  minReplicas: 1
  targetCPUUtilizationPercentage: 80
fullnameOverride: ""
image:
  pullPolicy: IfNotPresent
  repository: nginx
  tag: ""
imagePullSecrets: []
ingress:
  annotations: {}
  className: ""
  enabled: false
  hosts:
  - host: chart-example.local
    paths:

$ helm get manifest demo -n helm-demo | grep -E '^# Source|^kind:'
# Source: webapp/templates/serviceaccount.yaml
kind: ServiceAccount
# Source: webapp/templates/configmap.yaml
kind: ConfigMap
# Source: webapp/templates/service.yaml
kind: Service
# Source: webapp/templates/deployment.yaml
kind: Deployment

$ helm get notes demo -n helm-demo
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT


$ helm get metadata demo -n helm-demo
NAME: demo
CHART: webapp
VERSION: 0.1.0
APP_VERSION: 1.27
NAMESPACE: helm-demo
REVISION: 1
STATUS: deployed
DEPLOYED_AT: 2026-10-08T01:30:13+05:30

################ helm upgrade ################
$ helm upgrade demo webapp -n helm-demo --set replicaCount=3 --set page.version=v2 --set page.message='Upgraded with helm upgrade' --wait
Release "demo" has been upgraded. Happy Helming!
NAME: demo
LAST DEPLOYED: Thu Oct  8 01:30:17 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 2
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT

$ kubectl get pods -n helm-demo
NAME                           READY   STATUS    RESTARTS   AGE
demo-webapp-565cb976c6-gqwtb   1/1     Running   0          2s
demo-webapp-565cb976c6-gwf48   1/1     Running   0          4s
demo-webapp-565cb976c6-hr4n7   1/1     Running   0          3s

$ kubectl exec curl -- curl -s http://demo-webapp.helm-demo
<html><body style="font-family:sans-serif;color:#2563eb">
<h1>Upgraded with helm upgrade</h1>
<p>version=v2 release=demo revision=2 chart=webapp-0.1.0</p>
</body></html>

################ helm history ################
$ helm history demo -n helm-demo
REVISION	UPDATED                 	STATUS    	CHART       	APP VERSION	DESCRIPTION     
1       	Thu Oct  8 01:30:13 2026	superseded	webapp-0.1.0	1.27       	Install complete
2       	Thu Oct  8 01:30:17 2026	deployed  	webapp-0.1.0	1.27       	Upgrade complete

################ helm rollback ################
$ helm rollback demo 1 -n helm-demo --wait
Rollback was a success! Happy Helming!

$ helm history demo -n helm-demo
REVISION	UPDATED                 	STATUS    	CHART       	APP VERSION	DESCRIPTION     
1       	Thu Oct  8 01:30:13 2026	superseded	webapp-0.1.0	1.27       	Install complete
2       	Thu Oct  8 01:30:17 2026	superseded	webapp-0.1.0	1.27       	Upgrade complete
3       	Thu Oct  8 01:30:21 2026	deployed  	webapp-0.1.0	1.27       	Rollback to 1   

$ kubectl exec curl -- curl -s http://demo-webapp.helm-demo
<html><body style="font-family:sans-serif;color:#2563eb">
<h1>Hello from Helm</h1>
<p>version=v1 release=demo revision=1 chart=webapp-0.1.0</p>
</body></html>

$ kubectl get secrets -n helm-demo -l owner=helm
NAME                         TYPE                 DATA   AGE
sh.helm.release.v1.demo.v1   helm.sh/release.v1   1      13s
sh.helm.release.v1.demo.v2   helm.sh/release.v1   1      9s
sh.helm.release.v1.demo.v3   helm.sh/release.v1   1      5s

################ helm test ################
$ helm test demo -n helm-demo
NAME: demo
LAST DEPLOYED: Thu Oct  8 01:30:21 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 3
TEST SUITE:     demo-webapp-test-connection
Last Started:   Thu Oct  8 01:30:26 2026
Last Completed: Thu Oct  8 01:30:37 2026
Phase:          Succeeded
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT

################ helm uninstall ################
$ helm uninstall demo -n helm-demo --wait
release "demo" uninstalled

$ helm list -n helm-demo
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION

$ kubectl get all -n helm-demo
NAME                               READY   STATUS      RESTARTS   AGE
pod/demo-webapp-65d8d75cdf-5gchc   0/1     Completed   0          16s
pod/demo-webapp-65d8d75cdf-mclmh   0/1     Completed   0          14s
pod/demo-webapp-test-connection    0/1     Completed   0          11s

################ helm repo ################
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories

$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
"prometheus-community" has been added to your repositories

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "prometheus-community" chart repository
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈

$ helm repo list
NAME                	URL                                               
bitnami             	https://charts.bitnami.com/bitnami                
prometheus-community	https://prometheus-community.github.io/helm-charts

################ helm search ################
$ helm search repo nginx | head -6
NAME                                          	CHART VERSION	APP VERSION	DESCRIPTION                                       
bitnami/nginx                                 	25.2.1       	1.31.6     	NGINX Open Source is a web server that can be a...
bitnami/nginx-ingress-controller              	12.0.7       	1.13.1     	NGINX Ingress Controller is an Ingress controll...
bitnami/nginx-intel                           	2.1.15       	0.4.9      	DEPRECATED NGINX Open Source for Intel is a lig...
prometheus-community/prometheus-nginx-exporter	1.23.1       	1.5.3      	A Helm chart for NGINX Prometheus Exporter        

$ helm search repo prometheus-community/kube-prometheus-stack --versions | head -4
NAME                                      	CHART VERSION	APP VERSION	DESCRIPTION                                       
prometheus-community/kube-prometheus-stack	92.1.0       	v0.94.1    	kube-prometheus-stack collects Kubernetes manif...
prometheus-community/kube-prometheus-stack	92.0.0       	v0.94.1    	kube-prometheus-stack collects Kubernetes manif...
prometheus-community/kube-prometheus-stack	91.9.0       	v0.94.1    	kube-prometheus-stack collects Kubernetes manif...

$ helm search hub argo-cd --max-col-width 60 | head -5
URL                                                         	CHART VERSION	APP VERSION	DESCRIPTION                                                 
https://artifacthub.io/packages/helm/spnngl-argo-cd-crds/...	3.5.6        	3.5.4      	CustomResourceDefinitions for Argo CD (Applications, Appl...
https://artifacthub.io/packages/helm/emberstack/argo-cd-e...	1.0.22       	1.0.0      	A Helm chart for Argo CD extensions                         
https://artifacthub.io/packages/helm/argo-cd-oci/argo-cd    	10.10.0      	v3.5.4     	A Helm chart for Argo CD, a declarative, GitOps continuou...
https://artifacthub.io/packages/helm/mesosphere-stable/ar...	0.5.4        	1.2.0      	A Helm chart for Argo-CD                                    

$ helm show chart bitnami/nginx | head -12
Error: failed to do request: Head "https://registry-1.docker.io/v2/bitnamicharts/nginx/manifests/25.2.1": dial tcp: lookup registry-1.docker.io: no such host
# (DNS lookups of registry-1.docker.io were intermittently failing on my network; the retry failed too.
#  The next command, helm show values, reached the same OCI chart successfully.)

$ helm show values bitnami/nginx | grep -A3 '^replicaCount' 
replicaCount: 1
## @param revisionHistoryLimit The number of old history to retain to allow rollback
##
revisionHistoryLimit: 10
```

**Observations**
- `helm install` printed the rendered **NOTES.txt**, and the page returned `revision=1`.
- `helm upgrade --set replicaCount=3 --set page.version=v2` produced revision 2: 3 Pods, the new page, and Pods restarted because the checksum annotation changed.
- `helm rollback demo 1` didn't "go back" to revision 1. It created **revision 3** with revision 1's content (`DESCRIPTION: Rollback to 1`). The three release Secrets `sh.helm.release.v1.demo.v1..v3` show where history lives.
- `helm uninstall` removed every object (`kubectl get all` returned nothing) and the release history.
- `helm search repo` lists charts from added repos. `helm search hub` queries Artifact Hub without adding anything.

---

## Task 2 – Helm rollback workflow

Install → Upgrade → Verify → Upgrade again → Verify → **Rollback** → Verify, using release `shop` of my chart.

```text
################ 1. INSTALL (revision 1) ################
$ helm install shop webapp -n helm-demo --create-namespace --set page.version=v1 --set page.message='Shop v1' --wait
NAME: shop
LAST DEPLOYED: Thu Oct  8 01:31:16 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=shop" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT

$ helm list -n helm-demo
NAME	NAMESPACE	REVISION	UPDATED                              	STATUS  	CHART       	APP VERSION
shop	helm-demo	1       	2026-10-08 01:31:16.8316996 +0530 IST	deployed	webapp-0.1.0	1.27       

---- verify ----
$ kubectl exec curl -- curl -s http://shop-webapp.helm-demo
<html><body style="font-family:sans-serif;color:#2563eb">
<h1>Shop v1</h1>
<p>version=v1 release=shop revision=1 chart=webapp-0.1.0</p>
</body></html>

$ kubectl get deploy shop-webapp -n helm-demo -o jsonpath='{.spec.replicas} replicas, image {.spec.template.spec.containers[0].image}'; echo
2 replicas, image nginx:1.27

################ 2. UPGRADE (revision 2: 3 replicas, nginx 1.25, page v2) ################
$ helm upgrade shop webapp -n helm-demo --reuse-values --set replicaCount=3 --set image.tag=1.25 --set page.version=v2 --set page.message='Shop v2' --set page.color='#16a34a' --wait
Release "shop" has been upgraded. Happy Helming!
NAME: shop
LAST DEPLOYED: Thu Oct  8 01:31:19 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 2
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=shop" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT

---- verify ----
$ kubectl get pods -n helm-demo
NAME                           READY   STATUS      RESTARTS   AGE
demo-webapp-test-connection    0/1     Completed   0          57s
shop-webapp-6898cd6658-shp6x   0/1     Completed   0          7s
shop-webapp-7b8cf94f86-6jtcg   1/1     Running     0          2s
shop-webapp-7b8cf94f86-clx77   1/1     Running     0          4s
shop-webapp-7b8cf94f86-kp566   1/1     Running     0          1s

$ kubectl exec curl -- curl -s http://shop-webapp.helm-demo
<html><body style="font-family:sans-serif;color:#16a34a">
<h1>Shop v2</h1>
<p>version=v2 release=shop revision=2 chart=webapp-0.1.0</p>
</body></html>

$ kubectl get deploy shop-webapp -n helm-demo -o jsonpath='{.spec.replicas} replicas, image {.spec.template.spec.containers[0].image}'; echo
3 replicas, image nginx:1.25

################ 3. UPGRADE AGAIN (revision 3: a bad release - wrong image tag) ################
$ helm upgrade shop webapp -n helm-demo --reuse-values --set image.tag=1.99-does-not-exist --set page.version=v3 --set page.message='Shop v3'
Release "shop" has been upgraded. Happy Helming!
NAME: shop
LAST DEPLOYED: Thu Oct  8 01:31:24 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 3
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=webapp,app.kubernetes.io/instance=shop" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT

---- verify (it is broken) ----
$ kubectl get pods -n helm-demo
NAME                           READY   STATUS             RESTARTS   AGE
demo-webapp-test-connection    0/1     Completed          0          103s
shop-webapp-687465849d-rj7xx   0/1     ImagePullBackOff   0          45s
shop-webapp-7b8cf94f86-6jtcg   1/1     Running            0          48s
shop-webapp-7b8cf94f86-clx77   1/1     Running            0          50s
shop-webapp-7b8cf94f86-kp566   1/1     Running            0          47s

$ kubectl describe pod -n helm-demo -l app.kubernetes.io/instance=shop | grep -E 'Failed to pull|ErrImagePull|BackOff' | head -3
      Reason:       ImagePullBackOff
  Warning  Failed     26s (x2 over 43s)  kubelet            Failed to pull image "nginx:1.99-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:1.99-does-not-exist": failed to resolve reference "docker.io/library/nginx:1.99-does-not-exist": docker.io/library/nginx:1.99-does-not-exist: not found
  Warning  Failed     26s (x2 over 43s)  kubelet            Error: ErrImagePull

$ helm history shop -n helm-demo
REVISION	UPDATED                 	STATUS    	CHART       	APP VERSION	DESCRIPTION     
1       	Thu Oct  8 01:31:16 2026	superseded	webapp-0.1.0	1.27       	Install complete
2       	Thu Oct  8 01:31:19 2026	superseded	webapp-0.1.0	1.27       	Upgrade complete
3       	Thu Oct  8 01:31:24 2026	deployed  	webapp-0.1.0	1.27       	Upgrade complete

$ kubectl exec curl -- curl -s http://shop-webapp.helm-demo
<html><body style="font-family:sans-serif;color:#16a34a">
<h1>Shop v2</h1>
<p>version=v2 release=shop revision=2 chart=webapp-0.1.0</p>
</body></html>

# The old v2 Pods keep serving (RollingUpdate never removed them because the new Pods never became Ready), but the release is unhealthy.
################ 4. ROLLBACK to revision 2 ################
$ helm rollback shop 2 -n helm-demo --wait
Rollback was a success! Happy Helming!

---- verify ----
$ helm history shop -n helm-demo
REVISION	UPDATED                 	STATUS    	CHART       	APP VERSION	DESCRIPTION     
1       	Thu Oct  8 01:31:16 2026	superseded	webapp-0.1.0	1.27       	Install complete
2       	Thu Oct  8 01:31:19 2026	superseded	webapp-0.1.0	1.27       	Upgrade complete
3       	Thu Oct  8 01:31:24 2026	superseded	webapp-0.1.0	1.27       	Upgrade complete
4       	Thu Oct  8 01:32:10 2026	deployed  	webapp-0.1.0	1.27       	Rollback to 2   

$ kubectl get pods -n helm-demo
NAME                           READY   STATUS        RESTARTS   AGE
demo-webapp-test-connection    0/1     Completed     0          106s
shop-webapp-687465849d-rj7xx   0/1     Terminating   0          48s
shop-webapp-7b8cf94f86-6jtcg   1/1     Running       0          51s
shop-webapp-7b8cf94f86-clx77   1/1     Running       0          53s
shop-webapp-7b8cf94f86-kp566   1/1     Running       0          50s

$ kubectl exec curl -- curl -s http://shop-webapp.helm-demo
<html><body style="font-family:sans-serif;color:#16a34a">
<h1>Shop v2</h1>
<p>version=v2 release=shop revision=2 chart=webapp-0.1.0</p>
</body></html>

$ helm get values shop -n helm-demo
USER-SUPPLIED VALUES:
image:
  tag: "1.25"
page:
  color: '#16a34a'
  message: Shop v2
  version: v2
replicaCount: 3

$ helm get values shop -n helm-demo --revision 3
USER-SUPPLIED VALUES:
image:
  tag: 1.99-does-not-exist
page:
  color: '#16a34a'
  message: Shop v3
  version: v3
replicaCount: 3

$ helm uninstall shop -n helm-demo --wait
release "shop" uninstalled
```

| Step | Revision | What changed | Verified |
|---|---|---|---|
| Install | 1 | 2 replicas, nginx 1.27, page "Shop v1" | page shows `revision=1`, 2 replicas |
| Upgrade | 2 | 3 replicas, nginx **1.25**, page "Shop v2" (green) | 3 Pods Running, `image nginx:1.25`, page `revision=2` |
| Upgrade again | 3 | Image tag `1.99-does-not-exist` + page v3 (**bad release**) | New Pod stuck in `ImagePullBackOff` (`not found`). Helm still says `deployed` because I didn't use `--wait`/`--atomic` |
| Rollback | **4** (= copy of 2) | Back to nginx 1.25 / "Shop v2" | broken Pod Terminating, 3 healthy Pods, page v2. `helm get values --revision 3` still shows what the bad release contained |

**What I learned**
- During the bad upgrade, users were mostly unaffected: the Deployment's RollingUpdate kept the 3 old Pods because the new Pod never became Ready. Kubernetes and Helm protect you at different layers.
- Helm marked revision 3 as `deployed` even though it was broken. In CI, use `helm upgrade --install --atomic --wait --timeout 5m`: Helm then waits for readiness and **rolls back automatically** on failure.
- A bad release can be partial: revision 3 also changed the ConfigMap. A mounted ConfigMap updates on the old Pods within about a minute, so config and image changes in one release can mix. Another reason for `--atomic` and checksum annotations.
- `helm rollback` with no revision number rolls back to the previous revision. Keep history bounded with `--history-max`.

---

## Task 3 – Mini project: Notes app chart

The chart from the course instructions ([03-mini-project/notes-chart](03-mini-project/notes-chart)): `Chart.yaml`, `values.yaml` (dev: 1 replica, nginx 1.24), `values-prod.yaml` (prod: 3 replicas, nginx 1.25), and templates for the Deployment, a NodePort Service (30090) and a ConfigMap injected with `envFrom`.

```text
################ Step 8: lint ################
$ helm lint notes-chart
==> Linting notes-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

################ Step 9: render locally ################
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
          envFrom:
            - configMapRef:
                name: notes-dev-config

################ Step 10: install (development) ################
$ helm install notes-dev notes-chart --wait
NAME: notes-dev
LAST DEPLOYED: Thu Oct  8 01:32:14 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

$ kubectl get pods -l app=notes-dev
NAME                                READY   STATUS    RESTARTS   AGE
notes-dev-deploy-74956bd987-rz2dv   1/1     Running   0          2s

$ kubectl get services notes-dev-svc
NAME            TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
notes-dev-svc   NodePort   10.111.168.125   <none>        80:30090/TCP   2s

$ kubectl get configmaps notes-dev-config -o jsonpath='{.data}'; echo
{"APP_NAME":"notes-app","ENVIRONMENT":"development"}

$ kubectl exec deploy/notes-dev-deploy -- sh -c 'echo APP_NAME=$APP_NAME ENVIRONMENT=$ENVIRONMENT; nginx -v'
APP_NAME=notes-app ENVIRONMENT=development
nginx version: nginx/1.24.0

$ minikube ssh -- curl -s -o /dev/null -w '%{http_code}' http://192.168.49.2:30090; echo
200

################ Step 11: upgrade to production values ################
$ helm upgrade notes-dev notes-chart -f notes-chart/values-prod.yaml --wait
Release "notes-dev" has been upgraded. Happy Helming!
NAME: notes-dev
LAST DEPLOYED: Thu Oct  8 01:32:17 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None

$ kubectl get pods -l app=notes-dev
NAME                                READY   STATUS      RESTARTS   AGE
notes-dev-deploy-74956bd987-rz2dv   0/1     Completed   0          5s
notes-dev-deploy-bbcc464b4-7jrbt    1/1     Running     0          1s
notes-dev-deploy-bbcc464b4-z7l69    1/1     Running     0          2s
notes-dev-deploy-bbcc464b4-zfgmr    1/1     Running     0          1s

$ kubectl exec deploy/notes-dev-deploy -- sh -c 'echo ENVIRONMENT=$ENVIRONMENT; nginx -v'
ENVIRONMENT=production
nginx version: nginx/1.25.5

################ Step 12: release history ################
$ helm history notes-dev
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Thu Oct  8 01:32:14 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Thu Oct  8 01:32:17 2026	deployed  	notes-chart-0.1.0	1.0        	Upgrade complete

################ Step 13: simulate a bad upgrade ################
$ helm upgrade notes-dev notes-chart -f notes-chart/values-prod.yaml --set image.tag=broken-tag-does-not-exist
Release "notes-dev" has been upgraded. Happy Helming!
NAME: notes-dev
LAST DEPLOYED: Thu Oct  8 01:32:20 2026
NAMESPACE: default
STATUS: deployed
REVISION: 3
TEST SUITE: None

$ kubectl get pods -l app=notes-dev
NAME                                READY   STATUS         RESTARTS   AGE
notes-dev-deploy-79b4dbdffd-s677w   0/1     ErrImagePull   0          40s
notes-dev-deploy-bbcc464b4-7jrbt    1/1     Running        0          42s
notes-dev-deploy-bbcc464b4-z7l69    1/1     Running        0          43s
notes-dev-deploy-bbcc464b4-zfgmr    1/1     Running        0          42s

################ Step 14: rollback to revision 2 ################
$ helm rollback notes-dev 2 --wait
Rollback was a success! Happy Helming!

$ kubectl get pods -l app=notes-dev
NAME                               READY   STATUS    RESTARTS   AGE
notes-dev-deploy-bbcc464b4-7jrbt   1/1     Running   0          44s
notes-dev-deploy-bbcc464b4-z7l69   1/1     Running   0          45s
notes-dev-deploy-bbcc464b4-zfgmr   1/1     Running   0          44s

$ helm history notes-dev
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Thu Oct  8 01:32:14 2026	superseded	notes-chart-0.1.0	1.0        	Install complete
2       	Thu Oct  8 01:32:17 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
3       	Thu Oct  8 01:32:20 2026	superseded	notes-chart-0.1.0	1.0        	Upgrade complete
4       	Thu Oct  8 01:33:00 2026	deployed  	notes-chart-0.1.0	1.0        	Rollback to 2   

################ Step 15: clean up ################
$ helm uninstall notes-dev --wait
release "notes-dev" uninstalled

$ kubectl get pods -l app=notes-dev
NAME                               READY   STATUS        RESTARTS   AGE
notes-dev-deploy-bbcc464b4-7jrbt   1/1     Terminating   0          45s
notes-dev-deploy-bbcc464b4-z7l69   1/1     Terminating   0          46s
notes-dev-deploy-bbcc464b4-zfgmr   1/1     Terminating   0          45s

$ kubectl get services notes-dev-svc
Error from server (NotFound): services "notes-dev-svc" not found
```

| Step | Result |
|---|---|
| Lint | `1 chart(s) linted, 0 chart(s) failed` |
| Template | All `{{ }}` rendered (`notes-dev-config`, `notes-dev-deploy`, `notes-dev-svc`) |
| Install (dev) | revision 1: 1 Pod, `ENVIRONMENT=development`, nginx 1.24.0, NodePort 30090 → HTTP 200 |
| Upgrade with `-f values-prod.yaml` | revision 2: 3 Pods, `ENVIRONMENT=production`, nginx 1.25.5 |
| Bad upgrade `--set image.tag=broken-tag-does-not-exist` | revision 3: new Pod `ErrImagePull`; the 3 old Pods kept running |
| `helm rollback notes-dev 2` | revision 4 = "Rollback to 2", 3 healthy Pods |
| Uninstall | Pods terminating, `services "notes-dev-svc" not found` |

```text
[PASS] Created a Helm chart from scratch
[PASS] Used values.yaml and values-prod.yaml
[PASS] Deployed to Kubernetes with helm install
[PASS] Upgraded the release with different values
[PASS] Simulated a bad upgrade (broken image tag)
[PASS] Rolled back to a healthy revision
[PASS] Cleaned up with helm uninstall
```

## Why Helm (vs plain YAML)
- **One chart, many environments:** the same templates with `values.yaml` / `values-prod.yaml`, instead of copy-pasted manifests.
- **Release management:** versioned revisions, `history`, one-command `rollback`, and `uninstall` that removes everything it created.
- **Sharing:** install community software (Prometheus, Argo CD, ingress-nginx) with `helm repo add` + `helm install`, as I do in Sessions 20 and 21.
