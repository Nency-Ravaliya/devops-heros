# Task 1 – Helm commands

**Name:** Kushal Talati · **Enrollment No:** 24BCS10123 · Helm v4.3.0, kind cluster `kushal-lab`, namespace `s15-helm`

Script: [`../scripts/01-helm-commands.sh`](../scripts/01-helm-commands.sh) · Raw log: [`../logs/01-helm-commands.txt`](../logs/01-helm-commands.txt)

Every command below was run once, in this order. The output blocks are copied from the log (long outputs trimmed, the log has them in full).

## helm version / helm env

What it does: shows the client build; `helm env` shows where Helm keeps repo indexes, cache and which namespace it talks to.

```text
$ helm version
version.BuildInfo{Version:"v4.3.0", GitCommit:"bec5b06ed841fe5269972d864d5177944fd5970f", GitTreeState:"clean", GoVersion:"go1.27.1", KubeClientVersion:"v1.37"}

$ helm env | grep -E 'HELM_NAMESPACE|HELM_REPOSITORY_CONFIG|HELM_CACHE_HOME'
HELM_CACHE_HOME="/Users/kushalscaler/Library/Caches/helm"
HELM_NAMESPACE="s15-helm"
HELM_REPOSITORY_CONFIG="/Users/kushalscaler/Library/Preferences/helm/repositories.yaml"
```

## helm repo add / update / list

What it does: a repo is just an HTTP server with an `index.yaml` and `.tgz` files. `add` records the URL, `update` downloads the fresh index, `list` shows what is configured.

```text
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" already exists with the same configuration, skipping

$ helm repo update
...Successfully got an update from the "argo" chart repository
...Successfully got an update from the "prometheus-community" chart repository
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈

$ helm repo list
NAME                	URL
prometheus-community	https://prometheus-community.github.io/helm-charts
argo                	https://argoproj.github.io/argo-helm
bitnami             	https://charts.bitnami.com/bitnami
```

## helm search repo / helm search hub

What it does: `search repo` greps the indexes I already downloaded (offline); `search hub` asks Artifact Hub over the internet. `--versions` lists every chart version.

```text
$ helm search repo nginx --max-col-width 60 | head -8
NAME                                          	CHART VERSION	APP VERSION	DESCRIPTION
bitnami/nginx                                 	25.2.1       	1.31.6     	NGINX Open Source is a web server that can be also used a...
bitnami/nginx-ingress-controller              	12.0.7       	1.13.1     	NGINX Ingress Controller is an Ingress controller that ma...
prometheus-community/prometheus-nginx-exporter	1.23.1       	1.5.3      	A Helm chart for NGINX Prometheus Exporter

$ helm search repo prometheus-community/kube-prometheus-stack --versions | head -4
prometheus-community/kube-prometheus-stack	92.1.0       	v0.94.1    	kube-prometheus-stack collects Kubernetes manif...
prometheus-community/kube-prometheus-stack	92.0.0       	v0.94.1    	...

$ helm search hub nginx --max-col-width 55 | head -8
URL                                                    	CHART VERSION  	APP VERSION
https://artifacthub.io/packages/helm/bitnami/nginx     	25.2.1         	1.31.6
https://artifacthub.io/packages/helm/quench-nginx/nginx	0.0.15         	1.30.5
...
```

## helm create

What it does: scaffolds a complete starter chart (Deployment, Service, ServiceAccount, Ingress, HPA, test hook, NOTES.txt, `_helpers.tpl`). It is the normal way to start a chart – you delete what you do not need.

```text
$ helm create demo-chart
Creating demo-chart

$ find demo-chart -type f | sort
demo-chart/.helmignore
demo-chart/Chart.yaml
demo-chart/templates/_helpers.tpl
demo-chart/templates/deployment.yaml
demo-chart/templates/hpa.yaml
demo-chart/templates/httproute.yaml
demo-chart/templates/ingress.yaml
demo-chart/templates/NOTES.txt
demo-chart/templates/service.yaml
demo-chart/templates/serviceaccount.yaml
demo-chart/templates/tests/test-connection.yaml
demo-chart/values.yaml

$ grep -nE '^(replicaCount|image:|  repository|  tag|service:|  type|  port)' demo-chart/values.yaml
6:replicaCount: 1
9:image:
10:  repository: nginx
14:  tag: ""            <- empty tag means "use appVersion" (1.16.0), which is why I passed --set image.tag=1.27-alpine below
53:service:
55:  type: ClusterIP
57:  port: 80
```

