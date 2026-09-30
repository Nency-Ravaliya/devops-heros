# Session 11 — Kubernetes Services

Session 11 focuses on Kubernetes Services and the different ways Kubernetes exposes and discovers application Pods.

---

# Labs

## 01 — ClusterIP

A ClusterIP Service provides a stable virtual IP inside the cluster.

![ClusterIP](screenshots/01-clusterip/)

---

## 02 — NodePort

A NodePort Service exposes the Service through a port on each Kubernetes node.

![NodePort](screenshots/02-nodeport/)

---

## 03 — LoadBalancer

A LoadBalancer Service requests an externally accessible load balancer from the underlying environment/provider.

![LoadBalancer](screenshots/03-loadbalancer/)

---

## 04 — ExternalName

ExternalName provides a Kubernetes DNS name that aliases an external DNS name rather than routing traffic through a Kubernetes Service IP.

![ExternalName](screenshots/04-externalname/)

---

## 05 — Headless Service

A Headless Service uses `clusterIP: None`. Instead of returning a virtual Service IP, Kubernetes DNS returns the IP addresses of the matching Pods.

![Headless Service](screenshots/05-headless/)

---

# Workload Controllers & Services

These concepts are easy to confuse because they all appear while building a Kubernetes application, but they solve different problems.

The simplest mental model is:

```text
                    Deployment
                        │
                        │ manages
                        ▼
                    ReplicaSet
                        │
                        │ maintains
                        ▼
                       Pods
                        ▲
                        │ selected by labels
                        │
                     Service
                        ▲
                        │
                      Client
```

The workload controllers answer:

> **How should Pods exist and behave?**

The Service answers:

> **How should other applications reach those Pods?**

---

# 1. Deployment vs ReplicaSet

## Purpose

### ReplicaSet

A ReplicaSet's primary responsibility is to maintain the desired number of identical Pod replicas.

For example:

```yaml
spec:
  replicas: 3
```

The ReplicaSet continuously works toward:

```text
Pod A
Pod B
Pod C
```

If one disappears:

```text
Pod A
Pod C
```

the ReplicaSet notices that the actual state no longer matches the desired state and creates a replacement:

```text
Pod A
Pod C
Pod D
```

So the core responsibility of a ReplicaSet is:

> **Maintain the desired number of matching Pods.**

---

### Deployment

A Deployment operates at a higher level.

It manages ReplicaSets and provides application rollout functionality such as:

- declarative updates
- rolling updates
- rollout history
- rollback
- revision management

The relationship is:

```text
Deployment
     │
     ▼
ReplicaSet
     │
     ▼
Pods
```

So a Deployment does not normally manage individual Pods directly. It manages the ReplicaSet that manages those Pods.

---

## Pod Management

Suppose we have:

```text
Deployment: web
        │
        ▼
ReplicaSet: web-6bd469df5c
        │
        ├── Pod
        ├── Pod
        └── Pod
```

The ReplicaSet is responsible for maintaining the desired replica count.

The Deployment is responsible for deciding which ReplicaSet represents the current application revision.

---

## Scaling

Both a ReplicaSet and Deployment expose a replica count.

For example:

```bash
kubectl scale deployment web --replicas=5
```

Conceptually:

```text
kubectl
   │
   ▼
Deployment
   │
   ▼
ReplicaSet
   │
   ▼
5 Pods
```

The Deployment delegates the actual replica maintenance to its ReplicaSet.

---

## Rolling Updates

This is one of the major reasons we normally use a Deployment instead of working directly with a ReplicaSet.

Suppose the current application is:

```text
web:v1
```

and we update it to:

```text
web:v2
```

The Deployment creates/manages a new ReplicaSet representing the new Pod template.

Before the update:

```text
Deployment
    │
    ▼
ReplicaSet v1
    ├── Pod v1
    ├── Pod v1
    └── Pod v1
```

During the rollout:

```text
Deployment
    ├── ReplicaSet v1
    │     ├── Pod v1
    │     └── Pod v1
    │
    └── ReplicaSet v2
          └── Pod v2
```

The Deployment gradually scales the old ReplicaSet down and the new ReplicaSet up according to the rollout strategy.

Eventually:

```text
Deployment
    │
    ▼
ReplicaSet v2
    ├── Pod v2
    ├── Pod v2
    └── Pod v2
```

The old ReplicaSet can remain as rollout history, which enables rollback.

