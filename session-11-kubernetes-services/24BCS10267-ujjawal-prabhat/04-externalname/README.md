# ExternalName Service

**Ujjawal Prabhat - 24BCS10267 - Session 11**

**What it is:** a DNS-only Service. It has no selector, no ClusterIP, no endpoints and no kube-proxy rules. CoreDNS answers
queries for the service name with a **CNAME** to `spec.externalName`.
**Use it for:** giving an external dependency (managed DB, SaaS API) a stable in-cluster name, so apps use
`external-api` and only the Service changes when the target moves. It can also alias a Service in another namespace.

Manifest: [`service.yaml`](service.yaml) (`external-api -> example.com`, `cluster-dns-alias -> kube-dns.kube-system.svc.cluster.local`)

```
$ kubectl apply -f 04-externalname/service.yaml
service/external-api created
service/cluster-dns-alias created

$ kubectl -n s11 get svc external-api cluster-dns-alias -o wide
NAME                TYPE           CLUSTER-IP   EXTERNAL-IP                              PORT(S)   AGE   SELECTOR
external-api        ExternalName   <none>       example.com                              <none>    2s    <none>
cluster-dns-alias   ExternalName   <none>       kube-dns.kube-system.svc.cluster.local   <none>    2s    <none>

$ kubectl -n s11 get endpointslices -l kubernetes.io/service-name=external-api
No resources found in s11 namespace.

$ kubectl -n s11 exec dnsutils -- dig +noall +answer external-api.s11.svc.cluster.local
external-api.s11.svc.cluster.local. 30 IN CNAME	example.com.
example.com.		30	IN	A	172.66.147.243
example.com.		30	IN	A	104.20.23.154

$ kubectl -n s11 exec dnsutils -- nslookup external-api
Server:		10.96.0.10
Address:	10.96.0.10#53

external-api.s11.svc.cluster.local	canonical name = example.com.
Name:	example.com
Address: 172.66.147.243
Name:	example.com
Address: 104.20.23.154


$ kubectl -n s11 exec curl -- curl -s -o /dev/null -w 'HTTP %{http_code} from %{remote_ip}\n' -H 'Host: example.com' http://external-api
HTTP 200 from 104.20.23.154

$ kubectl -n s11 exec curl -- curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://external-api
HTTP 403

$ kubectl -n s11 exec dnsutils -- dig +noall +answer cluster-dns-alias.s11.svc.cluster.local
cluster-dns-alias.s11.svc.cluster.local. 30 IN CNAME kube-dns.kube-system.svc.cluster.local.
kube-dns.kube-system.svc.cluster.local.	30 IN A	10.96.0.10
```

## Observations

- `CLUSTER-IP <none>`, `PORT(S) <none>`, and **no EndpointSlice**: there is nothing to proxy.
- `dig` shows the CNAME chain: `external-api.s11.svc.cluster.local -> example.com. -> A records`.
- **Gotcha shown above:** the HTTP request reached example.com's servers, but with `Host: external-api` they answered **403**.
  With the correct `Host: example.com` header the answer was **200**. ExternalName only rewrites DNS, not the HTTP Host header
  or TLS SNI. HTTPS would also fail certificate validation, because the cert is for `example.com`.
- `cluster-dns-alias` shows the namespace-alias use case: it is a CNAME to `kube-dns.kube-system.svc.cluster.local`, which resolves to `10.96.0.10`.