## helm lint / helm template / helm show

What they do, all without a cluster: `lint` checks the chart for errors, `template` renders the YAML Kubernetes would receive, `show chart|values` prints `Chart.yaml` / default values of any chart (local or from a repo).

```text
$ helm lint demo-chart
==> Linting demo-chart
[INFO] Chart.yaml: icon is recommended
1 chart(s) linted, 0 chart(s) failed

$ helm template demo demo-chart --set image.tag=1.27-alpine | grep -E '^(kind:|  name:|        image:|  replicas:)'
kind: ServiceAccount
  name: demo-demo-chart
kind: Service
  name: demo-demo-chart
kind: Deployment
  name: demo-demo-chart
  replicas: 1
kind: Pod
  name: "demo-demo-chart-test-connection"

$ helm show chart demo-chart
apiVersion: v2
appVersion: 1.16.0
description: A Helm chart for Kubernetes
name: demo-chart
type: application
version: 0.1.0
```

## helm package

What it does: tars the chart folder into `<name>-<version>.tgz` – the artifact a repo serves.

```text
$ helm package demo-chart
Successfully packaged chart and saved it to: /tmp/s15-helm-bPfO/demo-chart-0.1.0.tgz

$ ls -la demo-chart-0.1.0.tgz && tar tzf demo-chart-0.1.0.tgz | head -5
-rw-r--r--@ 1 kushalscaler  wheel  5030 Oct  7 23:12 demo-chart-0.1.0.tgz
demo-chart/Chart.yaml
demo-chart/values.yaml
demo-chart/templates/NOTES.txt
...
```

## helm install

What it does: renders the chart with the given values and creates the objects. Prints the release name, namespace, revision and the chart's NOTES.txt.

```text
$ helm install demo ./demo-chart-0.1.0.tgz --set image.tag=1.27-alpine
NAME: demo
LAST DEPLOYED: Wed Oct  7 23:12:33 2026
NAMESPACE: s15-helm
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace s15-helm -l "app.kubernetes.io/name=demo-chart,app.kubernetes.io/instance=demo" -o jsonpath="{.items[0].metadata.name}")
  ...

$ kubectl -n s15-helm rollout status deployment/demo-demo-chart --timeout=120s
deployment "demo-demo-chart" successfully rolled out
```

## helm list / helm status / helm get

What they do: `list` = releases in the namespace (`-A` for all), `status` = the install output again plus related resources, `get values|manifest|notes|all` = what Helm stored for the current revision. The last command shows *where* it is stored.

```text
$ helm list
NAME	NAMESPACE	REVISION	UPDATED                             	STATUS  	CHART           	APP VERSION
demo	s15-helm 	1       	2026-10-07 23:12:33.786381 +0530 IST	deployed	demo-chart-0.1.0	1.16.0

$ helm list --all-namespaces | grep -E 'NAME|demo|kube-prometheus'
demo                 	s15-helm  	1   ...	deployed	demo-chart-0.1.0
kube-prometheus-stack	monitoring	1   ...	deployed	kube-prometheus-stack-92.1.0      <- the monitoring stack on this cluster is also a Helm release

$ helm status demo | sed -n '1,8p'
NAME: demo
LAST DEPLOYED: Wed Oct  7 23:12:33 2026
NAMESPACE: s15-helm
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
RESOURCES:
==> v1/Pod(related)

$ helm get values demo
USER-SUPPLIED VALUES:
image:
  tag: 1.27-alpine

$ helm get values demo --all | sed -n '1,15p'      # user values merged on top of values.yaml
COMPUTED VALUES:
affinity: {}
autoscaling:
  enabled: false
  maxReplicas: 100
  ...

$ helm get manifest demo | grep -E '^(kind:|  name:|        image:)'
kind: ServiceAccount
  name: demo-demo-chart
kind: Service
  name: demo-demo-chart
kind: Deployment
  name: demo-demo-chart

$ helm get all demo | wc -l
     190

$ kubectl -n s15-helm get secret -l owner=helm -o custom-columns='NAME:.metadata.name,TYPE:.type'
NAME                         TYPE
sh.helm.release.v1.demo.v1   helm.sh/release.v1
```

## helm upgrade / helm history

What they do: `upgrade` re-renders with new values and applies the diff, creating revision N+1; `history` lists every revision. `upgrade --install` is the idempotent form for pipelines (installs if missing, upgrades otherwise).

