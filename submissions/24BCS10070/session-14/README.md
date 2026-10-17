# Session 14: Kubernetes troubleshooting

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

```bash
kubectl create namespace student14
kubectl -n student14 apply -f mini-project/ -f broken/
kubectl -n student14 get pods -o wide
kubectl -n student14 describe pod broken-image
kubectl -n student14 logs broken-crash --previous
kubectl -n student14 describe pod broken-pending
kubectl -n student14 events
kubectl -n student14 get events --sort-by=.metadata.creationTimestamp
kubectl explain deployment.spec.template.spec.containers
kubectl -n student14 top pods
kubectl -n student14 exec deployment/troubleshooting-app -- curl -I localhost
```

Run each fault separately and save before/after output under `evidence/`.
The table below is the investigation guide.

| Problem | Investigation | Root cause in this lab / correction | Verify |
|---|---|---|---|
| ErrImagePull → ImagePullBackOff | describe broken-image, read Events | Nonexistent tag; `kubectl set image pod/broken-image web=nginx:stable-alpine` | Pod becomes Ready |
| CrashLoopBackOff | logs --previous, describe | Script exits 1; delete broken-crash and recreate with `sleep 3600` command | Restarts stop |
| Pending | describe broken-pending | Impossible nodeSelector; delete and recreate without it | Pod schedules |
| ContainerCreating | describe Pod, inspect Events and PVC | Investigate volume attachment, CNI, image unpacking before choosing a fix | Container starts |
| Service no endpoints | compare selector with Pod labels | Intentionally change Service selector to wrong-app, then restore | EndpointSlice contains ready addresses |
| DNS failure | exec client nslookup, resolv.conf, CoreDNS logs | Check typo/namespace, DNS Service and network policy | Resolve full Service name |
| Pod networking | get -o wide, test Pod IP and Service separately | Check CNI and NetworkPolicy; correct only the diagnosed issue | Both paths work |
| Configuration error | describe, check ConfigMap/Secret keys | Fix missing object/key and restart workload where needed | Ready Pod with expected config |

Mini-project Service fault:

```bash
kubectl -n student14 patch svc troubleshooting-service -p '{"spec":{"selector":{"app":"wrong-app"}}}'
kubectl -n student14 get endpointslices -l kubernetes.io/service-name=troubleshooting-service
kubectl -n student14 get pods --show-labels
kubectl -n student14 describe svc troubleshooting-service
kubectl -n student14 apply -f mini-project/service.yaml
kubectl -n student14 get endpointslices -l kubernetes.io/service-name=troubleshooting-service
```

Answers to the mini-project questions: `get` summarizes resources; `describe`
shows details and events; `logs` reads process output; `exec` runs a diagnostic
inside a running container. CrashLoopBackOff is restart backoff after repeated
exits. ImagePullBackOff is pull retry backoff. Pending can result from placement,
resource, or storage constraints. A Service can have no ready endpoints because
labels differ or readiness fails. Its selector must match Pod labels. Kubernetes
DNS lets applications find Services by name. An invalid image tag is found in
the pull error Events; use a real tag and verify readiness before declaring it fixed.
Cleanup: `kubectl delete namespace student14`.

## Verification

Manifest syntax checked; fault examples and investigation guide prepared.

Before/after fault reproduction and fixes need a cluster.
