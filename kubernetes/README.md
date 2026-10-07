# Session 9: Kubernetes Fundamentals

**Name:** Tejas Varshney  
**Environment:** Windows 11, Docker Desktop 28.5.1, minikube v1.39.0 (docker driver), Kubernetes v1.37.0, kubectl v1.34.1

All outputs below were captured from my own minikube cluster.

---

## Task 1 – Install and configure Minikube

```powershell
winget install Kubernetes.minikube
winget install Kubernetes.kubectl          # (kubectl also ships with Docker Desktop)
minikube start --driver=docker --cpus=4 --memory=6144
minikube addons enable metrics-server
minikube addons enable ingress
```

`minikube start` creates a single Docker container that acts as one Kubernetes node (control plane + worker), downloads the Kubernetes binaries, and writes the `minikube` context into `~/.kube/config`.

## Task 2 – Verify cluster status

```text
$ minikube version
minikube version: v1.39.0
commit: 7a9f6a841470a207de8cf4bafcccee0969d8ba10

$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured


$ kubectl version
Client Version: v1.34.1
Kustomize Version: v5.7.1
Server Version: v1.37.0
Warning: version difference between client (1.34) and server (1.37) exceeds the supported minor version skew of +/-1

$ kubectl cluster-info
Kubernetes control plane is running at https://127.0.0.1:42231
CoreDNS is running at https://127.0.0.1:42231/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

$ kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION                             CONTAINER-RUNTIME
minikube   Ready    control-plane   3m14s   v1.37.0   192.168.49.2   <none>        Debian GNU/Linux 12 (bookworm)   6.6.87.2-microsoft-standard-WSL2 (amd64)   containerd://2.3.4

$ kubectl get pods -n kube-system -o wide
NAME                               READY   STATUS    RESTARTS   AGE     IP             NODE       NOMINATED NODE   READINESS GATES
coredns-559f6c778d-5jmmm           1/1     Running   0          3m5s    10.244.0.2     minikube   <none>           <none>
etcd-minikube                      1/1     Running   0          3m11s   192.168.49.2   minikube   <none>           <none>
kindnet-48kkl                      1/1     Running   0          3m5s    192.168.49.2   minikube   <none>           <none>
kube-apiserver-minikube            1/1     Running   0          3m13s   192.168.49.2   minikube   <none>           <none>
kube-controller-manager-minikube   1/1     Running   0          3m11s   192.168.49.2   minikube   <none>           <none>
kube-proxy-2255r                   1/1     Running   0          3m5s    192.168.49.2   minikube   <none>           <none>
kube-scheduler-minikube            1/1     Running   0          3m11s   192.168.49.2   minikube   <none>           <none>
metrics-server-768f9f6999-cs6xl    1/1     Running   0          74s     10.244.0.4     minikube   <none>           <none>
storage-provisioner                1/1     Running   0          3m10s   192.168.49.2   minikube   <none>           <none>

$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   3m14s
ingress-nginx     Active   73s
kube-node-lease   Active   3m14s
kube-public       Active   3m14s
kube-system       Active   3m14s

$ kubectl api-resources | head -25
NAME                                SHORTNAMES   APIVERSION                        NAMESPACED   KIND
bindings                                         v1                                true         Binding
componentstatuses                   cs           v1                                false        ComponentStatus
configmaps                          cm           v1                                true         ConfigMap
endpoints                           ep           v1                                true         Endpoints
events                              ev           v1                                true         Event
limitranges                         limits       v1                                true         LimitRange
namespaces                          ns           v1                                false        Namespace
nodes                               no           v1                                false        Node
persistentvolumeclaims              pvc          v1                                true         PersistentVolumeClaim
persistentvolumes                   pv           v1                                false        PersistentVolume
pods                                po           v1                                true         Pod
podtemplates                                     v1                                true         PodTemplate
replicationcontrollers              rc           v1                                true         ReplicationController
resourcequotas                      quota        v1                                true         ResourceQuota
secrets                                          v1                                true         Secret
serviceaccounts                     sa           v1                                true         ServiceAccount
services                            svc          v1                                true         Service
mutatingadmissionpolicies                        admissionregistration.k8s.io/v1   false        MutatingAdmissionPolicy
mutatingadmissionpolicybindings                  admissionregistration.k8s.io/v1   false        MutatingAdmissionPolicyBinding
mutatingwebhookconfigurations                    admissionregistration.k8s.io/v1   false        MutatingWebhookConfiguration
validatingadmissionpolicies                      admissionregistration.k8s.io/v1   false        ValidatingAdmissionPolicy
validatingadmissionpolicybindings                admissionregistration.k8s.io/v1   false        ValidatingAdmissionPolicyBinding
validatingwebhookconfigurations                  admissionregistration.k8s.io/v1   false        ValidatingWebhookConfiguration
customresourcedefinitions           crd,crds     apiextensions.k8s.io/v1           false        CustomResourceDefinition

```

