# Session 9 – Kubernetes Fundamentals

**Name:** Sourabh Srivastva
**Enrollment Number:** 24BCS10157

---

## Setup

I set up a local Kubernetes cluster using Minikube with Docker as the driver and tried some basic `kubectl` commands for checking the cluster, nodes, namespaces, and pods.

```bash
minikube start --driver=docker
```

## 1. Cluster Information

```bash
$ kubectl version

Client Version: v1.34.1
Server Version: v1.37.0

$ kubectl cluster-info

Kubernetes control plane is running at https://127.0.0.1:65085
CoreDNS is running at https://127.0.0.1:65085/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

$ kubectl get nodes -o wide

NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    OS-IMAGE                  CONTAINER-RUNTIME
minikube   Ready    control-plane   9d    v1.37.0   192.168.49.2   Debian GNU/Linux 12      containerd://2.3.4
```

The Minikube cluster has one node, `minikube`, which is currently acting as the control-plane node and also runs workloads. A production cluster can have multiple nodes.

## 2. Namespaces

```bash
$ kubectl get namespaces

NAME              STATUS   AGE
default           Active   9d
kube-node-lease   Active   9d
kube-public       Active   9d
kube-system       Active   9d
```

The `default` namespace is used when no namespace is specified. The `kube-system` namespace contains Kubernetes system components and other cluster-level services.

## 3. Kubernetes Components

I checked the pods running in the `kube-system` namespace:

```bash
$ kubectl get pods -n kube-system -o wide

NAME                               READY   STATUS    RESTARTS      AGE   IP             NODE
coredns-559f6c778d-nfz4x           1/1     Running   1 (19m ago)   9d    10.244.0.2     minikube
etcd-minikube                      1/1     Running   1 (19m ago)   9d    192.168.49.2   minikube
kindnet-szr9v                      1/1     Running   1 (19m ago)   9d    192.168.49.2   minikube
kube-apiserver-minikube            1/1     Running   1 (19m ago)   9d    192.168.49.2   minikube
kube-controller-manager-minikube   1/1     Running   1 (19m ago)   9d    192.168.49.2   minikube
kube-proxy-vnlzq                   1/1     Running   1 (19m ago)   9d    192.168.49.2   minikube
kube-scheduler-minikube             1/1     Running   1 (19m ago)   9d    192.168.49.2   minikube
storage-provisioner                 1/1     Running   2 (19m ago)   9d    192.168.49.2   minikube
```

Seeing the Kubernetes components as actual running workloads made the architecture easier to understand.

* `kube-apiserver` – handles requests from `kubectl` and other clients.
* `etcd` – stores the cluster's state.
* `kube-scheduler` – decides which node should run newly created pods.
* `kube-controller-manager` – runs controllers that work to keep the actual state close to the desired state.
* `kubelet` – runs on each node and manages containers for pods. It is not itself a Kubernetes pod.
* `kube-proxy` – handles networking rules used by Kubernetes Services.
* `coredns` – provides DNS resolution inside the cluster.

## 4. Node Capacity and API Resources

```bash
$ kubectl describe node minikube | sed -n '/^Capacity/,/^System Info/p'

Capacity:
  cpu:                28
  memory:             7977660Ki
  pods:               110

Allocatable:
  cpu:                28
  memory:             7977660Ki
  pods:               110
```

The `Allocatable` values show the resources that Kubernetes can assign to workloads on the node. In this setup, the node has a pod limit of 110.

I also checked the available API resources:

```bash
$ kubectl api-resources | head -12

NAME             SHORTNAMES   APIVERSION   NAMESPACED   KIND
configmaps       cm           v1           true         ConfigMap
endpoints        ep           v1           true         Endpoints
namespaces       ns           v1           false        Namespace
nodes            no           v1           false        Node
pods             po           v1           true         Pod
```

This command is useful for seeing the resource types supported by the cluster and their short names. For example, `po` can be used instead of `pods`:

```bash
kubectl get po
```

## 5. Creating and Inspecting a Pod

I tried creating my first pod using an Nginx image:

```bash
$ kubectl run my-first-pod --image=nginx:1.25-alpine

Error from server (AlreadyExists): pods "my-first-pod" already exists
```

The error occurred because I had already created the pod during an earlier attempt. After checking the existing pod:

```bash
$ kubectl get pods -o wide

NAME           READY   STATUS    RESTARTS   AGE     IP           NODE
my-first-pod   1/1     Running   0          2m35s   10.244.0.54   minikube
```

The pod was already running successfully.

I then used `describe` to inspect it in more detail:

```bash
$ kubectl describe pod my-first-pod

Name:        my-first-pod
Namespace:   default
Node:        minikube/192.168.49.2
Status:      Running
IP:          10.244.0.54

Containers:
  my-first-pod:
    Image:          nginx:1.25-alpine
    State:          Running
    Ready:          True
    Restart Count:  0

Conditions:
  Type                       Status
  PodReadyToStartContainers  True
  Initialized                True
  Ready                      True
  ContainersReady            True
  PodScheduled               True

QoS Class:  BestEffort

Events:
  Type    Reason    Age      From               Message
  ----    ------    ---      ----               -------
  Normal  Scheduled 2m45s    default-scheduler  Successfully assigned default/my-first-pod to minikube
  Normal  Pulled    2m45s    kubelet            Container image "nginx:1.25-alpine" already present on machine and can be accessed by the pod
  Normal  Created   2m45s    kubelet            Container created
  Normal  Started   2m45s    kubelet            Container started
```

The Events section shows the sequence of what happened to the pod: it was scheduled to the node, the image was found, and then the container was created and started.

The image was already present on the Minikube machine, so Kubernetes did not need to download it again. This also explained why the pod started quickly.

The Conditions section also showed that the pod passed all the main stages and reached the `Ready` state.

Finally, I deleted the pod:

```bash
$ kubectl delete pod my-first-pod

pod "my-first-pod" deleted from default namespace
```

## What I Learned

This session helped me understand Kubernetes as a declarative system. Instead of manually starting a container on a particular node, I specify the desired workload and Kubernetes components work together to run it.

I also understood the roles of the API server, scheduler, controllers, kubelet, networking components, and `etcd` more clearly after seeing them in the running Minikube cluster.

One useful command I learned was `kubectl describe`. Unlike `kubectl get`, it provides detailed information about a resource, including its conditions and Events, which can be useful when troubleshooting a pod.
