# Kubernetes FQDN & CoreDNS: The Ultimate Beginner-Friendly Guide

> **"How do Pods talk to each other without knowing each other's IP addresses?"**  
> Answer: **CoreDNS** and **FQDN** (Fully Qualified Domain Name).  
> Let's demystify how Kubernetes internal naming works using simple, everyday language and clear diagrams!

---

## 📌 Table of Contents
1. [What is an FQDN](#1-what-is-an-fqdn)
2. [The Anatomy of a Kubernetes FQDN](#2-the-anatomy-of-a-kubernetes-fqdn)
3. [What is CoreDNS? (The Cluster Phonebook)](#3-what-is-coredns-the-cluster-phonebook)
4. [How a DNS Query Works (Step-by-Step Flow Diagram)](#4-how-a-dns-query-works-step-by-step-flow-diagram)
5. [Inside a Pod: The Magic of `/etc/resolv.conf`](#5-inside-a-pod-the-magic-of-etcresolvconf)
6. [Short Name vs Long Name (Same vs Cross-Namespace)](#6-short-name-vs-long-name-same-vs-cross-namespace)
7. [FQDN for Services vs FQDN for Pods](#7-fqdn-for-services-vs-fqdn-for-pods)
8. [Hands-on Practice: How to Test DNS in Your Cluster](#8-hands-on-practice-how-to-test-dns-in-your-cluster)
9. [Top 3 Real-World DNS Issues & DevOps Interview Questions](#9-top-3-real-world-dns-issues--devops-interview-questions)
10. [Quick Recap Cheat Sheet](#10-quick-recap-cheat-sheet)

---

## 1. What is an FQDN

**FQDN** stands for **Fully Qualified Domain Name**.

#### Think of it like this:
If you are sitting in your living room with your brother Rahul, you can just yell:
> *"Hey Rahul, pass the remote!"*  
> (This is a **Short Name**). Everyone in the room knows exactly who you mean.

But what if you want to send a letter through the post office to a friend named Rahul in another city?  
Writing just *"Rahul"* on the envelope will fail. You must write the complete address:
> `Rahul Sharma, Flat 402, Sunshine Heights, Mumbai, Maharashtra, India`  
> (This is the **FQDN**). It leaves zero room for confusion anywhere in the world.

In Kubernetes:
- Inside the same namespace: You can use the short name (`backend`).
- Across namespaces or external systems: You need the complete address (**FQDN**).

---

## 2. The Anatomy of a Kubernetes FQDN

Every Service in Kubernetes gets an automatic, official FQDN that looks like this:

```text
  payment-service .  production  .   svc   .  cluster.local
  └──────┬──────┘   └─────┬────┘    └──┬──┘  └──────┬──────┘
         │                │            │            │
    Service Name      Namespace     Object Type   Cluster Domain
```

Let's break down each piece:

| Segment | What it is | Meaning |
| :--- | :--- | :--- |
| **`payment-service`** | Service Name | The exact name you gave your Service in `metadata.name`. |
| **`production`** | Namespace | The namespace where your Service is deployed (e.g., `default`, `prod`, `dev`). |
| **`svc`** | Resource Type | Tells CoreDNS this is a **Service** (as opposed to a `pod`). |
| **`cluster.local`** | Cluster Domain | The base root domain of your Kubernetes cluster (configured during cluster setup; default is `cluster.local`). |

---

## 3. What is CoreDNS? (The Cluster Phonebook)

When you deploy Kubernetes, it automatically runs a built-in DNS server called **CoreDNS** inside the `kube-system` namespace.

#### Think of it like this:
CoreDNS is the **hotel operator**:
- When Pod A wants to talk to `payment-service`, Pod A doesn't know what IP `payment-service` has.
- Pod A calls the hotel operator (CoreDNS) and asks: *"What is the IP of `payment-service`?"*
- CoreDNS looks at its phonebook, replies: *"It's `10.96.45.12`"*, and Pod A connects straight away!

```bash
# You can see CoreDNS running in your cluster anytime:
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Output:
```text
NAME                       READY   STATUS    RESTARTS   AGE
coredns-768b85b76f-8j2k4   1/1     Running   0          5d
coredns-768b85b76f-vx4qp   1/1     Running   0          5d
```

CoreDNS automatically watches the Kubernetes API. Whenever you create, update, or delete a Service, CoreDNS instantly adds or removes its DNS record in real time!

---

## 4. How a DNS Query Works (Step-by-Step Flow Diagram)

Here is what happens in milliseconds when Pod `frontend` wants to talk to `backend`:

```text
+-----------------------------------------------------------------------+
| 1. Frontend Pod runs: curl http://backend                             |
+-----------------------------------------------------------------------+
                                  │
                                  ▼
+-----------------------------------------------------------------------+
| 2. Linux checks /etc/resolv.conf inside the Pod                       |
|    - Nameserver points to: 10.96.0.10 (CoreDNS Service IP)           |
|    - Appends search domain: backend.production.svc.cluster.local     |
+-----------------------------------------------------------------------+
                                  │
                                  ▼
+-----------------------------------------------------------------------+
| 3. Query sent to CoreDNS Pod (in kube-system)                         |
|    "Hey CoreDNS, what is the IP of backend.production.svc.cluster.local?"|
+-----------------------------------------------------------------------+
                                  │
                                  ▼
+-----------------------------------------------------------------------+
| 4. CoreDNS returns Service ClusterIP: 10.96.200.55                    |
+-----------------------------------------------------------------------+
                                  │
                                  ▼
+-----------------------------------------------------------------------+
| 5. Frontend Pod sends the actual HTTP request to 10.96.200.55         |
|    kube-proxy routes packet to one of the backend Pods                |
+-----------------------------------------------------------------------+
```

---

## 5. Inside a Pod: The Magic of `/etc/resolv.conf`

Whenever Kubernetes spins up any Pod, it automatically injects a DNS configuration file at `/etc/resolv.conf`.

If you run `cat /etc/resolv.conf` inside any container, you will see something like this:

```ini
nameserver 10.96.0.10
search production.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

### What do these 3 lines mean?

1. **`nameserver 10.96.0.10`**:  
   This is the internal ClusterIP of the `kube-dns` / CoreDNS Service. Every DNS lookup your container makes goes directly to this IP.

2. **`search ...` (The autocomplete list)**:  
   If you type a short name like `curl http://backend`, Linux automatically tries appending these suffixes one by one until it finds a match:
   - 1st attempt: `backend.production.svc.cluster.local` (Found! Resolves immediately!)
   - 2nd attempt: `backend.svc.cluster.local`
   - 3rd attempt: `backend.cluster.local`

3. **`options ndots:5`**:  
   Tells Linux: *"If a name has fewer than 5 dots in it, check the search suffixes first before trying to resolve it as an external public domain."*

---

## 6. Short Name vs Long Name (Same vs Cross-Namespace)

This is one of the most common everyday scenarios for DevOps engineers.

### Scenario A: Both Pods in the **SAME** namespace (`production`)

Both `frontend` and `backend` are in `production`.

```text
[Frontend Pod]  ─── curl http://backend ───►  [Backend Service]
```
✅ You can use the simple short name:
```bash
curl http://backend
```
*Why does this work?*  
Because `/etc/resolv.conf` automatically appends `production.svc.cluster.local`, which matches your backend service!

---

### Scenario B: Pods in **DIFFERENT** namespaces (`dev` talking to `production`)

Your test runner pod is in namespace **`dev`**, but it needs to call a service in namespace **`production`**.

```text
Namespace: [dev]                               Namespace: [production]
[Test Runner Pod] ── curl http://backend ──► ❌ FAILS! (looks for backend.dev...)
[Test Runner Pod] ── curl http://backend.production ──► ✅ SUCCESS!
```

If you just type `curl http://backend`, Linux will look for `backend.dev.svc.cluster.local` and fail with `404 Name Not Found`.

**The Solution:**
You must provide at least the namespace:
```bash
# Option 1: Service + Namespace (Most common in microservices configs)
curl http://backend.production

# Option 2: Full FQDN (Bulletproof, 100% unambiguous)
curl http://backend.production.svc.cluster.local
```

---

## 7. FQDN for Services vs FQDN for Pods

Did you know individual Pods can also have their own DNS names? Here is how they compare:

### 1. Standard Service FQDN
```text
<service-name>.<namespace>.svc.cluster.local
```
- **Returns:** The single virtual **ClusterIP** of the service.
- **Example:** `auth-svc.default.svc.cluster.local` -> `10.96.100.24`

---

### 2. StatefulSet Pods with Headless Service
When you use a **Headless Service** (`clusterIP: None`) with a **StatefulSet**, every single replica Pod gets its own permanent, dedicated DNS record:

```text
<pod-name>.<service-name>.<namespace>.svc.cluster.local
```
- **Example:** In a Kafka cluster with 3 brokers:
  - `kafka-0.kafka-service.prod.svc.cluster.local`
  - `kafka-1.kafka-service.prod.svc.cluster.local`
  - `kafka-2.kafka-service.prod.svc.cluster.local`
- **Why this matters:** Each Kafka broker or MongoDB replica can find its specific peers directly!

---

### 3. Ordinary Pod IP-based FQDN
Even regular pods get a DNS entry based on their IP address (replacing dots with dashes):
```text
<pod-ip-with-dashes>.<namespace>.pod.cluster.local
```
- **Example:** A pod with IP `10.244.2.85` in namespace `default`:
  `10-244-2-85.default.pod.cluster.local`

---

## 8. Hands-on Practice: How to Test DNS in Your Cluster

Want to test DNS resolution inside your cluster right now? Here is the standard DevOps diagnostic trick:

### Step 1: Spin up a temporary DNS testing pod
Run a lightweight diagnostic pod with `nslookup` and `curl` installed:

```bash
kubectl run dnsutils --rm -it --image=ghcr.io/nestybox/curl:latest -- sh
```
*(Or use `busybox:1.28` / `tutum/dnsutils`)*

### Step 2: Test Service Name Resolution
Inside the interactive shell, run:

```bash
# 1. Test short name (resolves if in same namespace)
nslookup kubernetes

# 2. Test full FQDN
nslookup kubernetes.default.svc.cluster.local

# 3. Check what DNS server you are hitting
cat /etc/resolv.conf
```

### Expected Output:
```text
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   kubernetes.default.svc.cluster.local
Address: 10.96.0.1
```

If `nslookup` returns the IP, your CoreDNS is healthy and working perfectly!

---

## 9. Top 3 Real-World DNS Issues & DevOps Interview Questions

### ❓ Question 1: "My pod in the `staging` namespace cannot connect to a database in `prod`. What is the issue?"
> **Answer:**  
> The application is likely configured with just the short name `DB_HOST=mysql`.  
> Since they are in different namespaces, the pod's DNS search path will look for `mysql.staging.svc.cluster.local` and fail.  
> **Fix:** Change the host configuration to `mysql.prod` or the full FQDN `mysql.prod.svc.cluster.local`.

---

### ❓ Question 2: "What is `ndots:5` in `/etc/resolv.conf` and why do senior engineers care about it?"
> **Answer:**  
> By default, Linux considers any domain with fewer than 5 dots (`ndots:5`) to be a partial name and appends the search domains first.  
> If your application makes a call to an external website like `api.stripe.com` (only 2 dots):
> 1. It queries: `api.stripe.com.production.svc.cluster.local` (NXDOMAIN - Fail)
> 2. It queries: `api.stripe.com.svc.cluster.local` (NXDOMAIN - Fail)
> 3. It queries: `api.stripe.com.cluster.local` (NXDOMAIN - Fail)
> 4. Finally it queries: `api.stripe.com` (Success!)
> 
> That's **3 useless DNS queries** causing latency on high-throughput microservices!  
> **Fix:** Add a trailing dot in your app config (`api.stripe.com.`) to tell DNS it is already fully qualified, or configure `dnsConfig.options` in the Pod spec to lower `ndots` (e.g., `ndots:2`).

---

### ❓ Question 3: "CoreDNS pods are in CrashLoopBackOff. What is the most common cause?"
> **Answer:**  
> **DNS forwarding loop!**  
> If the host node's `/etc/resolv.conf` points to `127.0.0.53` (systemd-resolved) or `127.0.0.1`, CoreDNS inherits this as its upstream server. When CoreDNS forwards an unknown query to localhost, it loops back to itself, detects an infinite loop, and intentionally crashes.  
> **Fix:** Configure `kubelet` with `--resolv-conf=/run/systemd/resolve/resolv.conf` or specify a public upstream DNS (like `8.8.8.8`) in the CoreDNS ConfigMap.

---

## 10. Quick Recap Cheat Sheet

```text
┌───────────────────────────────┬─────────────────────────────────────────────────────────────┐
│ Concept                       │ Quick Memory Hook                                           │
├───────────────────────────────┼─────────────────────────────────────────────────────────────┤
│ FQDN Format                   │ <service>.<namespace>.svc.cluster.local                     │
│ CoreDNS Location              │ Pods running in kube-system namespace                       │
│ Internal DNS IP               │ Typically 10.96.0.10 (configured in /etc/resolv.conf)       │
│ Same Namespace                │ Just use the service name: curl http://my-service           │
│ Different Namespace           │ Must add namespace: curl http://my-service.<namespace>      │
│ StatefulSet Pod FQDN          │ <pod-name>.<service-name>.<namespace>.svc.cluster.local     │
│ Diagnostic Tool               │ nslookup <fqdn> or dig <fqdn> inside a test pod             │
└───────────────────────────────┴─────────────────────────────────────────────────────────────┘
```
