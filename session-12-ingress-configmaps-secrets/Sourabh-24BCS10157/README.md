# Session 12 - Kubernetes Ingress, ConfigMaps & Secrets

**Name:** Sourabh Srivastva
**Enrollment Number:** 24BCS10157

I used the full demo from `04-full-demo/`. It contains a ConfigMap and Secret used by the backend, along with a frontend and an Ingress that routes `/` and `/api/` to different services.

## 1. ConfigMap

```text
$ kubectl apply -f 04-full-demo/configmap.yaml
configmap/yatri-app-config created

$ kubectl get configmap yatri-app-config
NAME               DATA   AGE
yatri-app-config   5      1s

$ kubectl describe configmap yatri-app-config
Name:         yatri-app-config
Namespace:    default
Labels:       app=yatri-app
Data
====
APP_PORT:
----
5000
DEFAULT_CURRENCY:
----
INR
ENVIRONMENT:
----
production
LOG_LEVEL:
----
INFO
MAX_BOOKING_DAYS:
----
30
```

A ConfigMap stores configuration separately from the container image. This means the same image can be used in different environments with different configuration values.

Since ConfigMaps are not intended for sensitive information, `describe` shows their values directly.

## 2. Secret

```text
$ kubectl apply -f 04-full-demo/secret.yaml
secret/yatri-db-secret created

$ kubectl get secret yatri-db-secret
NAME              TYPE     DATA   AGE
yatri-db-secret   Opaque   3      0s

$ kubectl describe secret yatri-db-secret
Name:         yatri-db-secret
Namespace:    default
Labels:       app=yatri-app
Type:         Opaque
Data
====
POSTGRES_DB:        19 bytes
POSTGRES_PASSWORD:  14 bytes
POSTGRES_USER:      11 bytes
```

Unlike the ConfigMap, `describe` only shows the size of each Secret value rather than the actual values.

I also checked the stored password:

```text
$ kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}'
$ [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('c2VjcmV0cGFzc3dvcmQ='))
c2VjcmV0cGFzc3dvcmQ=secretpassword
```

The first value is the Base64-encoded password and the second is the decoded value.

This showed that Base64 is only an encoding mechanism, not encryption. Access control such as RBAC is therefore important for protecting Secrets.

Since I am using PowerShell, I used `[Convert]` to decode the value instead of the Linux `base64 -d` command.

## 3. Injecting ConfigMap and Secret into a Pod

The backend uses the ConfigMap with `envFrom` and individual Secret values with `secretKeyRef`.

```text
$ kubectl exec deploy/yatri-backend -- env | Select-String 'ENVIRONMENT|LOG_LEVEL|CURRENCY|POSTGRES'

ENVIRONMENT=production
LOG_LEVEL=INFO
POSTGRES_USER=yatri_admin
POSTGRES_PASSWORD=secretpassword
POSTGRES_DB=yatri_production_db
DEFAULT_CURRENCY=INR
```

Both ConfigMap and Secret values are available to the application as environment variables. The application can read them normally without needing to know where the values originally came from.

The Secret value is also visible inside the container's environment, which means anyone who has sufficient access to exec into the pod may be able to read it.

## 4. Ingress

Before creating the Ingress, I enabled the Minikube Ingress controller:

```bash
minikube addons enable ingress
```

Then I applied the Ingress configuration:

```text
$ kubectl apply -f 04-full-demo/ingress.yaml
ingress.networking.k8s.io/yatri-ingress created

$ kubectl get ingress yatri-ingress

NAME            CLASS   HOSTS         ADDRESS   PORTS   AGE
yatri-ingress   nginx   yatri.local             80      0s

$ kubectl describe ingress yatri-ingress

Name:             yatri-ingress
Labels:           app=yatri-app
Namespace:        default
Address:
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host         Path  Backends
  ----         ----  --------
  yatri.local
               /api(/|$)(.*)   yatri-backend-service:80 (10.244.0.99:5000,10.244.0.98:5000)
               /               yatri-frontend-service:80 (10.244.0.97:80,10.244.0.96:80)
Annotations:   nginx.ingress.kubernetes.io/rewrite-target: /$2
               nginx.ingress.kubernetes.io/ssl-redirect: false
               nginx.ingress.kubernetes.io/use-regex: true
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  Sync    0s    nginx-ingress-controller  Scheduled for sync
```

The Ingress has two routing rules:

* `/api/` → `yatri-backend-service`
* `/` → `yatri-frontend-service`

The backend has two pods listening on port 5000, while the frontend has two pods listening on port 80.

The `ADDRESS` field was empty when I checked because the Ingress had just been created. The controller was still processing it.

## 5. Testing the Ingress Routing

Since `yatri.local` was not added to my Windows hosts file, I accessed the Ingress controller directly and manually supplied the Host header.

```text
$ kubectl exec curl-test -- curl -s -H "Host: yatri.local" http://10.100.94.74/api/

Yatri Backend API
=================
ENVIRONMENT     : production
LOG_LEVEL       : INFO
DEFAULT_CURRENCY: INR
POSTGRES_USER   : yatri_admin
POSTGRES_DB     : yatri_production_db

$ kubectl exec curl-test -- curl -s -H "Host: yatri.local" http://10.100.94.74/

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

Both requests used the same IP and port, but different paths were routed to different services.

* `/api/` was routed to the backend.
* `/` was routed to the frontend.

The backend response also confirmed that the ConfigMap and Secret values were successfully injected into the application.

The `Host: yatri.local` header was required because the Ingress rule is associated with that hostname.

The annotation:

```text
nginx.ingress.kubernetes.io/rewrite-target: /$2
```

rewrites the `/api/` path before sending the request to the backend. The regular expression `(/|$)(.*)` provides the capture group used by `$2`.

---

## What I Learned

ConfigMaps and Secrets both allow configuration to be kept outside the container image. ConfigMaps expose normal configuration values, while Secrets are handled more carefully and their values are not shown by `describe`. However, Base64 encoding by itself is not encryption.

I also learned that Services and Ingress work at different levels. A Service provides networking to a set of pods, while an Ingress can route HTTP requests based on the hostname and path.

An Ingress object also needs an Ingress controller to actually process its rules. Creating the object alone does not perform the routing.

Finally, the demo showed how ConfigMaps, Secrets, Services, and Ingress can work together: configuration is injected into the backend, Services provide access to the pods, and the Ingress provides a single entry point that routes requests to the appropriate service.
