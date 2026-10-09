# Session 10 - Kubernetes Pods, ReplicaSets & Deployments

**Name:** Sourabh Srivastva
**Enrollment Number:** 24BCS10157

## 1. Core Objects

I worked with the main Kubernetes workload objects: Pod, ReplicaSet, Deployment, DaemonSet, and StatefulSet.

```bash
kubectl apply -f k8s-core-objects/pod.yml
kubectl apply -f k8s-core-objects/replicaset.yml
kubectl apply -f k8s-core-objects/deployment.yml
kubectl apply -f k8s-core-objects/deamonset.yml
kubectl apply -f k8s-core-objects/statefulset.yml
```

I then checked the created resources:

```text
$ kubectl get pod mypod
NAME    READY   STATUS              RESTARTS   AGE
mypod   0/2     ContainerCreating   0          15s

$ kubectl get rs myapp-rs
NAME       DESIRED   CURRENT   READY   AGE
myapp-rs   3         3         3       15s

$ kubectl get deploy myapp
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
myapp   3/3     3            3           15s

$ kubectl get ds node-exporter
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-exporter   1         1         1       1            1           <none>          14s

$ kubectl get sts mysql
NAME    READY   AGE
mysql   3/3     14s

$ kubectl get pods -l app=mysql
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   1/1     Running   0          15s
mysql-1   1/1     Running   0          15s
mysql-2   1/1     Running   0          14s
```

I ran the first command shortly after applying the YAML, so `mypod` was still in `ContainerCreating`. It has two containers, so it becomes `2/2` only after both containers are ready.

The DaemonSet has `DESIRED 1` because my Minikube cluster has only one node. A DaemonSet normally maintains one copy of a pod on each node.

The StatefulSet pods have predictable names such as `mysql-0`, `mysql-1`, and `mysql-2`, unlike the generated names used by Deployment pods. They are also started in order, which is useful for stateful applications.

## 2. Deployment vs ReplicaSet

```text
$ kubectl get pods --show-labels
NAME                     READY   STATUS    AGE   LABELS
myapp-5b9587f95d-hgrlz   1/1     Running   41s   app=myapp,pod-template-hash=5b9587f95d
myapp-5b9587f95d-shqm8   1/1     Running   41s   app=myapp,pod-template-hash=5b9587f95d
myapp-5b9587f95d-x9npt   1/1     Running   41s   app=myapp,pod-template-hash=5b9587f95d
myapp-rs-5dbp2           1/1     Running   41s   app=web
myapp-rs-l2zzn           1/1     Running   41s   app=web
myapp-rs-s9z8t           1/1     Running   41s   app=web
```

I created one Deployment and one ReplicaSet, but there were two ReplicaSets visible. The Deployment creates and manages a ReplicaSet, which in turn manages the pods.

The `pod-template-hash` label helps the Deployment distinguish pods belonging to different versions.

The relationship is:

**Deployment → ReplicaSet → Pods**

This structure is also what allows Deployments to perform rolling updates.

## 3. Pod Lifecycle

I created pods to observe different lifecycle and error states:

```text
$ kubectl get pod lifecycle-crashloop lifecycle-image-error lifecycle-init lifecycle-multi-container

NAME                        READY   STATUS         RESTARTS      AGE
lifecycle-crashloop        1/1     Running        4 (59s ago)   111s
lifecycle-image-error      0/1     ErrImagePull    0             111s
lifecycle-init              1/1     Running        0             111s
lifecycle-multi-container   2/2     Running        0             110s
```

### CrashLoopBackOff

The crashloop pod repeatedly starts and crashes. When I checked it, it was temporarily in `Running` but had already restarted four times.

To see why the previous container stopped:

```text
$ kubectl logs lifecycle-crashloop --previous --tail=5
Application started
Application crashed
```

The `--previous` option was useful because the current container had already restarted.

### ErrImagePull / ImagePullBackOff

The image-error pod could not download its image:

```text
$ kubectl describe pod lifecycle-image-error | Select-Object -Last 8

Type     Reason     Age                  From               Message
----     ------     ---                  ----               -------
Normal   Scheduled  111s                 default-scheduler  Successfully assigned default/lifecycle-image-error to minikube
Normal   Pulling    18s (x4 over 110s)   kubelet            Pulling image "jakwehrgkaejw:kahsdfgkhj"
Warning  Failed     17s (x4 over 109s)   kubelet            Failed to pull image "jakwehrgkaejw:kahsdfgkhj":
                                                            pull access denied, repository does not exist or may require authorization
Warning  Failed     17s (x4 over 109s)   kubelet            Error: ErrImagePull
Normal   BackOff    5s (x6 over 109s)    kubelet            Back-off pulling image "jakwehrgkaejw:kahsdfgkhj"
Warning  Failed     5s (x6 over 109s)    kubelet            Error: ImagePullBackOff
```

`ErrImagePull` means the image pull failed, while `ImagePullBackOff` means Kubernetes is waiting before trying again. In this case, the image name was invalid or inaccessible.

Since I am using PowerShell, I used `Select-Object -Last 8` instead of `tail -8`.

### Init Containers

Init containers complete before the main containers are started.

```text
$ kubectl logs lifecycle-init -c setup
Init container running
Init complete
```

An init container can be used for tasks such as waiting for another service or preparing configuration before the main application starts.

### Multi-container Pod

The multi-container pod showed `2/2`, meaning both containers were running. To access the logs of a particular container, I used `-c`:

```text
$ kubectl logs lifecycle-multi-container -c sidecar --tail=4
Sidecar is running
```

## 4. Rolling Update and Rollback

I started with version 1 using `nginx:1.24-alpine` and then updated the Deployment to version 2 using `nginx:1.25-alpine`.

```text
$ kubectl apply -f 01-rolling-update/deployment-v2.yaml
deployment.apps/app-rolling configured

$ kubectl rollout status deployment/app-rolling
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
deployment "app-rolling" successfully rolled out
```

I then checked the pods:

```text
$ kubectl get pods -l app=app-rolling --show-labels

NAME                           READY   STATUS        RESTARTS   AGE   LABELS
app-rolling-56bff6d88c-6m7f5   1/1     Running       0          12s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-7947s   1/1     Running       0          6s    app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-8qxds   1/1     Running       0          25s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-gttnt   1/1     Running       0          19s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-86d7d44d5b-2lv6j   1/1     Terminating   0          43s   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
```

The new pods were created gradually instead of replacing all the old pods at once. The YAML uses `maxSurge: 1` and `maxUnavailable: 0`, so Kubernetes creates a new pod and waits for it to become ready before terminating an old one.

I then tested a rollback:

```text
$ kubectl rollout undo deployment/app-rolling
deployment.apps/app-rolling rolled back
```

Immediately after the rollback, the new v1 pod was still being created while the v2 pods were running:

```text
$ kubectl get pods -l app=app-rolling --show-labels

NAME                           READY   STATUS              RESTARTS   AGE   LABELS
app-rolling-56bff6d88c-6m7f5   1/1     Running             0          12s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-7947s   1/1     Running             0          6s    app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-8qxds   1/1     Running             0          25s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-gttnt   1/1     Running             0          19s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-86d7d44d5b-2lv6j   0/1     Completed           0          43s   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
app-rolling-86d7d44d5b-zrjpb   0/1     ContainerCreating   0          0s    app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
```

The important part was that the v1 pod used the same `pod-template-hash` as the original v1 pods. The old ReplicaSet was retained with zero replicas, so the rollback could use it again.

## What I Learned

The main relationship I learned was:

**Deployment → ReplicaSet → Pod**

A Deployment manages ReplicaSets, while ReplicaSets make sure the required number of pods are running.

I also learned the difference between several pod failure states. A `CrashLoopBackOff` is related to a container repeatedly failing, while `ErrImagePull` and `ImagePullBackOff` indicate problems pulling the container image.

Using `kubectl logs --previous` was particularly useful for checking why a container from an earlier restart had failed.

Finally, rolling updates allow a Deployment to replace pods gradually, while `kubectl rollout undo` can switch back to the previous ReplicaSet.
