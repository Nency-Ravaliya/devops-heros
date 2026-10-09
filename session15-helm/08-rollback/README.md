# Rollback

```bash
helm rollback my-app 1
```

If an upgrade breaks your application, rollback returns you to a previous working revision in seconds.

---

## 1. Why Rollback Matters

```text
Revision 1: Working (1 replica, nginx:1.24)
Revision 2: Broken  (bad image tag: nginx:doesnotexist)
```

Without Helm rollback, you must manually fix YAML and re-apply.  
With Helm rollback, you type one command.

---

## 2. Setup: Install the Chart

Use the `app-chart` from topic 07.

```bash
helm install rollback-demo ./app-chart
```

Expected output:

```text
NAME: rollback-demo
STATUS: deployed
REVISION: 1
```

---

## 3. Upgrade to a Broken Version

```bash
helm upgrade rollback-demo ./app-chart --set image.tag=doesnotexist
```

Check the pods:

```bash
kubectl get pods
```

Expected output:

```text
NAME                         READY   STATUS             RESTARTS
rollback-demo-app-xxxx       0/1     ImagePullBackOff   0
```

The pod fails because the image tag does not exist.

---

## 4. Check Release History

```bash
helm history rollback-demo
```

Expected output:

```text
REVISION   STATUS      DESCRIPTION
1          superseded  Install complete
2          deployed    Upgrade complete
```

*(Revision 2 is the broken one even though the pod is failing.)*

---

## 5. Rollback to Revision 1

```bash
helm rollback rollback-demo 1
```

Expected output:

```text
Rollback was a success! Happy Helming!
```

---

## 6. Check Pods After Rollback

```bash
kubectl get pods
```

Expected output:

```text
NAME                         READY   STATUS    RESTARTS
rollback-demo-app-yyyy       1/1     Running   0
```

The pod is healthy again. Helm re-deployed revision 1's configuration.

---

## 7. History After Rollback

```bash
helm history rollback-demo
```

Expected output:

```text
REVISION   STATUS      DESCRIPTION
1          superseded  Install complete
2          superseded  Upgrade complete
3          deployed    Rollback to 1
```

Rollback creates a new revision (3). It does not delete the history.

---

## 8. Use --atomic for Auto Rollback

During upgrade, use `--atomic` to auto-rollback on failure:

```bash
helm upgrade rollback-demo ./app-chart \
  --set image.tag=doesnotexist \
  --atomic \
  --timeout 60s
```

If pods do not become ready within 60 seconds, Helm automatically rolls back.

---

## Clean Up

```bash
helm uninstall rollback-demo
```

---

## Key Learning

```text
helm history <release>     = list all revisions
helm rollback <release> N  = go back to revision N
--atomic                   = auto rollback if upgrade fails
```

---

## Reference

* **Helm rollback:** https://helm.sh/docs/helm/helm_rollback/
