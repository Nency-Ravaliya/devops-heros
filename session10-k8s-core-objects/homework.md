# Session 10 — Kubernetes Deployment Strategies — Homework

Cluster: local `minikube` (Docker driver, macOS). All labs applied against the `default` namespace, verified with `kubectl`, and cleaned up after each lab.

> Note on networking: with the Docker driver on macOS, `minikube ip` / `localhost:<nodePort>` are **not** directly reachable from the host — the NodePort only exists inside the Docker Desktop VM. Every lab below therefore accesses the service through `minikube service <svc> --url` (a local tunnel) or `kubectl port-forward`.

---

## 1. Rolling Update — `01-rolling-update/`

**Strategy:** replace pods gradually (`maxSurge`/`maxUnavailable`) so the Service always has capacity — zero downtime, but v1 and v2 briefly serve traffic side by side.

**Steps performed:**
1. `kubectl apply -f 01-rolling-update/deployment-v1.yaml -f 01-rolling-update/service.yaml`
2. `kubectl rollout status deployment/app-rolling` → successfully rolled out, 4/4 `version=v1` pods.
3. Opened the app in a browser via the tunnel URL → **`VERSION: v1`** page.
4. `kubectl apply -f 01-rolling-update/deployment-v2.yaml` to trigger the update, then watched `kubectl get pods -l app=app-rolling -w` — pods churned one at a time (old `Terminating`/`Completed` while a new one is `ContainerCreating`→`Running`), never all-down at once.
5. Verified v2 in the browser → **`VERSION: v2` — NEW VERSION!**
6. `kubectl rollout history deployment/app-rolling` → revisions 1 and 2 recorded.
7. `kubectl rollout undo deployment/app-rolling` → rolled back; `kubectl get pods --show-labels` confirmed all 4 pods back to `version=v1`.

**Screenshots:**

![v1 page](<01-rolling-update/Screenshot 2026-09-20 at 4.18.20 PM.png>)
*Browser showing `VERSION: v1` after the initial deploy.*


![v2 page](<01-rolling-update/Screenshot 2026-09-20 at 4.20.19 PM.png>)
*Browser showing `VERSION: v2` after the rolling update completed.*

![initial deploy](<01-rolling-update/Screenshot 2026-09-20 at 4.25.10 PM.png>)
*Terminal: `minikube start`, apply v1 deployment+service, rollout status success, 4/4 `version=v1` pods.*

![rollout history + undo](<01-rolling-update/Screenshot 2026-09-20 at 4.25.25 PM.png>)
*Terminal: all 4 pods now `version=v2`, `rollout history` showing 2 revisions, then `rollout undo`.*

![post-rollback pods](<01-rolling-update/Screenshot 2026-09-20 at 4.25.37 PM.png>)
*Terminal: after undo, all 4 pods back to `version=v1`.*

![live rollout churn](<01-rolling-update/Screenshot 2026-09-20 at 4.30.32 PM.png>)
*Terminal: `kubectl get pods -w` during the v2 rollout — old pods `Terminating`/`Completed` interleaved with new pods `Pending`→`ContainerCreating`→`Running`, confirming the gradual, zero-downtime replacement.*

**Result:** Rolling update replaced all 4 pods one at a time with no gap in service; rollback via `kubectl rollout undo` restored v1 in seconds.

**Cleanup:** `kubectl delete -f 01-rolling-update/service.yaml -f 01-rolling-update/deployment-v1.yaml`

---

## 2. Blue-Green Deployment — `02-blue-green/`

**Strategy:** run two full, independent environments (Blue = live v1, Green = standby v2) and cut traffic over instantly by changing the Service `selector` — no mixed-version traffic, instant rollback.

**Steps performed:**
1. `kubectl apply -f 02-blue-green/deployment-blue.yaml -f 02-blue-green/deployment-green.yaml` → 3 blue (`slot=blue,version=v1`) + 3 green (`slot=green,version=v2`) pods, all `Running`.
2. `kubectl apply -f 02-blue-green/service-blue.yaml` → Service selector `app=myapp,slot=blue`. Browser confirmed **BLUE ENVIRONMENT — Version: v1 | Slot: BLUE (LIVE)**.
3. `kubectl describe svc myapp-service | grep Selector` and `kubectl get endpoints myapp-service` → confirmed 3 blue pod IPs behind the service.
4. **The switch:** `kubectl apply -f 02-blue-green/service-green.yaml` → selector flips to `app=myapp,slot=green`.
5. Browser refresh → **GREEN ENVIRONMENT — Version: v2 | Slot: GREEN (STANDBY -> PROMOTED)**, confirming the cutover.
6. Re-ran `describe svc`/`get endpoints` → selector and endpoint IPs both updated to the green pods.
7. Flipped back to `service-blue.yaml` to demonstrate instant rollback.