---

## Relationship: Deployment → ReplicaSet → Pods

The cleanest way to remember it:

> **Deployment manages ReplicaSets; ReplicaSets manage Pods.**

| Responsibility | Deployment | ReplicaSet |
|---|---|---|
| Maintain Pod count | Indirectly | Directly |
| Create/recreate Pods | Through ReplicaSet | Yes |
| Scaling | Yes | Yes |
| Rolling updates | Yes | No |
| Rollback / rollout history | Yes | No |
| Manage multiple revisions | Yes | No |

### Mental model

```text
ReplicaSet:
"How many Pods matching this template should exist?"

Deployment:
"Which application revision should be running,
and how should we transition between revisions?"
```

---

# 2. Deployment vs DaemonSet vs StatefulSet

Deployment, DaemonSet, and StatefulSet are all workload controllers, but they solve different workload problems.

The key question is:

> **What kind of Pod lifecycle, identity, placement, and storage does this application need?**

---

## Use Cases

### Deployment — interchangeable replicas

Use a Deployment when the application consists of interchangeable replicas.

Typical examples:

- REST API
- frontend
- stateless backend
- web server

Mental model:

```text
web application

Pod A
Pod B
Pod C

All replicas are generally interchangeable.
```

---

### DaemonSet — workload associated with nodes

Use a DaemonSet when a workload should run on nodes according to its scheduling rules.

Typical examples:

- log collection agents
- monitoring agents
- node-level networking components
- security agents

Mental model:

```text
Node 1 → agent
Node 2 → agent
Node 3 → agent
```

The important idea is that the desired Pod placement is tied to **eligible nodes**, rather than simply requesting N interchangeable replicas.

---

### StatefulSet — stable identity

Use a StatefulSet when Pods need stable identity and often stable persistent storage.

Typical examples:

- databases
- distributed storage systems
- clustered systems whose members have identities

Mental model:

```text
database-0
database-1
database-2
```

Unlike ordinary Deployment replicas, these members are not simply anonymous interchangeable copies.

---

# Pod Creation

## Deployment

A Deployment manages ReplicaSets:

```text
Deployment
    │
    ▼
ReplicaSet
    │
    ├── Pod
    ├── Pod
    └── Pod
```

The Pods are generally interchangeable.

---

## DaemonSet

A DaemonSet creates Pods according to node eligibility and scheduling rules.

```text
DaemonSet
   │
   ├── Node A → Pod
   ├── Node B → Pod
   ├── Node C → Pod
   └── Node D → Pod
```

When an eligible node joins the cluster, the DaemonSet can place its Pod there.

---

## StatefulSet

A StatefulSet creates Pods with stable ordinal identities.

For three replicas:

```text
web-0
web-1
web-2
```

The identity is meaningful.

If `web-1` is recreated, Kubernetes recreates that logical StatefulSet member rather than treating it as an unrelated anonymous replica.

---

# Scaling

## Deployment

Scaling changes the number of interchangeable replicas:

```text
replicas: 3

        ↓

replicas: 5
```

Result:

```text
Pod A
Pod B
Pod C
Pod D
Pod E
```

---

## DaemonSet

DaemonSet Pod count is primarily determined by the number of nodes that satisfy its scheduling requirements.

For example:

```text
3 eligible nodes
       ↓
3 DaemonSet Pods
```

If another eligible node joins:

```text
4 eligible nodes
       ↓
4 DaemonSet Pods
```

The actual count can be affected by node selectors, affinity, taints/tolerations, and other scheduling constraints.

---

## StatefulSet

Scaling changes the number of stable members.

For example:

```text
replicas: 3

web-0
web-1
web-2
```

Scaling to four adds:

```text
web-3
```

The ordinal identity is part of the workload model.

---

# Networking

## Deployment

Deployment Pods have individual Pod IPs, but those IPs are ephemeral.

Applications therefore commonly use a Service:

```text
Client
   │
   ▼
Service
   │
   ├── Pod A
   ├── Pod B
   └── Pod C
```

---

## DaemonSet

DaemonSet Pods receive normal Pod networking.

Because these workloads are often node-oriented, the networking pattern depends on the application.

For example, a node-level monitoring agent may communicate with local node resources rather than being consumed through a normal application Service.

A DaemonSet itself does **not** automatically create a Service.

---

## StatefulSet

StatefulSets are commonly paired with Headless Services when individual member discovery is required.

