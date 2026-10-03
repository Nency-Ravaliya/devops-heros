# Service & DNS

We will check:

* Pods
* Pod labels
* Service selector
* Service endpoints
* Service DNS
* CoreDNS
* Connectivity from inside a Pod

---

## 1. Create The Application

Apply:

```bash
kubectl apply -f deployment.yaml
```

Check:

```bash
kubectl get pods
```

Expected output:

```text
NAME                   READY   STATUS
web-xxxxxxxxxx-xxxxx   1/1     Running
web-xxxxxxxxxx-yyyyy   1/1     Running
```

*(The exact names will be different on your cluster.)*

---

## 2. Create The Service

Apply:

```bash
kubectl apply -f service.yaml
```

Check:

```bash
kubectl get service
```

You should see:

```text
NAME          TYPE        CLUSTER-IP
web-service   ClusterIP   10.x.x.x
```

*(The ClusterIP will be different on your cluster.)*

---

## 3. Check Service Details

Run:

```bash
kubectl describe service web-service
```

Important things to check:
* **Selector**
* **Port**
* **TargetPort**
* **Endpoints**

---

## 4. Check Endpoints

Run:

```bash
kubectl get endpoints web-service
```

You should see Pod IP addresses. Example:

```text
NAME          ENDPOINTS
web-service   10.244.0.5:80,10.244.0.6:80
```

*(The IPs will be different.)*

This is a very important troubleshooting step.

---

## 5. Why Are Endpoints Important?

A Service uses its selector to find matching Pods.

Our Service says:

```yaml
selector:
  app: web
```

Our Pods have:

```yaml
labels:
  app: web
```

Therefore:

```text
Service
   │
   │ selector app=web
   ▼
Matching Pods
   │
   ▼
Endpoints
```

---

## 6. Test DNS

Create the DNS testing Pod:

```bash
kubectl apply -f dns-test-pod.yaml
```

Check:

```bash
kubectl get pod dns-test
```

Expected output:

```text
NAME       READY   STATUS
dns-test   1/1     Running
```

---

## 7. Test Service DNS

Run:

```bash
kubectl exec -it dns-test -- nslookup web-service
```

You should get a result containing the Service IP. *(The exact output will depend on your cluster.)*

You can also test:

```bash
kubectl exec -it dns-test -- nslookup web-service.default.svc.cluster.local
```

The Kubernetes DNS name follows this general structure:

```text
service-name.namespace.svc.cluster.local
```

---

## 8. Test HTTP Connection

Run:

```bash
kubectl exec dns-test -- wget -qO- http://web-service
```

You should receive Nginx HTML output.

This proves:

```text
DNS works
   │
   ▼
Service resolves
   │
   ▼
Service routes traffic
   │
   ▼
Pod responds
```

---

## 9. Intentionally Break The Service

Apply:

```bash
kubectl apply -f broken-service.yaml
```

Check:

```bash
kubectl get service broken-service
```

Then:

```bash
kubectl get endpoints broken-service
```

You should see:

```text
NAME             ENDPOINTS
broken-service   <none>
```

**Why?** Because the Service says:

```yaml
selector:
  app: does-not-exist
```

but our Pods have:

```yaml
app: web
```

So the Service finds no matching Pods.

---

## 10. This Is A Very Common Problem

Imagine:

Pod label:
```yaml
app: backend
```

but Service has:
```yaml
selector:
  app: frontend
```

Then:

```text
Service
   │
   │ selector does not match
   ▼
No endpoints
   │
   ▼
No application traffic
```

The Pod can be perfectly healthy. The Service can also be perfectly created. But traffic still fails.

---

## 11. Fix The Service

Delete the broken Service:

```bash
kubectl delete service broken-service
```

The correct Service is:

```bash
kubectl get service web-service
```

Check:

```bash
kubectl get endpoints web-service
```

You should again see Pod IP addresses.

---

## 12. Service Troubleshooting Flow

When a Service is not working:

1. **Check Pods:** `kubectl get pods`
2. **Check labels:** `kubectl get pods --show-labels`
3. **Check Service:** `kubectl describe service <name>`
4. **Check endpoints:** `kubectl get endpoints <name>`
5. **Test DNS:** `nslookup <service-name>`
6. **Test HTTP:** `wget` / `curl`
7. **Check CoreDNS:** `kubectl get pods -n kube-system`

---

## 13. Check Pod Labels

Run:

```bash
kubectl get pods --show-labels
```

You should see:

```text
NAME                   LABELS
web-xxxxxxxxxx-xxxxx   app=web
web-xxxxxxxxxx-yyyyy   app=web
```

Compare those labels with:

```bash
kubectl describe service web-service
```

Look for:

```text
Selector: app=web
```

They must match.

---

## 14. Check CoreDNS

Run:

```bash
kubectl get pods -n kube-system
```

Look for CoreDNS Pods. Depending on your Kubernetes distribution, the names can differ. For many clusters you will see something similar to:

```text
coredns-xxxxx   1/1   Running
```

---

## 15. Check DNS Configuration

Run:

```bash
kubectl exec -it dns-test -- cat /etc/resolv.conf
```

You should see a Kubernetes DNS nameserver and search domains. *(The exact values depend on your cluster.)*

---

## 16. Check CoreDNS Logs

Run:

```bash
kubectl logs -n kube-system -l k8s-app=kube-dns
```

If DNS is broken, CoreDNS status and logs are useful places to investigate.

---

## 17. Important Difference

If this works:

```bash
kubectl exec dns-test -- nslookup web-service
```

but this fails:

```bash
kubectl exec dns-test -- wget -qO- http://web-service
```

then DNS may be working. The problem could be:
* Service selector
* Endpoints
* `targetPort`
* Application
* Network policy

Do not immediately blame DNS.

---

## Key Learning

Remember:

```text
Pod
 │
 ├── label
 ▼
Service selector
 │
 ▼
Endpoints
 │
 ▼
Service IP
 │
 ▼
DNS name
```

A Service without matching endpoints is one of the first things to investigate when a Service is not working.

Kubernetes' official Service debugging guide follows this same general process: verify Pods, inspect their addresses, inspect the Service, and test connectivity from inside a Pod.

The official DNS troubleshooting guide also recommends checking DNS resolution from a Pod, CoreDNS Pods, and CoreDNS logs.

---

## Reference

* **Kubernetes Services:**  
  https://kubernetes.io/docs/concepts/services-networking/service/
* **Debug Services:**  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/