```text
$ helm upgrade demo ./demo-chart-0.1.0.tgz --set image.tag=1.27-alpine --set replicaCount=2
Release "demo" has been upgraded. Happy Helming!
STATUS: deployed
REVISION: 2

$ kubectl -n s15-helm get pods -l app.kubernetes.io/instance=demo
NAME                               READY   STATUS    RESTARTS   AGE
demo-demo-chart-6594d6bf8b-6qp75   1/1     Running   0          13s
demo-demo-chart-6594d6bf8b-rxzd8   1/1     Running   0          1s

$ helm history demo
REVISION	UPDATED                 	STATUS    	CHART           	APP VERSION	DESCRIPTION
1       	Wed Oct  7 23:12:33 2026	superseded	demo-chart-0.1.0	1.16.0     	Install complete
2       	Wed Oct  7 23:12:45 2026	deployed  	demo-chart-0.1.0	1.16.0     	Upgrade complete

$ helm upgrade --install demo ./demo-chart-0.1.0.tgz --set image.tag=1.27-alpine --set replicaCount=2 --reuse-values | head -3
Release "demo" has been upgraded. Happy Helming!
```

## helm rollback

What it does: creates a new revision whose content is a copy of revision N. Nothing is deleted from history.

```text
$ helm rollback demo 1
Rollback was a success! Happy Helming!

$ kubectl -n s15-helm get pods -l app.kubernetes.io/instance=demo
NAME                               READY   STATUS        RESTARTS   AGE
demo-demo-chart-6594d6bf8b-6qp75   1/1     Running       0          14s
demo-demo-chart-6594d6bf8b-rxzd8   1/1     Terminating   0          2s          <- back to 1 replica

$ helm history demo
REVISION	STATUS    	DESCRIPTION
1       	superseded	Install complete
2       	superseded	Upgrade complete
3       	superseded	Upgrade complete
4       	deployed  	Rollback to 1
```

## helm uninstall

What it does: deletes every object the release created and the release Secrets. A second uninstall fails because the release no longer exists.

```text
$ helm uninstall demo
release "demo" uninstalled

$ helm list
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION

$ kubectl -n s15-helm get all
pod/demo-demo-chart-6594d6bf8b-6qp75   1/1     Terminating   0          14s
pod/demo-demo-chart-6594d6bf8b-rxzd8   1/1     Terminating   0          2s

$ helm uninstall demo 2>&1 || true
Error: uninstall: Release not loaded: demo: release: not found
```

## helm install from a repository

What it does: the same `install`, but the chart comes from a repo index (`repo/chart --version`) instead of a local folder. I installed the community node-exporter chart; two overrides were needed because this cluster already runs a node-exporter on host port 9100 of every node (kube-prometheus-stack) and kind nodes do not have a shared `/` mount.

```text
$ helm install metrics prometheus-community/prometheus-node-exporter --version 4.59.0 --set image.tag=v1.12.1-distroless --set hostRootFsMount.enabled=false --set hostNetwork=false
NAME: metrics
LAST DEPLOYED: Wed Oct  7 23:16:57 2026
NAMESPACE: s15-helm
STATUS: deployed
REVISION: 1

$ kubectl -n s15-helm rollout status daemonset/metrics-prometheus-node-exporter --timeout=120s
daemon set "metrics-prometheus-node-exporter" successfully rolled out

$ helm list
NAME   	NAMESPACE	REVISION	STATUS  	CHART                          	APP VERSION
metrics	s15-helm 	1       	deployed	prometheus-node-exporter-4.59.0	1.12.1

$ helm uninstall metrics
release "metrics" uninstalled
```

## Summary table

| Command | Touches the cluster? | What I use it for |
|---|---|---|
| `helm create` | no | scaffold a chart |
| `helm lint` / `helm template` / `helm show` | no | check and preview before installing |
| `helm package` | no | build the `.tgz` to publish |
| `helm repo add/update/list`, `helm search repo/hub` | no (network only) | find and track charts |
| `helm install` / `helm upgrade` / `helm upgrade --install` | yes | create / change a release (new revision each time) |
| `helm list` / `helm status` / `helm get` / `helm history` | read only | inspect releases and revisions |
| `helm rollback` | yes | new revision = copy of an old one |
| `helm uninstall` | yes | remove objects + release Secrets |