What I noticed:
- The single node `minikube` is `Ready` and runs **containerd** as its container runtime.
- Every control-plane component (`etcd`, `kube-apiserver`, `kube-scheduler`, `kube-controller-manager`) runs as a **static Pod** in `kube-system`, using the node's IP (`192.168.49.2`).
- `coredns` and `metrics-server` get Pod IPs from the Pod CIDR (`10.244.0.0/16`).
- kubectl warns that client 1.34 vs. server 1.37 is outside the supported ±1 version skew. Everything I used still worked, but `minikube kubectl --` gives a matching client.

## Task 3 – Kubernetes architecture (notes)

```
                     +---------------------- Control Plane ----------------------+
   kubectl  ------>  |  kube-apiserver  <----->  etcd (cluster state, key-value)  |
   (REST/HTTPS)      |        ^                                                   |
                     |        |  watch / update                                   |
                     |  kube-scheduler        kube-controller-manager    (CCM)    |
                     +--------|-------------------------------------------------- +
                              |
            +-----------------+------------------+
            |                                    |
   +------ Worker Node ------+         +------ Worker Node ------+
   | kubelet  (node agent)   |         | kubelet                 |
   | kube-proxy (Service     |         | kube-proxy              |
   |   rules: iptables/IPVS) |         | containerd              |
   | containerd (runtime)    |         |  [Pod] [Pod] [Pod]      |
   |  [Pod] [Pod]            |         +-------------------------+
   +-------------------------+
```

| Component | Where | What it does |
|---|---|---|
| **kube-apiserver** | Control plane | The only component that talks to etcd. All clients (kubectl, controllers, kubelets) read and write cluster state through its REST API. It also handles authentication, authorization (RBAC) and admission control. |
| **etcd** | Control plane | Consistent, distributed key-value store that holds the desired and current state of every object. Back it up and you can rebuild the cluster. |
| **kube-scheduler** | Control plane | Watches for Pods with no `nodeName` and picks a node, filtering on resources, taints/tolerations and affinity, then scoring the candidates. |
| **kube-controller-manager** | Control plane | Runs the reconciliation loops (Deployment, ReplicaSet, Node, Job, EndpointSlice, ServiceAccount…). Each loop compares desired state with actual state and acts. |
| **cloud-controller-manager** | Control plane (cloud only) | Creates cloud load balancers and routes, and manages node lifecycle on AWS/GCP/Azure. |
| **kubelet** | Every node | Registers the node, receives PodSpecs, asks the runtime (via CRI) to start containers, runs probes and reports status. |
| **kube-proxy** | Every node | Programs iptables/IPVS so a Service's virtual IP load-balances to its Pod endpoints. |
| **Container runtime** | Every node | containerd / CRI-O pulls images and runs the containers. |
| **CoreDNS** | Add-on (Pods) | Cluster DNS: `my-svc.my-ns.svc.cluster.local` → ClusterIP. |

