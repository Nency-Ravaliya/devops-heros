# Session 13 — Volumes, HPA, and probes

**Name:** Viraj Bhanage
**Roll number:** 24BCS10274

`emptyDir` lasts as long as the Pod. `hostPath` is a directory on one node, so the Pod is stuck on that node. A PersistentVolume is the disk. A PersistentVolumeClaim is the request. A StorageClass creates the disk when the claim is created.

My HPA file is `homework/session-13-storage/hpa.yaml`. It runs `registry.k8s.io/hpa-example`, targets 50% CPU, and scales from 1 to 5 replicas. A busybox loop calls the Service so CPU rises. Metrics Server has to be on, or `kubectl top` stays empty.

The mini project in `mini-project/` already defines the PVC, probes, and HPA in namespace `production-webapp`. Apply it on Minikube and keep a screenshot of `kubectl get pvc,pods,hpa -n production-webapp`.
