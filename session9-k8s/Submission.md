# Kubernetes Notes

## Deployment

* Designed for running stateless applications.
* Makes sure the desired number of Pods are always available.
* Supports rolling updates as well as rollbacks.
* Example: Web applications and APIs.

## ReplicaSet

* Ensures that a specific number of identical Pod replicas are running.
* Automatically replaces Pods if they fail or are removed.
* Typically created and managed by a Deployment.
* Example: Maintaining 3 replicas of an application Pod.

## DaemonSet

* Ensures that one Pod runs on each node in the cluster.
* Automatically schedules the Pod on newly added nodes.
* Useful for services that need to run at the node level.
* Example: Log collection and monitoring agents.

## StatefulSet

* Intended for applications that require persistent or stateful data.
* Provides Pods with stable identities, names, and storage.
* Pods are generally created and terminated in a defined order.
* Example: MySQL, PostgreSQL, and MongoDB.

## Quick Difference

| Resource    | Purpose                                                                    |
| ----------- | -------------------------------------------------------------------------- |
| Deployment  | Manage and deploy stateless applications                                   |
| ReplicaSet  | Maintain a desired number of Pod replicas                                  |
| DaemonSet   | Run one Pod on each node                                                   |
| StatefulSet | Manage stateful applications with persistent storage and stable identities |