**What happens on `kubectl create deployment`:**
1. kubectl sends the Deployment to the **API server**, which validates it and stores it in **etcd**.
2. The **Deployment controller** sees the new Deployment and creates a **ReplicaSet**.
3. The **ReplicaSet controller** creates the required number of **Pod** objects (still with no node).
4. The **scheduler** assigns each Pod to a node.
5. That node's **kubelet** sees the Pod and tells **containerd** to pull the image and start the container.
6. kubelet reports the Pod as `Running` back to the API server.

Kubernetes is **declarative and self-healing**: you describe the desired state, and controllers keep moving the actual state towards it.

## Task 4 – Basic objects and commands

| Object | Purpose |
|---|---|
| **Pod** | Smallest deployable unit: one or more containers sharing a network namespace (one IP) and volumes. |
| **ReplicaSet** | Keeps N identical Pods running (selector + template). |
| **Deployment** | Manages ReplicaSets, giving rolling updates, rollback and scaling. |
| **Service** | Stable virtual IP and DNS name that load-balances to Pods matched by labels. |
| **Namespace** | Logical partition of the cluster (names, RBAC, quotas). |
| **Label / Selector** | Key-value tags; how Services and ReplicaSets find their Pods. |
| **ConfigMap / Secret** | Configuration and sensitive data injected into Pods. |

| Command | Use |
|---|---|
| `kubectl get <resource> [-o wide\|yaml]` | List resources |
| `kubectl describe <resource> <name>` | Detailed state and events |
| `kubectl logs <pod> [-f] [-c container]` | Container logs |
| `kubectl exec -it <pod> -- sh` | Shell inside a container |
| `kubectl apply -f file.yaml` | Declarative create/update |
| `kubectl create deployment / expose / scale` | Imperative helpers |
| `kubectl set image` + `kubectl rollout status/undo/history` | Updates and rollbacks |
| `kubectl delete <resource> <name>` | Remove |

## Task 5 – Kubernetes Basics tutorial (hands-on)

I went through every module of the official [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/) tutorial on my minikube cluster:

