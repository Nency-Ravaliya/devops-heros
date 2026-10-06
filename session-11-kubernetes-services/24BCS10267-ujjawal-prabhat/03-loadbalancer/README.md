# LoadBalancer Service

**Ujjawal Prabhat - 24BCS10267 - Session 11**

**What it is:** a NodePort **plus** an external load balancer that a cloud controller manager (CCM) provisions.
The CCM writes the LB address into `.status.loadBalancer.ingress`, and `kubectl get svc` shows it as `EXTERNAL-IP`.
**Use it for:** exposing a service to the internet on a cloud provider (AWS NLB/ELB, GCP LB, Azure LB).

kind has no cloud, so without a CCM the service would stay at `EXTERNAL-IP <pending>` forever. I installed
**cloud-provider-kind**, which acts as the CCM. For each LoadBalancer Service it runs an Envoy container on the `kind` Docker network
and gives the service that container's IP.

```bash
brew install cloud-provider-kind
# run outside the cluster (it talks to Docker + the API server).
# Default ingress/Gateway features disabled so it does not install anything else in the shared cluster;
# --enable-lb-port-mapping publishes LB ports on the Mac host (Docker Desktop cannot route to container IPs).
cloud-provider-kind --enable-default-ingress=false --gateway-channel=disabled --enable-lb-port-mapping
```

Manifest: [`service.yaml`](service.yaml)

```
$ brew list --versions cloud-provider-kind
cloud-provider-kind 0.12.0

$ kubectl apply -f 03-loadbalancer/service.yaml
service/web-loadbalancer created

$ kubectl -n s11 get svc web-loadbalancer
NAME               TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
web-loadbalancer   LoadBalancer   10.96.66.32   <pending>     80:31943/TCP   0s

$ kubectl -n s11 get svc web-loadbalancer -o wide
NAME               TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE   SELECTOR
web-loadbalancer   LoadBalancer   10.96.66.32   172.18.0.6    80:31943/TCP   15s   app=web

$ kubectl -n s11 get svc web-loadbalancer -o jsonpath='{.status.loadBalancer}{"\n"}'
{"ingress":[{"ip":"172.18.0.6","ipMode":"Proxy","ports":[{"port":80,"protocol":"TCP"}]}]}

$ kubectl -n s11 get endpointslices -l kubernetes.io/service-name=web-loadbalancer
NAME                     ADDRESSTYPE   PORTS   ENDPOINTS                                AGE
web-loadbalancer-6pdb9   IPv4          80      10.244.2.109,10.244.1.139,10.244.1.138   15s

$ kubectl -n s11 describe svc web-loadbalancer | sed -n '/^Type/,$p'
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.66.32
IPs:                      10.96.66.32
LoadBalancer Ingress:     172.18.0.6 (Proxy)
Port:                     http  80/TCP
TargetPort:               http/TCP
NodePort:                 http  31943/TCP
Endpoints:                10.244.2.109:80,10.244.1.139:80,10.244.1.138:80
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  15s   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   15s   service-controller  Ensured load balancer

$ docker ps --filter label=io.x-k8s.cloud-provider-kind.cluster=devops-heros --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
NAMES                  IMAGE                      PORTS
kindccm-bfd5bba4f5bf   envoyproxy/envoy:v1.33.2   0.0.0.0:59294->80/tcp, 0.0.0.0:59293->10000/tcp, [::]:59293->10000/tcp
kindccm-17118423c54d   envoyproxy/envoy:v1.33.2   0.0.0.0:58919->80/tcp, 0.0.0.0:58918->443/tcp, 0.0.0.0:58920->10000/tcp, [::]:58920->10000/tcp

$ docker inspect kindccm-bfd5bba4f5bf --format '{{index .Config.Labels "io.x-k8s.cloud-provider-kind.loadbalancer.name"}} -> {{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}'
devops-heros/s11/web-loadbalancer -> 59294
```

### Test the external IP from a container on the `kind` Docker network (where 172.18.0.6 is routable)

```
$ docker run --rm --network kind curlimages/curl:8.10.1 -s http://172.18.0.6/ | head -4
...(docker image pull progress lines removed)
Hostname: web-7bdcf85c86-qq9t8
IP: 127.0.0.1
IP: ::1
IP: 10.244.1.138

$ for i in 1 2 3 4; do docker run --rm --network kind curlimages/curl:8.10.1 -s http://172.18.0.6/ | grep Hostname; done
Hostname: web-7bdcf85c86-8rl6d
Hostname: web-7bdcf85c86-58dx6
Hostname: web-7bdcf85c86-qq9t8
Hostname: web-7bdcf85c86-8rl6d

$ kubectl -n s11 exec curl -- sh -c 'curl -s web-loadbalancer | grep Hostname'
Hostname: web-7bdcf85c86-qq9t8
```

### From the Mac host

```
$ curl -s -m 3 http://172.18.0.6/ || echo 'LB IP not routable from macOS host (exit '$?') - Docker Desktop network lives inside a VM'
LB IP not routable from macOS host (exit 28) - Docker Desktop network lives inside a VM

$ curl -s http://localhost:59294/ | head -2
Hostname: web-7bdcf85c86-8rl6d
IP: 127.0.0.1
```

## Observations

- `EXTERNAL-IP` went from `<pending>` (0 s) to `172.18.0.6` (15 s) after the CCM's `EnsuringLoadBalancer` / `EnsuredLoadBalancer` events.
  **Without cloud-provider-kind it stays `<pending>`**, because nothing in the cluster can create a load balancer. In that case you
  reach the service through its NodePort (`31943` here), which a LoadBalancer Service always also has.
- `ipMode: Proxy`: the Envoy container proxies traffic to the node ports. The request still goes LB -> NodePort -> pod.
- On macOS the LB IP is inside Docker Desktop's VM network, so the host cannot reach it directly (curl exit 28).
  `--enable-lb-port-mapping` publishes it as `localhost:59294`.
- The second `kindccm-*` container belongs to the cluster's existing `ingress-nginx-controller` LoadBalancer Service, which
  also received an external IP (`172.18.0.5`) once a CCM was running. I did not change that Service.
