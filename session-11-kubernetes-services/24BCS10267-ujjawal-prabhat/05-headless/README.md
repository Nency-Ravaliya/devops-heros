# Headless Service

**Ujjawal Prabhat - 24BCS10267 - Session 11**

**What it is:** a Service with `clusterIP: None`. It has no virtual IP and kube-proxy does no load balancing. A DNS query returns **one A record per ready
pod**, so the client picks the pod. Combined with a StatefulSet (`serviceName:`), every pod also gets its own stable DNS name:
`<pod>.<svc>.<ns>.svc.cluster.local`.
**Use it for:** stateful clustered systems where peers must address each other individually (databases with replication,
Kafka, ZooKeeper, Elasticsearch), and client-side load balancing (gRPC).

Manifest: [`headless.yaml`](headless.yaml) (headless Service `web-headless` + StatefulSet `web-sts`, 3 replicas)

```
$ kubectl apply -f 05-headless/headless.yaml
service/web-headless created
statefulset.apps/web-sts created

$ kubectl -n s11 get svc web-headless -o wide
NAME           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE   SELECTOR
web-headless   ClusterIP   None         <none>        80/TCP    5s    app=web-sts

$ kubectl -n s11 get pods -l app=web-sts -o wide
NAME        READY   STATUS    RESTARTS   AGE   IP             NODE                   NOMINATED NODE   READINESS GATES
web-sts-0   1/1     Running   0          5s    10.244.1.144   devops-heros-worker2   <none>           <none>
web-sts-1   1/1     Running   0          5s    10.244.2.111   devops-heros-worker    <none>           <none>
web-sts-2   1/1     Running   0          4s    10.244.1.145   devops-heros-worker2   <none>           <none>

$ kubectl -n s11 get endpointslices -l kubernetes.io/service-name=web-headless -o wide
NAME                 ADDRESSTYPE   PORTS   ENDPOINTS                                AGE
web-headless-c22rv   IPv4          80      10.244.1.144,10.244.2.111,10.244.1.145   5s

$ kubectl -n s11 exec dnsutils -- nslookup web-headless
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-headless.s11.svc.cluster.local
Address: 10.244.1.145
Name:	web-headless.s11.svc.cluster.local
Address: 10.244.2.111
Name:	web-headless.s11.svc.cluster.local
Address: 10.244.1.144


$ kubectl -n s11 exec dnsutils -- nslookup web-clusterip
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-clusterip.s11.svc.cluster.local
Address: 10.96.213.135


$ kubectl -n s11 exec dnsutils -- dig +noall +answer web-headless.s11.svc.cluster.local
web-headless.s11.svc.cluster.local. 30 IN A	10.244.2.111
web-headless.s11.svc.cluster.local. 30 IN A	10.244.1.144
web-headless.s11.svc.cluster.local. 30 IN A	10.244.1.145

$ kubectl -n s11 exec dnsutils -- dig +noall +answer web-sts-0.web-headless.s11.svc.cluster.local
web-sts-0.web-headless.s11.svc.cluster.local. 30 IN A 10.244.1.144

$ kubectl -n s11 exec dnsutils -- nslookup web-sts-1.web-headless
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-sts-1.web-headless.s11.svc.cluster.local
Address: 10.244.2.111


$ kubectl -n s11 exec curl -- curl -s web-sts-2.web-headless | grep -E 'Hostname|IP: 10'
Hostname: web-sts-2
IP: 10.244.1.145

$ kubectl -n s11 exec dnsutils -- dig +noall +answer SRV _http._tcp.web-headless.s11.svc.cluster.local
_http._tcp.web-headless.s11.svc.cluster.local. 30 IN SRV 0 33 80 web-sts-0.web-headless.s11.svc.cluster.local.
_http._tcp.web-headless.s11.svc.cluster.local. 30 IN SRV 0 33 80 web-sts-1.web-headless.s11.svc.cluster.local.
_http._tcp.web-headless.s11.svc.cluster.local. 30 IN SRV 0 33 80 web-sts-2.web-headless.s11.svc.cluster.local.

$ kubectl -n s11 delete pod web-sts-0
pod "web-sts-0" deleted from s11 namespace

$ kubectl -n s11 get pod web-sts-0 -o wide
NAME        READY   STATUS    RESTARTS   AGE   IP             NODE                   NOMINATED NODE   READINESS GATES
web-sts-0   1/1     Running   0          4s    10.244.1.146   devops-heros-worker2   <none>           <none>

$ kubectl -n s11 exec dnsutils -- dig +noall +answer web-sts-0.web-headless.s11.svc.cluster.local
web-sts-0.web-headless.s11.svc.cluster.local. 30 IN A 10.244.1.146
```

## Observations

- `CLUSTER-IP None`. The EndpointSlice still exists, and DNS is built from it.
- Headless vs normal: `nslookup web-headless` returned **3 pod IPs**. `nslookup web-clusterip` returned **1 virtual IP**.
- Each StatefulSet pod has its own record: `web-sts-0.web-headless...` -> `10.244.1.144`. Curling `web-sts-2.web-headless`
  always reaches pod `web-sts-2`.
- SRV records list the named port (`_http._tcp`) and the per-pod hostnames.
- After I deleted `web-sts-0`, it came back with the **same name** but a **new IP** (`10.244.1.144 -> 10.244.1.146`), and the DNS record
  updated. Clients should therefore use the stable name, not the IP.