```text
### Module 2 - Deploy an app
$ kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
deployment.apps/kubernetes-bootcamp created

$ kubectl get deployments
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           25s

### Module 3 - Explore the app
$ kubectl get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-5cc66bcc9b-zhx94   1/1     Running   0          24s   10.244.0.8   minikube   <none>           <none>

$ kubectl describe pod kubernetes-bootcamp-5cc66bcc9b-zhx94 | sed -n '1,25p'
Name:             kubernetes-bootcamp-5cc66bcc9b-zhx94
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Thu, 08 Oct 2026 00:13:14 +0530
Labels:           app=kubernetes-bootcamp
                  pod-template-hash=5cc66bcc9b
Annotations:      <none>
Status:           Running
IP:               10.244.0.8
IPs:
  IP:           10.244.0.8
Controlled By:  ReplicaSet/kubernetes-bootcamp-5cc66bcc9b
Containers:
  kubernetes-bootcamp:
    Container ID:   containerd://addd190cdf4677a04f2ca80009f1a2cc93a3a14de4fb86c4b55da43518bb7cb3
    Image:          gcr.io/google-samples/kubernetes-bootcamp:v1
    Image ID:       gcr.io/google-samples/kubernetes-bootcamp@sha256:0d6b8ee63bb57c5f5b6156f446b3bc3b3c143d233037f3a2f00e279c8fcc64af
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Thu, 08 Oct 2026 00:13:38 +0530
    Ready:          True
    Restart Count:  0

$ kubectl logs kubernetes-bootcamp-5cc66bcc9b-zhx94
Kubernetes Bootcamp App Started At: 2026-10-07T18:43:38.280Z | Running On:  kubernetes-bootcamp-5cc66bcc9b-zhx94 


$ kubectl exec kubernetes-bootcamp-5cc66bcc9b-zhx94 -- env | grep -E 'HOSTNAME|KUBERNETES_SERVICE'
HOSTNAME=kubernetes-bootcamp-5cc66bcc9b-zhx94
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443

$ kubectl exec kubernetes-bootcamp-5cc66bcc9b-zhx94 -- curl -s http://localhost:8080
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-zhx94 | v=1

### Module 4 - Expose the app
$ kubectl expose deployment/kubernetes-bootcamp --type=NodePort --port 8080
service/kubernetes-bootcamp exposed

$ kubectl get services
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes            ClusterIP   10.96.0.1       <none>        443/TCP          3m54s
kubernetes-bootcamp   NodePort    10.111.74.129   <none>        8080:32595/TCP   1s

$ kubectl describe services/kubernetes-bootcamp
Name:                     kubernetes-bootcamp
Namespace:                default
Labels:                   app=kubernetes-bootcamp
Annotations:              <none>
Selector:                 app=kubernetes-bootcamp
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.111.74.129
IPs:                      10.111.74.129
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  32595/TCP
Endpoints:                10.244.0.8:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

$ minikube ssh -- curl -s http://192.168.49.2:32595
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-zhx94 | v=1

$ kubectl get pods -l app=kubernetes-bootcamp --show-labels
NAME                                   READY   STATUS    RESTARTS   AGE   LABELS
kubernetes-bootcamp-5cc66bcc9b-zhx94   1/1     Running   0          27s   app=kubernetes-bootcamp,pod-template-hash=5cc66bcc9b

$ kubectl label pods kubernetes-bootcamp-5cc66bcc9b-zhx94 version=v1
pod/kubernetes-bootcamp-5cc66bcc9b-zhx94 labeled

$ kubectl get pods -l version=v1
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-5cc66bcc9b-zhx94   1/1     Running   0          28s

### Module 5 - Scale the app
$ kubectl scale deployments/kubernetes-bootcamp --replicas=4
deployment.apps/kubernetes-bootcamp scaled

$ kubectl get deployments
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   4/4     4            4           30s

$ kubectl get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-5cc66bcc9b-2pq2h   1/1     Running   0          1s    10.244.0.9    minikube   <none>           <none>
kubernetes-bootcamp-5cc66bcc9b-hpj7p   1/1     Running   0          1s    10.244.0.11   minikube   <none>           <none>
kubernetes-bootcamp-5cc66bcc9b-jbjtk   1/1     Running   0          1s    10.244.0.10   minikube   <none>           <none>
kubernetes-bootcamp-5cc66bcc9b-zhx94   1/1     Running   0          29s   10.244.0.8    minikube   <none>           <none>

$ kubectl get rs
NAME                             DESIRED   CURRENT   READY   AGE
kubernetes-bootcamp-5cc66bcc9b   4         4         4       30s

$ for i in 1 2 3 4 5 6; do minikube ssh -- curl -s http://192.168.49.2:32595; done
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-jbjtk | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-2pq2h | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-hpj7p | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-2pq2h | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-jbjtk | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-2pq2h | v=1

### Module 6 - Update the app
$ kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=docker.io/jocatalin/kubernetes-bootcamp:v2
deployment.apps/kubernetes-bootcamp image updated

$ kubectl rollout status deployments/kubernetes-bootcamp --timeout=300s
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 of 4 updated replicas are available...
deployment "kubernetes-bootcamp" successfully rolled out

$ kubectl get pods
NAME                                   READY   STATUS        RESTARTS   AGE
kubernetes-bootcamp-5b97597885-5sm6p   1/1     Running       0          13s
kubernetes-bootcamp-5b97597885-f6nqc   1/1     Running       0          13s
kubernetes-bootcamp-5b97597885-jzmjf   1/1     Running       0          1s
kubernetes-bootcamp-5b97597885-xm7t8   1/1     Running       0          1s
kubernetes-bootcamp-5cc66bcc9b-2pq2h   1/1     Terminating   0          18s
kubernetes-bootcamp-5cc66bcc9b-hpj7p   1/1     Terminating   0          18s
kubernetes-bootcamp-5cc66bcc9b-jbjtk   1/1     Terminating   0          18s
kubernetes-bootcamp-5cc66bcc9b-zhx94   1/1     Terminating   0          46s

$ minikube ssh -- curl -s http://192.168.49.2:32595
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5b97597885-jzmjf | v=2

$ kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v10
deployment.apps/kubernetes-bootcamp image updated

$ kubectl get pods
NAME                                   READY   STATUS             RESTARTS   AGE
kubernetes-bootcamp-556487b4d4-4w4jz   0/1     ImagePullBackOff   0          30s
kubernetes-bootcamp-556487b4d4-v8xbn   0/1     ErrImagePull       0          30s
kubernetes-bootcamp-5b97597885-5sm6p   1/1     Running            0          44s
kubernetes-bootcamp-5b97597885-f6nqc   1/1     Running            0          44s
kubernetes-bootcamp-5b97597885-jzmjf   0/1     Error              0          32s
kubernetes-bootcamp-5b97597885-xm7t8   1/1     Running            0          32s

$ kubectl rollout undo deployments/kubernetes-bootcamp
deployment.apps/kubernetes-bootcamp rolled back

$ kubectl rollout status deployments/kubernetes-bootcamp --timeout=300s
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 of 4 updated replicas are available...
deployment "kubernetes-bootcamp" successfully rolled out

$ kubectl rollout history deployments/kubernetes-bootcamp
deployment.apps/kubernetes-bootcamp 
REVISION  CHANGE-CAUSE
1         <none>
3         <none>
4         <none>


$ kubectl describe pods | grep Image:
    Image:          docker.io/jocatalin/kubernetes-bootcamp:v2
    Image:          docker.io/jocatalin/kubernetes-bootcamp:v2
    Image:          docker.io/jocatalin/kubernetes-bootcamp:v2
    Image:          docker.io/jocatalin/kubernetes-bootcamp:v2

### Cleanup
$ kubectl delete service kubernetes-bootcamp
service "kubernetes-bootcamp" deleted from default namespace

$ kubectl delete deployment kubernetes-bootcamp
deployment.apps "kubernetes-bootcamp" deleted from default namespace

```

