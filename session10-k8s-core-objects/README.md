# Session 10 Homework Question


## Q1. Difference between StatefulSet, Deployment and DaemonSet

- **Deployment:** Used for managing stateless applications where Pods are interchangeable. It supports scaling, rolling updates, and rollbacks.
- **StatefulSet:** Used for stateful applications where Pods need stable identities, stable network names, and persistent storage. Each Pod gets a unique and predictable name.
- **DaemonSet:** Ensures that a copy of a Pod runs on each node, or on selected nodes. It is commonly used for node-level tasks such as logging and monitoring.

---

## Q2. Difference between Deployment and ReplicaSet

- **Deployment:** A higher-level Kubernetes object that manages ReplicaSets and provides features such as rolling updates and rollbacks.
- **ReplicaSet:** Ensures that a specified number of identical Pods are running at all times.
- A **Deployment creates and manages ReplicaSets**, while a ReplicaSet mainly focuses on maintaining the desired number of Pods.

---

## Q3. Difference between Deployment and Deployment Strategy

- **Deployment:** Defines and manages the desired state of an application, including the container image, number of replicas, and Pod configuration.
- **Deployment Strategy:** Defines how Kubernetes replaces the old Pods with new Pods when the Deployment is updated.
- Common strategies include **RollingUpdate**, which gradually replaces Pods, and **Recreate**, which removes the old Pods before creating the new ones.