# ClusterIP Service

**Ujjawal Prabhat - 24BCS10267 - Session 11**

**What it is:** the default Service type. It gets a stable virtual IP from the service CIDR (`10.96.0.0/16`). That IP is reachable
**only from inside the cluster**. kube-proxy programs iptables so the VIP load-balances to the ready pods that match the selector.
**Use it for:** internal service-to-service traffic (frontend -> backend, app -> cache/DB).

Manifests: [`../common/web-deployment.yaml`](../common/web-deployment.yaml) (3 x `traefik/whoami`, which prints its pod name),
[`../common/client-pod.yaml`](../common/client-pod.yaml), [`service.yaml`](service.yaml) (`port: 8080 -> targetPort: http (80)`).

```
$ kubectl create ns s11
namespace/s11 created

$ kubectl apply -f common/
pod/dnsutils created
pod/curl created
deployment.apps/web created

$ kubectl -n s11 get deploy,pods -o wide
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                 SELECTOR
deployment.apps/web   3/3     3            3           73s   whoami       traefik/whoami:v1.10   app=web

NAME                       READY   STATUS    RESTARTS   AGE   IP             NODE                   NOMINATED NODE   READINESS GATES
pod/curl                   1/1     Running   0          73s   10.244.2.108   devops-heros-worker    <none>           <none>
pod/dnsutils               1/1     Running   0          73s   10.244.1.137   devops-heros-worker2   <none>           <none>
pod/web-7bdcf85c86-58dx6   1/1     Running   0          73s   10.244.2.109   devops-heros-worker    <none>           <none>
pod/web-7bdcf85c86-8rl6d   1/1     Running   0          73s   10.244.1.139   devops-heros-worker2   <none>           <none>
pod/web-7bdcf85c86-qq9t8   1/1     Running   0          73s   10.244.1.138   devops-heros-worker2   <none>           <none>

$ kubectl apply -f 01-clusterip/service.yaml
service/web-clusterip created

$ kubectl -n s11 get svc web-clusterip -o wide
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SELECTOR
web-clusterip   ClusterIP   10.96.213.135   <none>        8080/TCP   3s    app=web

$ kubectl -n s11 get endpointslices -l kubernetes.io/service-name=web-clusterip -o wide
NAME                  ADDRESSTYPE   PORTS   ENDPOINTS                                AGE
web-clusterip-v45hp   IPv4          80      10.244.1.139,10.244.1.138,10.244.2.109   3s

$ kubectl -n s11 describe svc web-clusterip
Name:                     web-clusterip
Namespace:                s11
Labels:                   <none>
Annotations:              <none>
Selector:                 app=web
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.213.135
IPs:                      10.96.213.135
Port:                     http  8080/TCP
TargetPort:               http/TCP
Endpoints:                10.244.1.139:80,10.244.1.138:80,10.244.2.109:80
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

$ kubectl -n s11 exec curl -- sh -c 'for i in 1 2 3 4 5 6; do curl -s web-clusterip:8080 | grep Hostname; done'
Hostname: web-7bdcf85c86-qq9t8
Hostname: web-7bdcf85c86-qq9t8
Hostname: web-7bdcf85c86-qq9t8
Hostname: web-7bdcf85c86-8rl6d
Hostname: web-7bdcf85c86-58dx6
Hostname: web-7bdcf85c86-qq9t8

$ kubectl -n s11 exec curl -- curl -s web-clusterip.s11.svc.cluster.local:8080
Hostname: web-7bdcf85c86-8rl6d
IP: 127.0.0.1
IP: ::1
IP: 10.244.1.139
IP: fe80::6022:70ff:fe08:2205
RemoteAddr: 10.244.2.108:58794
GET / HTTP/1.1
Host: web-clusterip.s11.svc.cluster.local:8080
User-Agent: curl/8.10.1
Accept: */*


$ kubectl -n s11 exec curl -- curl -s -o /dev/null -w '%{http_code}\n' http://10.96.213.135:8080
200

$ curl -s -m 3 http://10.96.213.135:8080 || echo 'not reachable from the host (exit '$?')'
not reachable from the host (exit 28)

$ docker exec devops-heros-worker iptables -t nat -S KUBE-SERVICES | grep web-clusterip
-A KUBE-SERVICES -d 10.96.213.135/32 -p tcp -m comment --comment "s11/web-clusterip:http cluster IP" -m tcp --dport 8080 -j KUBE-SVC-AT5HU5PJEVGCRNTY
```

## Observations

- `get svc` shows `CLUSTER-IP 10.96.213.135` and `EXTERNAL-IP <none>`.
- The **EndpointSlice** lists the 3 pod IPs on port 80. The Service port (8080) and the container port (80) are separate settings.
- 6 requests from the client pod reached all 3 different pods: kube-proxy picks a backend at random for each connection.
- The same VIP answers by short name, by FQDN, and by raw IP from inside the cluster. From the Mac host it **times out** (curl exit 28), because the VIP only exists in the nodes' iptables rules.
- The `KUBE-SERVICES` rule on a node shows how it works: traffic to `10.96.213.135:8080` jumps to the `KUBE-SVC-...` chain, which DNATs to a pod.