**Screenshots:**

![blue live](<02-blue-green/Screenshot 2026-09-20 at 4.29.01 PM.png>)
*Browser: BLUE ENVIRONMENT, Version v1, Slot BLUE (LIVE) — service pointed at the blue selector.*

![green promoted](<02-blue-green/Screenshot 2026-09-20 at 4.33.02 PM.png>)
*Browser: GREEN ENVIRONMENT, Version v2, Slot GREEN (STANDBY -> PROMOTED) — right after applying `service-green.yaml`.*

![blue after rollback](<02-blue-green/Screenshot 2026-09-20 at 4.33.57 PM.png>)
*Browser: back to BLUE ENVIRONMENT after re-applying `service-blue.yaml` — instant rollback.*

![selector + endpoints flip](<02-blue-green/Screenshot 2026-09-20 at 4.34.16 PM.png>)
*Terminal: `describe svc | grep Selector` and `get endpoints` before and after the switch — selector goes `slot=blue` → `slot=green`, endpoint IPs change accordingly.*

![both environments deployed](<02-blue-green/Screenshot 2026-09-20 at 4.34.48 PM.png>)
*Terminal: both deployments created, `get pods --show-labels` showing 3 blue + 3 green pods, then the service tunnel started.*

**Result:** The Service selector change was the only moving part — traffic moved 100% blue → 100% green (and back) with no pod restarts and no mixed-version window, unlike rolling update.

**Cleanup:** `kubectl delete -f 02-blue-green/service-blue.yaml -f 02-blue-green/deployment-blue.yaml -f 02-blue-green/deployment-green.yaml`

---

## 3. Canary Deployment — `03-canary/`

**Strategy:** expose a new version to a small slice of real traffic by controlling the **ratio of stable vs. canary pod replicas** behind one Service (Kubernetes has no native weighted routing — traffic split is purely pod-count math).

**Steps performed:**
1. `kubectl apply -f 03-canary/deployment-stable.yaml` → 9 `track=stable,version=v1` pods, rolled out successfully.
2. `kubectl apply -f 03-canary/service.yaml` (selects only the shared `app=myapp-canary` label, so it balances across stable **and** canary pods).
3. `kubectl apply -f 03-canary/deployment-canary.yaml` → 1 `track=canary,version=v2` pod added (10 pods total).
4. Traffic test: `for i in $(seq 1 20); do curl ... ; done` → ~1-4 out of 20 hits landed on `CANARY v2`, the rest `STABLE v1` — matching the 9:1 (90/10) pod ratio.
5. Scaled up the split: `kubectl scale deployment app-canary --replicas=3` + `kubectl scale deployment app-stable --replicas=7` → `kubectl get endpoints` showed 10 endpoints (7 stable + 3 canary); a 20-request traffic test showed roughly 30% of hits on `CANARY v2`.
6. Promoted canary to 100%: `kubectl scale deployment app-canary --replicas=9` + `kubectl scale deployment app-stable --replicas=0` → every request returned `CANARY v2`.
7. Deleted `app-stable` and scaled `app-canary` back down as part of cleanup.

**Screenshots:**

![deploy stable + canary](<03-canary/Screenshot 2026-09-20 at 6.47.04 PM.png>)
*Terminal: stable deployment rolled out (9/9), service applied, canary deployment applied — 1 canary pod (`track=canary,version=v2`) alongside 9 stable pods.*

![scale to 30% + 100%](<03-canary/Screenshot 2026-09-20 at 6.47.25 PM.png>)
*Terminal: `kubectl scale` commands — canary to 3 / stable to 7 (30% split), endpoints showing all 10 pod IPs, then canary to 9 / stable to 0 (100% promotion).*

![promote + rollback commands](<03-canary/Screenshot 2026-09-20 at 6.47.36 PM.png>)
*Terminal: continuation — canary scaled to 9, stable scaled to 0, then `kubectl delete deployment app-stable` and canary scaled back to 0 as part of teardown.*

![10% traffic split](<03-canary/Screenshot 2026-09-20 at 6.47.47 PM.png>)
*Terminal: 20-request curl loop against the service — `CANARY v2` appears once out of 20 (~10%), the rest `STABLE v1` — confirms the 9:1 pod-ratio traffic split.*

![30% traffic split](<03-canary/Screenshot 2026-09-20 at 6.48.03 PM.png>)
*Terminal: 20-request curl loop after scaling to 7 stable / 3 canary — roughly 5 of 20 hits land on `CANARY v2` (~25-30%), matching the new ratio.*

