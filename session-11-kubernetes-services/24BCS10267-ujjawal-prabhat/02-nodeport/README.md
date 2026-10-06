# NodePort Service

**Ujjawal Prabhat - 24BCS10267 - Session 11**

**What it is:** a ClusterIP **plus** a port in the range 30000-32767 opened on **every node**. Traffic to `<anyNodeIP>:<nodePort>`
is forwarded to a ready pod, which may be on a different node.
**Use it for:** simple external access in dev/bare-metal setups, or as the building block under a LoadBalancer.

Manifest: [`service.yaml`](service.yaml). I fixed `nodePort: 30080` because my kind config maps host port 30080 to the
control-plane node, so the service is also reachable from my Mac at `http://localhost:30080`.

```
$ kubectl apply -f 02-nodeport/service.yaml
service/web-nodeport created

$ kubectl -n s11 get svc web-nodeport -o wide
NAME           TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE   SELECTOR
web-nodeport   NodePort   10.96.28.2   <none>        80:30080/TCP   3s    app=web

$ kubectl -n s11 get endpointslices -l kubernetes.io/service-name=web-nodeport
NAME                 ADDRESSTYPE   PORTS   ENDPOINTS                                AGE
web-nodeport-l6sx4   IPv4          80      10.244.1.138,10.244.2.109,10.244.1.139   3s

$ kubectl get nodes -o custom-columns=NAME:.metadata.name,INTERNAL-IP:.status.addresses[0].address
NAME                         INTERNAL-IP
devops-heros-control-plane   172.18.0.3
devops-heros-worker          172.18.0.4
devops-heros-worker2         172.18.0.2

$ for ip in 172.18.0.3 172.18.0.4 172.18.0.2; do docker exec devops-heros-worker curl -s http://$ip:30080 | grep Hostname; done
Hostname: web-7bdcf85c86-8rl6d
Hostname: web-7bdcf85c86-58dx6
Hostname: web-7bdcf85c86-58dx6

$ curl -s http://localhost:30080 | head -4
Hostname: web-7bdcf85c86-8rl6d
IP: 127.0.0.1
IP: ::1
IP: 10.244.1.139

$ kubectl -n s11 exec curl -- sh -c 'curl -s web-nodeport | grep Hostname'
Hostname: web-7bdcf85c86-8rl6d
```

## Observations

- `PORT(S) 80:30080/TCP` means Service port 80 on the ClusterIP, and node port 30080 on every node.
- The same port answered on **all three node IPs**, including the control-plane, which runs none of the web pods.
  kube-proxy forwards the traffic to a pod on another node.
- `curl http://localhost:30080` from macOS works because of the kind `extraPortMappings` (host 30080 -> node 30080).
  On Minikube the equivalent would be `minikube service web-nodeport --url`.
- A NodePort is also a ClusterIP: the in-cluster call `curl web-nodeport` still works.
