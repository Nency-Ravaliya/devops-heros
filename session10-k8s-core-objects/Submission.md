# Session 10 — Kubernetes Deployment Strategies

## 1. Rolling Update

Deploy `v1`, then roll out `v2` pod-by-pod with zero downtime, and roll back with
`kubectl rollout undo`.

**Deploying v1 and exposing the Service**

![Applying deployment-v1 and service, rollout status and the four v1 pods](../assets/ss2.png)

**v1 serving traffic in the browser**

![Browser showing VERSION: v1 for the rolling update demo](../assets/ss3.png)

**Rolling out v2, checking history and rolling back**

![Applying deployment-v2, watching pods roll over to v2, rollout history and rollout undo](../assets/ss4.png)

## 2. Blue-Green

Run `blue` (v1) and `green` (v2) side by side and switch traffic by changing the
Service selector from `slot=blue` to `slot=green`.

**Both environments running and the Service selector switch**

![Applying blue and green deployments, pods for both slots, and switching the Service selector between blue and green](../assets/ss5.png)

**Blue environment (live)**

![Browser showing BLUE ENVIRONMENT, Version v1, Slot BLUE (LIVE)](../assets/ss6.png)

**Green environment (after promotion)**

![Browser showing GREEN ENVIRONMENT, Version v2, Slot GREEN (STANDBY to PROMOTED)](../assets/ss7.png)

## 3. Canary

Send a small share of traffic to `v2` by scaling the canary Deployment up and the
stable Deployment down behind a single Service.

**Canary rollout and progressive scaling**

![Applying the canary deployment, stable and canary pods, and scaling canary 1 to 3 to 9 while stable goes 9 to 7 to 0](../assets/ss8.png)

## 4. Recreate

Terminate every old pod before any new pod starts — simple, but with downtime
during the switch.

**All v1 pods terminated before v2 pods are created**

![Watch output showing all app-recreate v1 pods terminating and completing before the v2 pods are created](../assets/ss10.png)

**Applying the v2 manifest**

![kubectl apply of the recreate deployment-v2 manifest](../assets/ss11.png)

**Before the update (v1)**

![Browser showing STRATEGY: RECREATE, VERSION: v1](../assets/ss12.png)

**After the update (v2)**

![Browser showing STRATEGY: RECREATE, VERSION: v2 (UPGRADED)](../assets/ss13.png)
