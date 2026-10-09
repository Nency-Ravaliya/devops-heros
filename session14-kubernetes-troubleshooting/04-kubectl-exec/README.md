# `kubectl exec`


```bash
kubectl exec
```

Think of it as:

> "Let me enter the container and check what is happening from inside."

---

## 1. Create the Pod

```bash
kubectl apply -f pod.yaml
```

Check:

```bash
kubectl get pod exec-demo
```

Expected output:

```text
NAME        READY   STATUS
exec-demo   1/1     Running
```

---

## 2. Open a Shell

Run:

```bash
kubectl exec -it exec-demo -- bash
```

You should get a shell inside the container. You may see:

```text
root@exec-demo:/#
```

---

## 3. Check Files

Inside the container:

```bash
ls
```

Then:

```bash
ls /usr/share/nginx/html
```

You should see files related to the Nginx default page.

---

## 4. Check the Application

Run:

```bash
curl localhost
```

If `curl` is available, you should receive HTML output.

You can also try:

```bash
nginx -T
```

to inspect Nginx configuration.

---

## 5. Exit

```bash
exit
```

---

## 6. Run One Command Without Opening Shell

You don't always need an interactive shell.

For example:

```bash
kubectl exec exec-demo -- hostname
```

Or:

```bash
kubectl exec exec-demo -- ls /usr/share/nginx/html
```

---

## 7. Why Is `exec` Useful?

Suppose: **Service is not working**.

You can enter a Pod and test:

```bash
curl localhost
```

If localhost works:

```text
Application
     │
     ▼
  Working
```

Then you can investigate:
* Service
* DNS
* Network
* Port

This helps us narrow down the problem.

---

## Important

`kubectl exec` works with a running container.

If the container is constantly crashing, `exec` may not be useful because there may be no stable running container to enter.

For those cases, use:

```bash
kubectl logs
kubectl describe
kubectl debug
```

---

## Useful Commands

```bash
kubectl exec -it exec-demo -- bash
kubectl exec exec-demo -- hostname
kubectl exec exec-demo -- ls
kubectl exec exec-demo -- cat /etc/hosts
```

---

## Key Learning

Remember:

```text
kubectl exec
     │
     ▼
"Let me check from INSIDE the container."
```

Kubernetes documentation also recommends `kubectl exec` for running commands inside a container while debugging.

---

## Reference

* **Get a Shell to a Running Container:**  
  https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/
