# Session 11 — Services

Student: Viraj Bhanage, roll 24BCS10274

Apply `clusterip.yaml` first. The other Service files select the same `app: web` Pods.

```bash
kubectl apply -f clusterip.yaml
kubectl apply -f nodeport.yaml
kubectl apply -f loadbalancer.yaml
kubectl apply -f externalname.yaml
kubectl apply -f headless.yaml
kubectl get svc
kubectl get endpoints web-clusterip
```

| Service | How you reach it | What to verify |
|---|---|---|
| ClusterIP | Only from inside the cluster | `kubectl exec` a debug pod and `wget -qO- http://web-clusterip` |
| NodePort | `<node-ip>:30080` | `minikube service web-nodeport --url` |
| LoadBalancer | External IP, or Minikube tunnel | `minikube tunnel` then `kubectl get svc web-loadbalancer` |
| ExternalName | DNS alias to `example.com` | `nslookup web-externalname.default.svc.cluster.local` returns a CNAME |
| Headless | No cluster IP | `clusterIP: None`. DNS returns Pod IPs, not one virtual IP |

## Deployment vs ReplicaSet

A ReplicaSet keeps N Pods that match its selector. A Deployment owns ReplicaSets and adds rollout history. You change the Deployment template. The Deployment creates a new ReplicaSet, scales it up, and scales the old one down. Scaling `kubectl scale deployment` changes the Deployment, which changes the current ReplicaSet. You normally do not edit the ReplicaSet.

## Deployment vs DaemonSet vs StatefulSet

| | Deployment | DaemonSet | StatefulSet |
|---|---|---|---|
| Use | Stateless app replicas | One Pod per node (logs, CNI, agents) | Stable identity (databases) |
| Pod names | Random suffix | One per node | `name-0`, `name-1` |
| Scaling | Replica count | Follows node count | Ordered create and delete |
| Network | Service load-balances | Often host ports | Stable per-Pod DNS |
| Storage | Usually shared or none | Often hostPath | One PVC per Pod via `volumeClaimTemplates` |

## ReplicaSet vs Service

A ReplicaSet starts and replaces Pods. A Service does not start Pods. It watches Endpoints that match its selector and load-balances traffic to ready Pod addresses. Pod IPs change. The Service virtual IP and DNS name stay put, which is why clients use the Service.

More DNS detail: [fqdn/README.md](fqdn/README.md) and [coredns/README.md](coredns/README.md).