For example:

```text
Headless Service
       │
       ├── database-0
       ├── database-1
       └── database-2
```

A Headless Service can expose the individual Pod IPs through DNS rather than hiding them behind one virtual ClusterIP.

This is useful for distributed systems where clients need to identify individual members.

---

# Storage

## Deployment

Deployments are commonly used for stateless applications.

A Deployment can use PersistentVolumes, but it does not inherently require a unique persistent volume per replica.

---

## DaemonSet

DaemonSets can use storage when required by the workload.

For example, a node-level logging agent may mount node log directories.

Storage is not what defines a DaemonSet.

---

## StatefulSet

Persistent storage is a common StatefulSet use case.

A StatefulSet can use `volumeClaimTemplates` to create storage associated with individual members:

```text
web-0 → PVC-0
web-1 → PVC-1
web-2 → PVC-2
```

This gives each logical member its own persistent storage.

---

# Comparison

| Property | Deployment | DaemonSet | StatefulSet |
|---|---|---|---|
| Primary use | Stateless / interchangeable replicas | Node-level workload | Stateful / identity-aware workload |
| Pod identity | Generally interchangeable | Associated with node placement | Stable identity |
| Pod naming | Generated names | Generated names | Stable ordinal names |
| Scaling model | Replica count | Eligible node count | Replica count + ordinal members |
| Rolling updates | Yes | Yes | Yes, with StatefulSet-specific behavior |
| Networking | Often through Service | Depends on workload | Often paired with Headless Service |
| Stable network identity | Not inherently | Not inherently | Yes, through StatefulSet identity/DNS patterns |
| Persistent storage | Optional | Optional | Common use case |
| Typical examples | API, frontend, web server | Logging/monitoring agent | Database, distributed system |

---

# The Mental Model

### Deployment

> "I need N interchangeable copies of this application."

```text
Pod
Pod
Pod
Pod
```

### DaemonSet

> "I need this workload present on eligible nodes."

```text
Node → Pod
Node → Pod
Node → Pod
```

### StatefulSet

> "I need identifiable members of this application."

```text
app-0
app-1
app-2
```

The important distinction is not memorizing three controller names. It is understanding **what kind of identity and placement the workload requires**.

---

# 3. ReplicaSet vs Service

A ReplicaSet and a Service solve completely different problems.

The simplest mental model is:

> **ReplicaSet manages Pods. Service provides a way to reach Pods.**

---

# ReplicaSet Responsibility

A ReplicaSet is a workload controller.

Its job is to maintain the desired number of Pods matching its selector and Pod template.

For example:

```yaml
spec:
  replicas: 3
```

The ReplicaSet attempts to maintain:

```text
Pod A
Pod B
Pod C
```

If Pod B disappears:

```text
Pod A
Pod C
```

the ReplicaSet reconciles the difference and creates a replacement:

```text
Pod A
Pod C
Pod D
```

So:

```text
ReplicaSet
     │
     │ manages lifecycle / count
     ▼
   Pods
```

A ReplicaSet is **not responsible for networking**.

---

# Service Responsibility

A Service provides a stable networking and service-discovery abstraction in front of a set of Pods.

Pods are ephemeral.

Their IP addresses can change when Pods are recreated.

For example:

```text
Before:

web-1 → 10.244.0.10
web-2 → 10.244.0.11
web-3 → 10.244.0.12
```

If one Pod is recreated:

```text
web-1 → 10.244.0.25
web-2 → 10.244.0.11
web-3 → 10.244.0.12
```

A client should not need to track these changing IP addresses.

A Service provides a stable abstraction:

```text
Client
   │
   ▼
web-service
   │
   ├── web-1
   ├── web-2
   └── web-3
```

---

# Why Is a Service Required?

Imagine three Pods:

```text
web-1 → 10.244.0.10
web-2 → 10.244.0.11
web-3 → 10.244.0.12
```

If clients connect directly to those Pod IPs, they must know which Pods currently exist.

But Pods can:

- die
- be recreated
- be rescheduled
- receive new IP addresses

The Service hides that instability.

Instead of:

```text
Client → 10.244.0.10
```

the client can use:

```text
Client → web-service
```

For a normal ClusterIP Service:

```text
web-service
     │
     ▼
10.96.x.x
     │
     ▼
Service networking
     │
     ▼
Pod IP
```

