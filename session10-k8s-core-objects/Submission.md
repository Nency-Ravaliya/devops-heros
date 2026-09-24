# Session 10 – Deployment Strategies (run on minikube)

All four strategies from this session were run on my local minikube cluster. Screenshots are my own terminal output.

## 1. Rolling Update (`01-rolling-update/`)
Deploy v1 with 4 replicas and a NodePort service, then confirm the page shows `VERSION: v1`.

![rolling update – deploy v1](/assets/s10-rolling-01.png)

Apply v2. With `maxSurge: 1` / `maxUnavailable: 0`, one v2 Pod starts, passes its readiness probe, and only then is one v1 Pod terminated. The curl loop keeps getting answers throughout and gradually switches from v1 to v2.

![rolling update – live pod watch and curl loop](/assets/s10-rolling-02.png)

Rollout history shows two revisions; `kubectl rollout undo` brings all Pods back to v1.

![rolling update – history and rollback](/assets/s10-rolling-03.png)

I added `deployment-v3.yaml` and `deployment-v4.yaml` and rolled through them too, ending on v4 with revisions 1–4 in the history.

![rolling update – v3, v4 and cleanup](/assets/s10-rolling-04.png)

## 2. Blue-Green (`02-blue-green/`)
Both environments run at once (3 blue + 3 green Pods). The service selector `slot: blue` sends all traffic to v1.

![blue-green – both slots running, service on blue](/assets/s10-bluegreen-01.png)

Switching is a single `kubectl apply` of `service-green.yaml`: the selector flips to `slot: green`, the endpoints change to the green Pod IPs, and curl now returns the GREEN page.

![blue-green – flip to green](/assets/s10-bluegreen-02.png)

Rollback is the same operation in reverse.

![blue-green – rollback to blue and cleanup](/assets/s10-bluegreen-03.png)

## 3. Canary (`03-canary/`)
9 stable Pods serve 100% of traffic. Adding 1 canary Pod behind the same service gives roughly a 10% split because kube-proxy balances per Pod.

![canary – stable only, then 1 canary pod](/assets/s10-canary-01.png)

Out of 20 requests, 2 hit the canary. Scaling to 3 canary / 7 stable moves that to about 30%.

![canary – 10% then 30% traffic split](/assets/s10-canary-02.png)

Promotion: scale canary to 9 and stable to 0, and every request returns `CANARY v2`.

![canary – promote to 100% and cleanup](/assets/s10-canary-03.png)

## 4. Recreate (`04-recreate/`)
Deploy v1 (3 replicas) and confirm the page.

![recreate – deploy v1](/assets/s10-recreate-01.png)

Applying v2 with `strategy.type: Recreate` terminates all v1 Pods first, then creates the v2 Pods. The curl loop shows the outage window in between.

![recreate – all pods terminated before new ones start, outage visible](/assets/s10-recreate-02.png)

`kubectl rollout undo` goes back to v1 the same way (with another short outage).

![recreate – verify v2, rollback, cleanup](/assets/s10-recreate-03.png)