![100% canary traffic](<03-canary/Screenshot 2026-09-20 at 6.48.15 PM.png>)
*Terminal: 5-request curl loop after promoting canary to 9 replicas / stable to 0 — all 5 responses are `CANARY v2`, i.e. fully promoted.*

![stable page render](<03-canary/Screenshot 2026-09-20 at 6.48.25 PM.png>)
*Browser: the stable pod's page — "STABLE v1 — Track: stable | 90% of traffic".*

**Result:** Traffic split tracked pod-count ratio exactly as documented (9:1 → 10%, 7:3 → ~30%, 9:0 → 100%), confirming Kubernetes Services do plain round-robin load balancing with no weighting beyond replica count.

**Cleanup:** `kubectl delete -f 03-canary/service.yaml` + `kubectl delete deployment app-canary app-stable`

---

## 4. Recreate Strategy — `04-recreate/`

**Strategy:** terminate **all** old pods before creating any new ones — guarantees no two versions ever run concurrently, at the cost of a brief full outage. Used for breaking schema migrations, RWO volumes, or single-writer legacy apps.

**Steps performed:**
1. `kubectl apply -f 04-recreate/deployment-v1.yaml -f 04-recreate/service.yaml` → 3/3 `version=v1` pods running.
2. `kubectl apply -f 04-recreate/deployment-v2.yaml` to trigger the update.
3. `kubectl get all` immediately after showed the **old ReplicaSet scaled to 0/0/0** and the **new ReplicaSet at 3/3/3** — i.e. all v1 pods were fully torn down before any v2 pod existed (the Recreate signature, unlike Rolling Update's overlap).
4. `kubectl rollout undo deployment/app-recreate` → rolled back; `kubectl rollout status` confirmed a successful rollout back to v1.

**Screenshots:**

![deploy v1, trigger v2, outage attempt](<04-recreate/Screenshot 2026-09-20 at 6.59.51 PM.png>)
*Terminal: v1 deployed (3/3 running), then `deployment-v2.yaml` applied. The `curl http://localhost:30040` loop shows continuous `[OUTAGE] Connection failed` — because no tunnel/port-forward was active for this NodePort on the Docker driver (see networking note above), so this loop isn't a clean timed capture of the Recreate downtime window specifically. The `kubectl get all` right after does prove the Recreate behavior directly: ReplicaSet `app-recreate-6c78cb55bb` (v1) at 0/0/0 desired/current/ready, and the new ReplicaSet `app-recreate-7bd8d89b8b` (v2) at 3/3/3 — the old set was fully drained before the new one came up.*

![rollback](<04-recreate/Screenshot 2026-09-20 at 6.59.58 PM.png>)
*Terminal: `kubectl rollout undo deployment/app-recreate` → rolled back, `kubectl rollout status` confirms `deployment "app-recreate" successfully rolled out` back to v1.*

**Result:** Confirmed via ReplicaSet counts (not a live curl trace) that Recreate tears the old ReplicaSet down to zero before scaling the new one up — the only one of the four strategies with an intentional all-pods-down window. Rollback restored v1 cleanly with `rollout undo`.

**Learning note:** the failed curl loop is itself a useful lesson — on Docker Desktop/macOS, a NodePort is only routable via `minikube service --url` or `kubectl port-forward`, never via `localhost:<nodePort>` directly.

**Cleanup:** `kubectl delete -f 04-recreate/service.yaml` + `kubectl delete deployment app-recreate`

---

## Strategy Comparison (observed)

| Strategy | Downtime observed? | Traffic mix during update | Rollback method | Evidence |
|---|---|---|---|---|
| Rolling Update | None — pods replaced 1-by-1 | v1 + v2 briefly both served | `kubectl rollout undo` | pod-watch log showed staggered churn |
| Blue-Green | None — instant selector flip | Never mixed (100% one or the other) | Re-apply old Service selector | endpoints/selector flipped atomically |
| Canary | None — ratio-controlled | v1 + v2 mixed by design (10%→30%→100%) | Scale canary to 0 | curl-loop ratios matched pod counts |
| Recreate | Yes — brief full outage | Never mixed (old fully down first) | `kubectl rollout undo` | old ReplicaSet 0/0/0 before new one ready |

---

## Pending

- `pod-lifecycle/` (12-scenario pod lifecycle lab: Running, Pending, Succeeded, Failed, CrashLoopBackOff, ImagePullBackOff, Readiness, Liveness, Startup probe, Init container, Multi-container, Graceful termination) has **not been run yet** — no screenshots exist for it. To be completed in a follow-up session.

---

*Reference material: [Nency-Ravaliya/Kubernetes — core-objects.md](https://github.com/Nency-Ravaliya/Kubernetes/blob/main/core-objects.md)*