The Service's stable identity remains even when its backend Pods change.

---

# How Does a Service Know Which Pods to Reach?

A Service commonly uses a label selector:

```yaml
selector:
  app: web
```

Matching Pods have:

```yaml
metadata:
  labels:
    app: web
```

Kubernetes maintains EndpointSlices representing the matching endpoints.

Conceptually:

```text
Service
   │
   │ selector: app=web
   ▼
EndpointSlice
   │
   ├── 10.244.0.10
   ├── 10.244.0.11
   └── 10.244.0.12
```

The Service does not own the Pods.

The workload controller does.

The Service uses the current endpoint set to determine where traffic can go.

---

# How Traffic Reaches Pods

For a normal ClusterIP Service, the conceptual flow is:

```text
Client Pod
    │
    │ DNS lookup
    ▼
web-service.clusterip-lab.svc.cluster.local
    │
    ▼
ClusterIP
10.96.x.x
    │
    ▼
Node networking / kube-proxy rules
    │
    │ backend selection + destination translation
    ▼
Pod IP
10.244.x.x
    │
    ▼
Web Pod
```

In the iptables mode we observed during the Session 11 lab, kube-proxy programmed rules that:

1. Match the Service ClusterIP and port.
2. Select an endpoint.
3. Jump to the endpoint chain.
4. DNAT the destination to the selected Pod IP.

So:

> **Service is the Kubernetes abstraction; the actual forwarding is implemented by the node's networking machinery.**

---

# ReplicaSet and Service Working Together

A typical application looks like:

```text
                 Deployment
                     │
                     ▼
                 ReplicaSet
                     │
             ┌───────┼───────┐
             ▼       ▼       ▼
           Pod A   Pod B   Pod C
             ▲       ▲       ▲
             │       │       │
             └───────┼───────┘
                     │
                  Service
                     │
                     ▼
                   Client
```

More precisely:

```text
ReplicaSet
    │
    │ creates/maintains
    ▼
  Pods
    │
    │ labels
    ▼
EndpointSlice
    ▲
    │
Service ────────── Client
```

The Service does not require those Pods to have been created by a ReplicaSet specifically.

The matching Pods could come from:

- Deployment
- ReplicaSet
- StatefulSet
- DaemonSet
- another controller
- or even direct Pod creation

The Service primarily cares about **which endpoints match its selector and are eligible to receive traffic**.

---

# What Happens When a Pod Dies?

Suppose:

```text
Service
  │
  ├── Pod A
  ├── Pod B
  └── Pod C
```

Pod B dies.

The workload controller creates a replacement:

```text
Pod A
Pod C
Pod D
```

Kubernetes updates the endpoint information:

```text
Service
  │
  ├── Pod A
  ├── Pod C
  └── Pod D
```

The client continues using the same Service name.

The client does not need to know that Pod B disappeared.

This gives us a clean separation:

```text
ReplicaSet / Deployment
        │
        │ Pod lifecycle
        ▼
       Pods
        │
        │ endpoint discovery
        ▼
     Service
        │
        │ stable access
        ▼
      Clients
```

---

# Headless Service — Important Exception

A Headless Service still uses a selector and EndpointSlices, but it has:

```yaml
clusterIP: None
```

There is therefore no virtual ClusterIP to route through.

Instead:

```text
Headless Service
       │
       ▼
     CoreDNS
       │
       ├── Pod IP
       ├── Pod IP
       └── Pod IP
```

For example:

```text
web-service-headless.default.svc.cluster.local
        │
        ├── 10.244.0.12
        ├── 10.244.0.13
        └── 10.244.0.14
```

This allows clients to discover individual service members.

---

# Final Mental Model

Keep these responsibilities separate:

```text
                 WORKLOAD SIDE

Deployment
    │
    │ manages revisions
    ▼
ReplicaSet
    │
    │ maintains replicas
    ▼
Pods


                 NETWORKING SIDE

Pods
    │
    │ selected by labels
    ▼
EndpointSlice
    ▲
    │
Service
    │
    │ stable discovery/access
    ▼
Clients
```

### One-line memory trick

```text
Deployment → "Which version should run?"
ReplicaSet → "How many Pods should exist?"
Service    → "How do clients reach those Pods?"
```

And for the three workload controllers:

```text
Deployment → interchangeable replicas
DaemonSet  → workload per eligible node
StatefulSet → stable identity / stateful members
```