### Observations
- **Deploy:** `kubectl create deployment` created a Deployment → ReplicaSet (`5cc66bcc9b`) → Pod chain. The Pod name ends with the ReplicaSet hash plus a random suffix.
- **Explore:** `describe` shows `Controlled By: ReplicaSet/...`, which proves the ownership chain. `exec` ran `curl localhost:8080` inside the container.
- **Expose:** the NodePort Service got ClusterIP `10.111.74.129` and NodePort `32595`. Its single endpoint `10.244.0.8:8080` is the Pod IP.
- **Labels:** I added `version=v1` to a Pod and then filtered with `-l version=v1`.
- **Scale:** after `--replicas=4` the ReplicaSet DESIRED became 4, and repeated curls were answered by different Pods (`jbjtk`, `2pq2h`, `hpj7p`). That is the Service load-balancing.
- **Rolling update:** to v2, new Pods (`5b97597885`) came up while old ones terminated, so the app stayed available, and curl then returned `v=2`.
- **Bad update + rollback:** image `v10` does not exist, so the new Pods went `ErrImagePull` → `ImagePullBackOff`. Because of the rolling-update strategy, 3 old v2 Pods kept serving traffic. `kubectl rollout undo` returned every Pod to the v2 image (revision 4 in `rollout history`).

## Resources
- https://kubernetes.io/docs/tutorials/kubernetes-basics/
- https://minikube.sigs.k8s.io/docs/start/
- https://kubernetes.io/docs/concepts/architecture/
- https://github.com/Nency-Ravaliya/Kubernetes
