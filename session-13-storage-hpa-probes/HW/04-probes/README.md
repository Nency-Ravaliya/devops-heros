# 04 — Probes (Liveness, Readiness, Startup)

**Submitted by:** Piyush Bansal

The session folder has a `05-probes/` section, so I ran it too. A Pod can be `Running` while
the app inside is broken. Probes let the kubelet check the app itself.

| Probe | Question it asks | On failure |
|---|---|---|
| Startup | Has the app finished starting? | Container restarted after `failureThreshold`. Liveness/readiness wait until it passes |
| Readiness | Can it take traffic right now? | Pod marked not ready, removed from Service endpoints. **No restart** |
| Liveness | Is it still alive? | kubelet kills and restarts the container |

Probe types: `httpGet`, `tcpSocket`, `exec`, `grpc`. Tuning fields: `initialDelaySeconds`,
`periodSeconds`, `timeoutSeconds`, `failureThreshold`, `successThreshold`.

| File | What it is |
|---|---|
| [liveness.yaml](liveness.yaml), [readiness.yaml](readiness.yaml), [startup.yaml](startup.yaml) | The session's three examples, unchanged |
| [readiness-broken.yaml](readiness-broken.yaml) | Readiness probe pointing at `/does-not-exist` |
| [liveness-broken.yaml](liveness-broken.yaml) | Liveness probe pointing at `/crash` |

Namespace: `p13-probes`. All output is real.

## 1. Healthy probes

```text
$ kubectl apply -n p13-probes -f liveness.yaml -f readiness.yaml -f startup.yaml
pod/liveness-demo created
pod/readiness-demo created
pod/startup-demo created
$ kubectl get pods -n p13-probes
NAME             READY   STATUS    RESTARTS   AGE
liveness-demo    1/1     Running   0          17s
readiness-demo   1/1     Running   0          17s
startup-demo     1/1     Running   0          16s
$ kubectl describe pod startup-demo -n p13-probes | grep -E 'Liveness|Readiness|Startup'
    Liveness:       http-get http://:80/ delay=0s timeout=1s period=5s #success=1 #failure=3
    Readiness:      http-get http://:80/ delay=0s timeout=1s period=5s #success=1 #failure=3
    Startup:        http-get http://:80/ delay=0s timeout=1s period=2s #success=1 #failure=30
```

The startup probe allows up to 30 × 2 s = 60 s for the app to come up before liveness kicks in.

## 2. Readiness failing on a running Pod

I put a Service in front of `readiness-demo`, then broke the app by moving nginx's
`index.html` away (nginx then returns 403 for `/`).

```text
$ kubectl expose pod readiness-demo -n p13-probes --name=readiness-service --port=80
service/readiness-service exposed
$ kubectl get endpointslices -n p13-probes -l kubernetes.io/service-name=readiness-service -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{" ready="}{.conditions.ready}{"\n"}{end}'
10.244.0.49 ready=true
$ kubectl exec -n p13-probes readiness-demo -- mv /usr/share/nginx/html/index.html /tmp/index.html
$ kubectl get pod readiness-demo -n p13-probes
NAME             READY   STATUS    RESTARTS   AGE
readiness-demo   0/1     Running   0          26m
$ kubectl get endpointslices -n p13-probes -l kubernetes.io/service-name=readiness-service -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{" ready="}{.conditions.ready}{"\n"}{end}'
10.244.0.49 ready=false
$ kubectl get events -n p13-probes --field-selector involvedObject.name=readiness-demo,reason=Unhealthy
LAST SEEN   TYPE      REASON      OBJECT               MESSAGE
4s          Warning   Unhealthy   pod/readiness-demo   Readiness probe failed: HTTP probe failed with statuscode: 403
$ kubectl run curl-test -n p13-probes --image=busybox:1.36 --restart=Never --rm -i --quiet -- wget -T 3 -qO- http://readiness-service
pod p13-probes/curl-test terminated (Error)
```

Still `Running`, `RESTARTS 0`, but `0/1` ready, the endpoint is marked `ready=false` and the
Service sends no traffic to it. (Note: plain `kubectl get endpointslices` still lists the IP;
you have to look at the `ready` condition.) Putting the file back fixes it without any restart:

```text
$ kubectl exec -n p13-probes readiness-demo -- mv /tmp/index.html /usr/share/nginx/html/index.html
$ kubectl get pod readiness-demo -n p13-probes
NAME             READY   STATUS    RESTARTS   AGE
readiness-demo   1/1     Running   0          26m
$ kubectl get endpointslices -n p13-probes -l kubernetes.io/service-name=readiness-service -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{" ready="}{.conditions.ready}{"\n"}{end}'
10.244.0.49 ready=true
$ kubectl run curl-test -n p13-probes --image=busybox:1.36 --restart=Never --rm -i --quiet -- wget -T 3 -qO- http://readiness-service | grep title
warning: couldn't attach to pod/curl-test, falling back to streaming logs: unable to upgrade connection: container curl-test not found in pod curl-test_p13-probes
<title>Welcome to nginx!</title>
<title>Welcome to nginx!</title>
```

(The warning and the doubled line are kubectl falling back to logs because the tiny Pod finished
before attach; the request itself worked.)

## 3. Wrong readiness path

```text
$ kubectl apply -n p13-probes -f readiness-broken.yaml
pod/readiness-broken created
$ kubectl get pod readiness-broken -n p13-probes
NAME               READY   STATUS    RESTARTS   AGE
readiness-broken   0/1     Running   0          34s
$ kubectl describe pod readiness-broken -n p13-probes | sed -n '/^Events/,$p'
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Normal   Scheduled  35s               default-scheduler  Successfully assigned p13-probes/readiness-broken to desktop-control-plane
  Normal   Pulled     31s               kubelet            spec.containers{nginx}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal   Created    30s               kubelet            spec.containers{nginx}: Container created
  Normal   Started    29s               kubelet            spec.containers{nginx}: Container started
  Warning  Unhealthy  7s (x4 over 22s)  kubelet            spec.containers{nginx}: Readiness probe failed: HTTP probe failed with statuscode: 404
```

Never becomes ready, never restarts.

## 4. Wrong liveness path

```text
$ kubectl apply -n p13-probes -f liveness-broken.yaml
pod/liveness-broken created
$ kubectl get pod liveness-broken -n p13-probes
NAME              READY   STATUS    RESTARTS      AGE
liveness-broken   1/1     Running   3 (10s ago)   76s
$ kubectl describe pod liveness-broken -n p13-probes | sed -n '/^Events/,$p'
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  75s                default-scheduler  Successfully assigned p13-probes/liveness-broken to desktop-control-plane
  Normal   Pulled     10s (x4 over 74s)  kubelet            spec.containers{nginx}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Warning  Unhealthy  10s (x9 over 65s)  kubelet            spec.containers{nginx}: Liveness probe failed: HTTP probe failed with statuscode: 404
  Normal   Killing    10s (x3 over 55s)  kubelet            spec.containers{nginx}: Container nginx failed liveness probe, will be restarted
  Normal   Created    9s (x4 over 74s)   kubelet            spec.containers{nginx}: Container created
  Normal   Started    9s (x4 over 73s)   kubelet            spec.containers{nginx}: Container started
$ kubectl logs -n p13-probes liveness-broken --previous --tail=3
2026/10/07 16:12:10 [notice] 1#1: worker process 37 exited with code 0
2026/10/07 16:12:10 [notice] 1#1: worker process 35 exited with code 0
2026/10/07 16:12:10 [notice] 1#1: exit
```

3 restarts in 76 s: 3 failures × 5 s = killed roughly every 15-20 s. The previous container's logs
show a clean nginx shutdown, so the app itself was fine. The restart came from the kubelet,
which is the clue that the probe (not the app) is wrong. Left like this it ends in `CrashLoopBackOff`.

## Cleanup

```bash
kubectl delete ns p13-probes
```

## What I learned

- Readiness failing = no traffic, no restart. Liveness failing = restart.
- A bad liveness probe can restart a perfectly healthy app forever, so it should check something
  cheap and reliable, and use a startup probe for slow-starting apps.
- `describe pod` events (`Unhealthy` + status code) are the fastest way to see which probe fails and why.
