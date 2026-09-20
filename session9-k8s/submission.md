## Author: Piyush Kumar Mahato
## Session: 09 - Kubernetes Fundamentals
## Repository: devops-heros / session9-k8s

![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)

```
+-------------------------------------------------------------------------------+
|                               CONTROL PLANE (MASTER)                          |
|                                                                               |
|   +-------------------+       +--------------------+       +--------------+   |
|   |       etcd        |<----->|  kube-apiserver    |<----->|kube-scheduler|   |
|   | (State Database)  |       |    (Front Door)    |       +--------------+   |
|   +-------------------+       +---------+----------+                          |
|                                         |                                     |
|                                         v                                     |
|                             +------------------------+                        |
|                             | kube-controller-manager|                        |
|                             +------------------------+                        |
+-----------------------------------------+-------------------------------------+
                                          |
                        +-----------------+-----------------+
                        |                                   |
                        v                                   v
+------------------------------------+ +------------------------------------+
|          WORKER NODE 1             | |          WORKER NODE 2             |
|                                    | |                                    |
|   +------------+  +------------+   | |   +------------+  +------------+   |
|   |  kubelet   |  | kube-proxy |   | |   |  kubelet   |  | kube-proxy |   |
|   +-----+------+  +-----+------+   | |   +-----+------+  +-----+------+   |
|         |               |          | |         |               |          |
|         v               v          | |         v               v          |
|   +----------------------------+   | |   +----------------------------+   |
|   | CRI (containerd runtime)   |   | |   | CRI (containerd runtime)   |   |
|   +----------------------------+   | |   +----------------------------+   |
|         |                          | |         |                          |
|         v                          | |         v                          |
|   +------------+  +------------+   | |   +------------+  +------------+   |
|   |   Pod 1    |  |   Pod 2    |   | |   |   Pod 3    |  |   Pod 4    |   |
|   | [Container]|  | [Container]|   | |   | [Container]|  | [Container]|   |
|   +------------+  +------------+   | |   +------------+  +------------+   |
+------------------------------------+ +------------------------------------+
```

Kubernetes architecture consists mainly of two parts: the **Control Plane** and the **Worker Nodes**. The Control Plane is basically the main part of Kubernetes which manages and controls the whole cluster. It has components like **API Server, etcd, Scheduler and Controller Manager**. The API Server is used for communication between the user and Kubernetes. etcd is the database where Kubernetes stores information about the cluster and its current state. The Scheduler decides on which Worker Node a Pod should run. The Controller Manager keeps checking whether the actual situation is matching with what the user has requested. For example, if the user wants 3 Pods but one Pod crashes, the Controller Manager makes sure that another Pod is created.

The **Worker Nodes** are the machines where the actual application containers run. Each Worker Node mainly has **Kubelet, kube-proxy, Container Runtime and Pods**. Kubelet is an agent which manages the Pods on that particular node and communicates with the Control Plane. The Container Runtime is responsible for actually running the containers. kube-proxy mainly helps in handling network communication and sending traffic to the correct Pod. A **Pod** is the smallest unit in Kubernetes and usually contains one or more containers. Users normally use **kubectl** to give commands to Kubernetes, such as creating Pods, checking nodes or deploying applications.

In simple terms, the working is like this: the user gives a command using kubectl, which goes to the API Server. The required information is stored in etcd, the Scheduler decides where the Pod should run, and the Kubelet on that Worker Node starts the container using the Container Runtime. Kubernetes keeps checking the system and tries to maintain the required state. If something fails, such as a Pod crashing, Kubernetes can automatically create a new one. So, the main purpose of Kubernetes architecture is to **manage containers, run applications, handle networking, scale applications and automatically recover from failures**.
