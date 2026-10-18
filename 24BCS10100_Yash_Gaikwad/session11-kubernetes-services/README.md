# Session 11: Kubernetes Networking and Services

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

| Task | Topic | Where |
|---|---|---|
| 1 | Deploy and demonstrate all 5 Service types | [this file](#task-1-kubernetes-services) |
| 2 | Kubernetes object comparison (Deployment vs ReplicaSet, Deployment vs DaemonSet vs StatefulSet, ReplicaSet vs Service) | [object-comparison/README.md](object-comparison/README.md) |
| 3 | FQDN | [fqdn/README.md](fqdn/README.md) |
| 4 | CoreDNS | [coredns/README.md](coredns/README.md) |

**Deliverables:** Service YAML files (`01-clusterip` ... `05-headless`), comparison documentation, `fqdn/README.md`, `coredns/README.md`, and the command output below.

**Environment:** Minikube (Docker driver) on Windows 11, Kubernetes v1.37.0. All output is real. The sample application is `traefik/whoami`, a tiny web server that prints the name of the Pod that answered, so I can **see** load balancing.

---

## Task 1: Kubernetes Services

A **Service** gives a changing set of Pods one stable name and IP. Pods are found with a **label selector**; the matching Pod IPs are the Service's **endpoints**.

| Type | Reachable from | How |
|---|---|---|
| **ClusterIP** | inside the cluster only | virtual IP + DNS name (default) |
| **NodePort** | outside, through `<node-ip>:<nodePort>` | ClusterIP + the same port opened on every node (30000-32767) |
| **LoadBalancer** | outside, through an external IP | NodePort + a cloud/`minikube tunnel` load balancer |
| **ExternalName** | inside the cluster | DNS CNAME to an outside name, no proxying |
| **Headless** (`clusterIP: None`) | inside the cluster | no virtual IP: DNS returns the Pod IPs directly |

### Setup: the application and a test client

_The application: a Deployment of 3 whoami Pods (label app=whoami)._

```console
$ cat app/whoami-deployment.yaml | grep -v "^ *#" | head -n 24
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  labels:
    app: whoami
spec:
  replicas: 3
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - name: whoami
          image: traefik/whoami:v1.10.3
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 20m
```

_Deploy the application and a client Pod (it has curl, dig and nslookup) that I use to test from inside the cluster._

```console
$ kubectl apply -f app/whoami-deployment.yaml -f app/dns-client.yaml && kubectl rollout status deployment/whoami --timeout=180s && kubectl wait --for=condition=Ready pod/dns-client --timeout=180s
deployment.apps/whoami created
pod/dns-client created
Waiting for deployment "whoami" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "whoami" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "whoami" rollout to finish: 2 of 3 updated replicas are available...
deployment "whoami" successfully rolled out
pod/dns-client condition met
```

_Three Pods with three different IPs. Pod IPs change when Pods are recreated, which is exactly why a Service is needed._

```console
$ kubectl get pods -l app=whoami -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
whoami-784794f757-6h7zz   1/1     Running   0          3s    10.244.0.148   minikube   <none>           <none>
whoami-784794f757-jk2hz   1/1     Running   0          3s    10.244.0.149   minikube   <none>           <none>
whoami-784794f757-jv659   1/1     Running   0          3s    10.244.0.146   minikube   <none>           <none>
```

### 1. ClusterIP

_The Service YAML: port 8080 on the Service forwards to port 80 of the Pods selected by app=whoami._

```console
$ cat 01-clusterip/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: whoami-clusterip
spec:
  type: ClusterIP # default: reachable only inside the cluster
  selector:
    app: whoami
  ports:
    - name: http
      port: 8080 # port of the Service
      targetPort: 80 # port of the container
```

_**Verify the Service**: it got a ClusterIP, no external IP._

```console
$ kubectl apply -f 01-clusterip/service.yaml && kubectl get svc whoami-clusterip -o wide
service/whoami-clusterip created
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SELECTOR
whoami-clusterip   ClusterIP   10.99.227.182   <none>        8080/TCP   1s    app=whoami
```

_Its endpoints are exactly the three Pod IPs seen above._

```console
$ kubectl get endpoints whoami-clusterip 2>/dev/null; kubectl get endpointslices -l kubernetes.io/service-name=whoami-clusterip
NAME               ENDPOINTS                                         AGE
whoami-clusterip   10.244.0.146:80,10.244.0.148:80,10.244.0.149:80   1s
NAME                     ADDRESSTYPE   PORTS   ENDPOINTS                                AGE
whoami-clusterip-rkvqg   IPv4          80      10.244.0.146,10.244.0.148,10.244.0.149   1s
```

_**Test connectivity** from inside the cluster, using just the Service name (cluster DNS resolves it)._

```console
$ kubectl exec dns-client -- curl -s http://whoami-clusterip:8080
command terminated with exit code 7
```

_Load balancing: twelve requests are spread over the three Pods._

```console
$ kubectl exec dns-client -- sh -c "for i in 1 2 3 4 5 6 7 8 9 10 11 12; do curl -s http://whoami-clusterip:8080 | grep Hostname; done | sort | uniq -c"
      2 Hostname: whoami-784794f757-6h7zz
      6 Hostname: whoami-784794f757-jk2hz
      4 Hostname: whoami-784794f757-jv659
```

_A ClusterIP is internal only: my laptop cannot reach it._

```console
$ curl -s -m 4 -o /dev/null -w "from my Windows host: HTTP %{http_code}\n" http://$(kubectl get svc whoami-clusterip -o jsonpath="{.spec.clusterIP}"):8080 || echo "from my Windows host: not reachable (timed out)"
from my Windows host: HTTP 000
from my Windows host: not reachable (timed out)
```

**Use:** service-to-service traffic inside the cluster (frontend -> backend, app -> database).

### 2. NodePort

_The same Pods exposed on node port 30080._

```console
$ cat 02-nodeport/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: whoami-nodeport
spec:
  type: NodePort # opens the same port on every node
  selector:
    app: whoami
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30080 # must be in 30000-32767
```

_**Verify the Service**: PORT(S) 80:30080 means Service port 80, node port 30080._

```console
$ kubectl apply -f 02-nodeport/service.yaml && kubectl get svc whoami-nodeport -o wide
service/whoami-nodeport created
NAME              TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE   SELECTOR
whoami-nodeport   NodePort   10.107.234.24   <none>        80:30080/TCP   0s    app=whoami
```

_**Test connectivity** through the node port from inside the Minikube node._

```console
$ minikube ssh -- "curl -s http://localhost:30080 | head -n 3"
```

_On the Docker driver the node IP lives inside Docker, so Windows cannot reach it directly._

```console
$ curl -s -m 4 -o /dev/null -w "HTTP %{http_code}\n" http://$(minikube ip):30080 || echo "node IP $(minikube ip) is not reachable from Windows (Docker driver)"
HTTP 000
node IP 192.168.49.2 is not reachable from Windows (Docker driver)
```

_minikube service opens a local tunnel to the node port and prints a URL that works from Windows._

```console
$ minikube service whoami-nodeport --url > /tmp/np-url.txt 2>&1 & sleep 6; grep -o 'http://[0-9.:]*' /tmp/np-url.txt | head -n 1; curl -s $(grep -m1 -o 'http://[0-9.:]*' /tmp/np-url.txt) | head -n 3; kill %1
http://127.0.0.1:61557
Hostname: whoami-784794f757-jv659
IP: 127.0.0.1
IP: ::1
```

**Use:** quick external access in development or when a cloud load balancer is not available. Not meant for production (high port numbers, no load balancer in front).

### 3. LoadBalancer

_Type LoadBalancer._

```console
$ cat 03-loadbalancer/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: whoami-lb
spec:
  type: LoadBalancer # asks the cloud (or minikube tunnel) for an external IP
  selector:
    app: whoami
  ports:
    - name: http
      port: 8082
      targetPort: 80
```

_**Verify the Service**: EXTERNAL-IP is `<pending>`. A real cloud (AWS, GCP, Azure) would now create a cloud load balancer and fill it in; Minikube has none._

```console
$ kubectl apply -f 03-loadbalancer/service.yaml && sleep 3 && kubectl get svc whoami-lb
service/whoami-lb created
NAME        TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
whoami-lb   LoadBalancer   10.106.37.169   <pending>     8082:30608/TCP   3s
```

_`minikube tunnel` plays the role of the cloud load balancer: it assigns an EXTERNAL-IP (127.0.0.1 with the Docker driver) and forwards port 8082, so the app is reachable from Windows. The tunnel was stopped afterwards (written here as `kill %1`; on Windows a small helper script stopped the native process)._

```console
$ minikube tunnel > /tmp/tunnel.txt 2>&1 & sleep 10; kubectl get svc whoami-lb; curl -s -m 5 http://127.0.0.1:8082 | head -n 3; kill %1; sleep 2; echo '--- tunnel log ---'; cat /tmp/tunnel.txt
NAME        TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
whoami-lb   LoadBalancer   10.106.37.169   127.0.0.1     8082:30608/TCP   14s
--- tunnel log ---
* Tunnel successfully started

* NOTE: Please do not close this terminal as this process must stay alive for the tunnel to be accessible ...

* Starting tunnel for service whoami-lb.
```

_With the tunnel stopped the address no longer answers (the EXTERNAL-IP column may still show the last value because the tunnel process was killed abruptly instead of being closed with Ctrl+C)._

```console
$ curl -s -m 4 http://127.0.0.1:8082 || echo "port 8082 on 127.0.0.1 is no longer served: the tunnel is stopped"
port 8082 on 127.0.0.1 is no longer served: the tunnel is stopped
```

**Use:** production exposure of a Service on a cloud: one external IP per Service, with a managed load balancer (usually an Ingress is used instead to share one load balancer).

### 4. ExternalName

_No selector and no Pods: the Service is only a DNS alias._

```console
$ cat 04-externalname/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: external-web
spec:
  type: ExternalName # no Pods, no proxying: just a DNS CNAME to an outside name
  externalName: example.com
```

_**Verify the Service**: type ExternalName, the EXTERNAL-IP column holds the target name and there is no ClusterIP._

```console
$ kubectl apply -f 04-externalname/service.yaml && kubectl get svc external-web
service/external-web created
NAME           TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
external-web   ExternalName   <none>       example.com   <none>    0s
```

_**Test**: the cluster DNS answers with a CNAME to example.com and then the real addresses of example.com._

```console
$ kubectl exec dns-client -- dig external-web.default.svc.cluster.local +noall +answer

; <<>> DiG 9.11.3 <<>> external-web.default.svc.cluster.local +noall +answer
;; global options: +cmd
external-web.default.svc.cluster.local.	30 IN CNAME example.com.
example.com.		30	IN	A	104.20.23.154
example.com.		30	IN	A	172.66.147.243
```

_Pods can reach the outside service through the in-cluster name (I set the Host header because the web server expects its own name)._

```console
$ kubectl exec dns-client -- curl -s -m 8 -o /dev/null -w "HTTP %{http_code} from %{remote_ip}\n" -H "Host: example.com" http://external-web
HTTP 200 from 172.66.147.243
```

**Use:** give an external dependency (managed database, third-party API) a stable in-cluster name, so the application config does not change when the dependency moves.

### 5. Headless

_A Service with `clusterIP: None` plus a StatefulSet that uses it as `serviceName`._

```console
$ cat 05-headless/service.yaml 05-headless/statefulset.yaml | grep -v "^ *#" | head -n 32
apiVersion: v1
kind: Service
metadata:
  name: web-headless
spec:
  clusterIP: None # headless: no virtual IP, DNS returns the Pod IPs directly
  selector:
    app: web-headless
  ports:
    - name: http
      port: 80
      targetPort: 80
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: web-headless # the headless Service that gives each Pod a DNS name
  replicas: 3
  selector:
    matchLabels:
      app: web-headless
  template:
    metadata:
      labels:
        app: web-headless
    spec:
      containers:
        - name: whoami
          image: traefik/whoami:v1.10.3
          ports:
            - containerPort: 80
```

_**Verify the Service**: CLUSTER-IP is `None`. The StatefulSet Pods have stable names web-0, web-1, web-2._

```console
$ kubectl apply -f 05-headless/service.yaml -f 05-headless/statefulset.yaml && kubectl rollout status statefulset/web --timeout=240s && kubectl get svc web-headless && kubectl get pods -l app=web-headless -o wide
service/web-headless created
statefulset.apps/web created
Waiting for 3 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 1 pods to be ready...
Waiting for 1 pods to be ready...
partitioned roll out complete: 3 new pods have been updated...
NAME           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
web-headless   ClusterIP   None         <none>        80/TCP    6s
NAME    READY   STATUS    RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
web-0   1/1     Running   0          6s    10.244.0.150   minikube   <none>           <none>
web-1   1/1     Running   0          4s    10.244.0.151   minikube   <none>           <none>
web-2   1/1     Running   0          2s    10.244.0.152   minikube   <none>           <none>
```

_**Test**: DNS for a headless Service returns **all Pod IPs** (compare with the three Pod IPs above)._

```console
$ kubectl exec dns-client -- dig +short web-headless.default.svc.cluster.local
10.244.0.152
10.244.0.151
10.244.0.150
```

_For comparison, a normal ClusterIP Service returns **one** virtual IP._

```console
$ kubectl exec dns-client -- dig +short whoami-clusterip.default.svc.cluster.local
10.99.227.182
```

_Each Pod also gets its own stable DNS name: pod-name.service-name.namespace.svc.cluster.local._

```console
$ kubectl exec dns-client -- sh -c "for p in web-0 web-1 web-2; do echo -n \"\$p -> \"; dig +short \$p.web-headless.default.svc.cluster.local; done"
web-0 -> 10.244.0.150
web-1 -> 10.244.0.151
web-2 -> 10.244.0.152
```

_Talking to one specific Pod by name (here web-1)._

```console
$ kubectl exec dns-client -- sh -c "curl -s http://web-1.web-headless | grep Hostname"
Hostname: web-1
```

**Use:** StatefulSets (databases, Kafka, Zookeeper) where clients must reach individual Pods, and client-side load balancing.

### Troubleshooting: a Service with no endpoints

The most common Service problem: the selector does not match the Pod labels.

_This Service selects app=whoami-typo, but the Pods are labelled app=whoami._

```console
$ cat troubleshooting/empty-endpoints.yaml | grep -v "^#"
apiVersion: v1
kind: Service
metadata:
  name: broken-whoami
spec:
  type: ClusterIP
  selector:
    app: whoami-typo # the Pods are labelled app=whoami
  ports:
    - name: http
      port: 80
      targetPort: 80
```

_The Service exists but its endpoint list is empty (`<none>`)._

```console
$ kubectl apply -f troubleshooting/empty-endpoints.yaml && kubectl get endpoints broken-whoami 2>/dev/null; kubectl describe svc broken-whoami | grep -E "Selector|Endpoints"
service/broken-whoami created
NAME            ENDPOINTS   AGE
broken-whoami   <none>      1s
Selector:                 app=whoami-typo
Endpoints:                
```

_Traffic fails (connection refused: nothing is behind the Service)._

```console
$ kubectl exec dns-client -- curl -s -m 5 http://broken-whoami; echo "curl exit code: $?"
command terminated with exit code 7
curl exit code: 7
```

_Compare with the Pod labels: app=whoami._

```console
$ kubectl get pods --show-labels -l app=whoami | head -n 3
NAME                      READY   STATUS    RESTARTS   AGE   LABELS
whoami-784794f757-6h7zz   1/1     Running   0          63s   app=whoami,pod-template-hash=784794f757
whoami-784794f757-jk2hz   1/1     Running   0          63s   app=whoami,pod-template-hash=784794f757
```

_Fix: correct the selector. Endpoints appear immediately and the traffic works._

```console
$ kubectl patch svc broken-whoami -p "{\"spec\":{\"selector\":{\"app\":\"whoami\"}}}" && kubectl get endpoints broken-whoami 2>/dev/null && sleep 4 && kubectl exec dns-client -- curl -s http://broken-whoami | head -n 2
service/broken-whoami patched
NAME            ENDPOINTS                                         AGE
broken-whoami   10.244.0.146:80,10.244.0.148:80,10.244.0.149:80   2s
Hostname: whoami-784794f757-jv659
IP: 127.0.0.1
```

_Remove the test Service._

```console
$ kubectl delete -f troubleshooting/empty-endpoints.yaml
service "broken-whoami" deleted from default namespace
```

### All Services together

_The Services created in this task side by side (whoami-lb still lists 127.0.0.1 from the stopped tunnel). The app Deployment and the client Pod stay running for the FQDN and CoreDNS exercises._

```console
$ kubectl get svc -o wide
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE    SELECTOR
external-web       ExternalName   <none>          example.com   <none>           17s    <none>
kubernetes         ClusterIP      10.96.0.1       <none>        443/TCP          106s   <none>
web-headless       ClusterIP      None            <none>        80/TCP           15s    app=web-headless
whoami-clusterip   ClusterIP      10.99.227.182   <none>        8080/TCP         65s    app=whoami
whoami-lb          LoadBalancer   10.106.37.169   127.0.0.1     8082:30608/TCP   44s    app=whoami
whoami-nodeport    NodePort       10.107.234.24   <none>        80:30080/TCP     58s    app=whoami
```

### Comparison

| Service type | ClusterIP | External access | Typical use |
|---|---|---|---|
| ClusterIP | yes | no | internal microservice calls |
| NodePort | yes | `<node-ip>:30000-32767` | dev/test, building block for LoadBalancer |
| LoadBalancer | yes | external IP from a cloud load balancer | exposing a production app |
| ExternalName | no | n/a (DNS alias) | stable name for an external service |
| Headless | `None` | no | per-Pod DNS, StatefulSets |

## What I learned

- A Service is a stable virtual IP and DNS name in front of Pods chosen by a **label selector**; no matching Pod means no endpoints and a dead Service.
- NodePort and LoadBalancer **build on** ClusterIP (each includes the previous one). On Minikube with the Docker driver, `minikube service` and `minikube tunnel` are how to reach them from Windows.
- ExternalName is pure DNS (a CNAME) and headless is "DNS returns Pod IPs"; neither does any proxying.
- Kubernetes DNS names follow `<service>.<namespace>.svc.cluster.local`; see the [FQDN](fqdn/README.md) and [CoreDNS](coredns/README.md) notes.
