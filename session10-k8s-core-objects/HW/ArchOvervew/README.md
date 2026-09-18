# Task 10: Theoretical & Architectural Concepts

## 1. `containerPort`, `targetPort`, `port`, and `nodePort`

These are mainly used when connecting a **Pod to a Kubernetes Service**.

* **`containerPort`** – The port on which the application is running **inside the container**.
* **`targetPort`** – The Pod/container port where the **Service sends traffic**.
* **`port`** – The port on which the **Kubernetes Service** is available inside the cluster.
* **`nodePort`** – A port opened on **each Worker Node** to allow access to the Service from outside the cluster.

### Simple Flow:

**User → nodePort → Service port → targetPort → Pod/Container**

---

## 2. Labels vs Selectors

* **Labels** – Tags attached to Kubernetes objects such as Pods.

  * Example: `app: frontend`
  * They help identify and organize objects.

* **Selectors** – Rules used to **find objects with specific labels**.

  * Example: `app: frontend`
  * A Service uses selectors to find the Pods to which it should send traffic.

### Simple Difference:

**Label = Tag**
**Selector = Search for that tag**

---

## 3. Deployment Strategies

Deployment strategies define **how a new version of an application is released**.

* **RollingUpdate**

  * Replaces old Pods with new Pods gradually.
  * Old and new versions may run at the same time.
  * Usually avoids downtime.

* **Blue-Green**

  * Keeps two environments: **Blue = old version**, **Green = new version**.
  * Traffic is switched from Blue to Green when the new version is ready.
  * Easy to switch back if needed.

* **Canary**

  * New version is given to a **small percentage of users/traffic first**.
  * If everything works correctly, more traffic is gradually moved to the new version.

* **Recreate**

  * Stops/deletes the old Pods first.
  * Then starts the new Pods.
  * This can cause **downtime**.

---

## 4. `maxSurge` vs `maxUnavailable`

These settings are mainly used with **RollingUpdate**.

* **`maxSurge`** – Maximum number of **extra Pods** that can be created above the desired number.
* **`maxUnavailable`** – Maximum number of desired Pods that can be **unavailable** during the update.

### Example:

Suppose we have **10 Pods** and:

* `maxSurge: 20%` → `20% of 10 = 2`

  * Kubernetes can temporarily create **2 extra Pods**.
  * Maximum = **12 Pods**.

* `maxUnavailable: 20%` → `20% of 10 = 2`

  * Up to **2 Pods** can be unavailable.
  * At least **8 Pods** should remain available.

**In short:**

`maxSurge` = **How many extra Pods can be added?**
`maxUnavailable` = **How many Pods can be unavailable?**

---

## 5. Resource Requests vs Limits

Kubernetes uses **Requests** and **Limits** to control CPU and memory usage.

* **Resource Request**

  * The amount of CPU/memory a container **needs/reserves**.
  * The scheduler uses requests when deciding where to place the Pod.

* **Resource Limit**

  * The **maximum amount** of CPU/memory a container is allowed to use.
  * Prevents one container from using unlimited resources.

### Example:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

Here:

* **Request:** 256 MiB memory and 250m CPU
* **Limit:** 512 MiB memory and 500m CPU

---

## 6. GB vs GiB

Both represent units of storage/memory, but they are calculated differently.

* **GB (Gigabyte)** = **1,000,000,000 bytes** (decimal)
* **GiB (Gibibyte)** = **1,073,741,824 bytes** (binary)

So:

**1 GiB ≈ 1.074 GB**

In Kubernetes, memory is commonly written using binary units such as **Mi** and **Gi**.

* `1Gi` = 1024 MiB
* `1Mi` = 1024 KiB