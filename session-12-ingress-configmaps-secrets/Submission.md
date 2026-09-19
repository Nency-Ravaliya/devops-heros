# <span style="font-size: 32px; font-weight: 800; color: #2563eb;">ConfigMap-01:</span>

<pre style="background-color: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 8px; font-family: 'Consolas', 'Courier New', monospace; font-size: 13.5px; line-height: 1.45; overflow-x: auto; border: 1px solid #313244;"><code><span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-11-kubernetes-services</span>$ cd ..
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main</span>$ cd session-12-ingress-configmaps-secrets
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets</span>$ ls
01-configmap  02-secret  03-ingress  04-full-demo  lab.md  troubleshooting
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets</span>$ cd 01-configmap
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/01-configmap</span>$ kubectl apply -f configmap/app-config.yaml
error: the path "configmap/app-config.yaml" does not exist
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/01-configmap</span>$ kubectl apply -f app-config.yaml
configmap/yatri-app-config created
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/01-configmap</span>$ kubectl get yatri-app-config
error: the server doesn't have a resource type "yatri-app-config"
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/01-configmap</span>$ kubectl get configmap yatri-app-config
NAME               DATA   AGE
yatri-app-config   5      24s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/01-configmap</span>$ kubectl describe configmap yatri-app-config
Name:         yatri-app-config
Namespace:    default
Labels:       app=yatri-backend
Annotations:  &lt;none&gt;

Data
====
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

PORT:
----
5000


BinaryData
====

Events:  &lt;none&gt;
</code></pre>

---

# <span style="font-size: 32px; font-weight: 800; color: #2563eb;">Secret-02:</span>

<pre style="background-color: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 8px; font-family: 'Consolas', 'Courier New', monospace; font-size: 13.5px; line-height: 1.45; overflow-x: auto; border: 1px solid #313244;"><code><span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/01-configmap</span>$ kubectl apply -f db-secret.yaml
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/01-configmap</span>$ cd ..
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets</span>$ ls
01-configmap  02-secret  03-ingress  04-full-demo  lab.md  troubleshooting
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets</span>$ cd 02-secret
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/02-secret</span>$ kubectl apply -f secret/db-secret.yaml
error: the path "secret/db-secret.yaml" does not exist
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/02-secret</span>$ kubectl apply -f db-secret.yaml
secret/yatri-db-secret created
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/02-secret</span>$ kubectl get secret yatri-db-secret
NAME              TYPE     DATA   AGE
yatri-db-secret   Opaque   3      8s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/02-secret</span>$ ^C
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/02-secret</span>$ kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
secretpassword
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/02-secret</span>$ echo -n "yatri_admin" | base64
eWF0cmlfYWRtaW4=
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/02-secret</span>$ echo -n "secretpassword" | base64
c2VjcmV0cGFzc3dvcmQ=
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/02-secret</span>$ echo -n "yatri_production_db" | base64
eWF0cmlfcHJvZHVjdGlvbl9kYg==
</code></pre>

---

# <span style="font-size: 32px; font-weight: 800; color: #2563eb;">FullDemo_04:</span>

<pre style="background-color: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 8px; font-family: 'Consolas', 'Courier New', monospace; font-size: 13.5px; line-height: 1.45; overflow-x: auto; border: 1px solid #313244;"><code><span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main</span>$ cd session-12-ingress-configmaps-secrets
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets</span>$ cd 04-full-demo
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ minikube start docker-desktop
😄  minikube v1.39.0 on Ubuntu 26.04 (kvm/amd64)
✨  Using the docker driver based on existing profile
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🚜  Pulling base image v0.0.51 ...
🔄  Restarting existing docker container for "minikube" ...
📦  Preparing Kubernetes v1.37.0 on containerd 2.3.4 ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
    ▪ Using image registry.k8s.io/ingress-nginx/controller:v1.15.1
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
🔎  Verifying ingress addon...
🌟  Enabled addons: default-storageclass, storage-provisioner, ingress

❗  /usr/local/bin/kubectl is version 1.34.1, which may have incompatibilities with Kubernetes 1.37.0.
    ▪ Want kubectl v1.37.0? Try 'minikube kubectl -- get pods -A'
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl config current-context
minikube
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl apply -f 04-full-demo/configmap.yaml
error: the path "04-full-demo/configmap.yaml" does not exist
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl describe configmap yatri-app-config
Name:         yatri-app-config
Namespace:    default
Labels:       app=yatri-backend
Annotations:  &lt;none&gt;

Data
====
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

PORT:
----
5000


BinaryData
====

Events:  &lt;none&gt;
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl apply -f configmap.yaml
configmap/yatri-app-config configured
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl describe configmap yatri-app-config
Name:         yatri-app-config
Namespace:    default
Labels:       app=yatri-app
Annotations:  &lt;none&gt;

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


BinaryData
====

Events:  &lt;none&gt;
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl apply -f secret.yaml
secret/yatri-db-secret configured
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl describe secret yatri-db-secret
Name:         yatri-db-secret
Namespace:    default
Labels:       app=yatri-app
Annotations:  &lt;none&gt;

Type:  Opaque

Data
====
POSTGRES_DB:        19 bytes
POSTGRES_PASSWORD:  14 bytes
POSTGRES_USER:      11 bytes
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl apply -f frontend.yaml
deployment.apps/yatri-frontend created
service/yatri-frontend-service created
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get pods -l app=yatri-frontend
NAME                             READY   STATUS    RESTARTS   AGE
yatri-frontend-ddcfc4b5f-j7czj   1/1     Running   0          14s
yatri-frontend-ddcfc4b5f-p4v4d   1/1     Running   0          14s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get svc yatri-frontend-service
NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
yatri-frontend-service   ClusterIP   10.107.93.193   &lt;none&gt;        80/TCP    14s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl apply -f backend.yaml
deployment.apps/yatri-backend created
service/yatri-backend-service created
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl rollout status deployment/yatri-backend --timeout=90s
deployment "yatri-backend" successfully rolled out
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get pods -l app=yatri-backend
NAME                             READY   STATUS    RESTARTS   AGE
yatri-backend-6c58cb99c7-db4hk   1/1     Running   0          32s
yatri-backend-6c58cb99c7-fbfzt   1/1     Running   0          32s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get svc yatri-backend-service
NAME                    TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
yatri-backend-service   ClusterIP   10.97.215.2   &lt;none&gt;        80/TCP    33s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl apply -f ingress.yaml
ingress.networking.k8s.io/yatri-ingress configured
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingress yatri-ingress
NAME            CLASS   HOSTS         ADDRESS        PORTS   AGE
yatri-ingress   nginx   yatri.local   192.168.49.2   80      90m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl describe ingress yatri-ingress
Name:             yatri-ingress
Labels:           app=yatri-app
Namespace:        default
Address:          192.168.49.2
Ingress Class:    nginx
Default backend:  &lt;default&gt;
Rules:
  Host         Path  Backends
  ----         ----  --------
  yatri.local  
               /api(/|$)(.*)   yatri-backend-service:80 (10.244.0.6:5000,10.244.0.7:5000)
               /               yatri-frontend-service:80 (10.244.0.5:80,10.244.0.4:80)
Annotations:   nginx.ingress.kubernetes.io/rewrite-target: /$2
               nginx.ingress.kubernetes.io/ssl-redirect: false
               nginx.ingress.kubernetes.io/use-regex: true
Events:
  Type    Reason  Age                  From                      Message
  ----    ------  ----                 ----                      -------
  Normal  Sync    83m (x2 over 84m)    nginx-ingress-controller  Scheduled for sync
  Normal  Sync    59m (x3 over 60m)    nginx-ingress-controller  Scheduled for sync
  Normal  Sync    10s (x4 over 9m58s)  nginx-ingress-controller  Scheduled for sync
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ echo "$(minikube ip) yatri.local" | sudo tee -a /etc/hosts
[sudo: authenticate] Password:          
sudo: Authentication failed, try again.
[sudo: authenticate] Password:        
sudo: Authentication failed, try again.
[sudo: authenticate] Password: 

<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ echo "$(minikube ip) yatri.local" | sudo tee -a /etc/hosts
[sudo: authenticate] Password:        
192.168.49.2 yatri.local
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ cat /etc/hosts | grep yatri.local
192.168.49.2 yatri.local
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ curl http://yatri.local
^C
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ getent hosts yatri.local
192.168.49.2    yatri.local
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ curl -v --max-time 10 http://yatri.local
* Host yatri.local:80 was resolved.
* IPv6: (none)
* IPv4: 192.168.49.2
*   Trying 192.168.49.2:80...
* Connection timed out after 10002 milliseconds
* closing connection #0
curl: (28) Connection timed out after 10002 milliseconds
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get pods -n ingress-nginx -o wide
NAME                                       READY   STATUS      RESTARTS      AGE   IP           NODE       NOMINATED NODE   READINESS GATES
ingress-nginx-admission-create-fs676       0/1     Completed   0             95m   &lt;none&gt;       minikube   &lt;none&gt;           &lt;none&gt;
ingress-nginx-admission-patch-fxld2        0/1     Completed   0             95m   &lt;none&gt;       minikube   &lt;none&gt;           &lt;none&gt;
ingress-nginx-controller-d7cd8c989-hm9x7   1/1     Running     2 (19m ago)   95m   10.244.0.3   minikube   &lt;none&gt;           &lt;none&gt;
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.107.181.154   &lt;none&gt;        80:32461/TCP,443:31953/TCP   96m
ingress-nginx-controller-admission   ClusterIP   10.106.230.169   &lt;none&gt;        443/TCP                      96m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ minikube ip
192.168.49.2
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ minikube ssh -- curl -v --max-time 5 -H "Host: yatri.local" http://192.168.49.2
* Could not resolve host: yatri.local
* Closing connection 0
curl: (6) Could not resolve host: yatri.local
*   Trying 192.168.49.2:80...
* Connected to 192.168.49.2 (192.168.49.2) port 80 (#1)
> GET / HTTP/1.1
> User-Agent: curl/7.88.1
> Accept: */*
> 
< HTTP/1.1 400 Bad Request
< Date: Thu, 17 Sep 2026 12:01:16 GMT
< Content-Type: text/html
< Content-Length: 150
< Connection: close
< 
&lt;html&gt;
&lt;head&gt;&lt;title&gt;400 Bad Request&lt;/title&gt;&lt;/head&gt;
&lt;body&gt;
&lt;center&gt;&lt;h1&gt;400 Bad Request&lt;/h1&gt;&lt;/center&gt;
&lt;hr&gt;&lt;center&gt;nginx&lt;/center&gt;
&lt;/body&gt;
&lt;/html&gt;
* Closing connection 1
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ minikube ssh -- curl -v --max-time 5 -H 'Host: yatri.local' http://192.168.49.2/
* Could not resolve host: yatri.local
* Closing connection 0
curl: (6) Could not resolve host: yatri.local
*   Trying 192.168.49.2:80...
* Connected to 192.168.49.2 (192.168.49.2) port 80 (#1)
> GET / HTTP/1.1
> User-Agent: curl/7.88.1
> Accept: */*
> 
< HTTP/1.1 400 Bad Request
< Date: Thu, 17 Sep 2026 12:02:17 GMT
< Content-Type: text/html
< Content-Length: 150
< Connection: close
< 
&lt;html&gt;
&lt;head&gt;&lt;title&gt;400 Bad Request&lt;/title&gt;&lt;/head&gt;
&lt;body&gt;
&lt;center&gt;&lt;h1&gt;400 Bad Request&lt;/h1&gt;&lt;/center&gt;
&lt;hr&gt;&lt;center&gt;nginx&lt;/center&gt;
&lt;/body&gt;
&lt;/html&gt;
* Closing connection 1
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ minikube ssh -- curl -v --max-time 5 -H 'Host: yatri.local' http://192.168.49.2/api/
* Could not resolve host: yatri.local
* Closing connection 0
curl: (6) Could not resolve host: yatri.local
*   Trying 192.168.49.2:80...
* Connected to 192.168.49.2 (192.168.49.2) port 80 (#1)
> GET /api/ HTTP/1.1
> User-Agent: curl/7.88.1
> Accept: */*
> 
< HTTP/1.1 400 Bad Request
< Date: Thu, 17 Sep 2026 12:02:40 GMT
< Content-Type: text/html
< Content-Length: 150
< Connection: close
< 
&lt;html&gt;
&lt;head&gt;&lt;title&gt;400 Bad Request&lt;/title&gt;&lt;/head&gt;
&lt;body&gt;
&lt;center&gt;&lt;h1&gt;400 Bad Request&lt;/h1&gt;&lt;/center&gt;
&lt;hr&gt;&lt;center&gt;nginx&lt;/center&gt;
&lt;/body&gt;
&lt;/html&gt;
* Closing connection 1
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingress yatri-ingress -o yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"networking.k8s.io/v1","kind":"Ingress","metadata":{"annotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/$2","nginx.ingress.kubernetes.io/ssl-redirect":"false","nginx.ingress.kubernetes.io/use-regex":"true"},"labels":{"app":"yatri-app"},"name":"yatri-ingress","namespace":"default"},"spec":{"ingressClassName":"nginx","rules":[{"host":"yatri.local","http":{"paths":[{"backend":{"service":{"name":"yatri-backend-service","port":{"number":80}}},"path":"/api(/|$)(.*)","pathType":"ImplementationSpecific"},{"backend":{"service":{"name":"yatri-frontend-service","port":{"number":80}}},"path":"/","pathType":"Prefix"}]}}]}}
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
  creationTimestamp: "2026-09-17T10:21:16Z"
  generation: 1
  labels:
    app: yatri-app
  name: yatri-ingress
  namespace: default
  resourceVersion: "7185"
  uid: d96fb78b-bd20-4fe5-86b1-636872d96e39
spec:
  ingressClassName: nginx
  rules:
  - host: yatri.local
    http:
      paths:
      - backend:
          service:
            name: yatri-backend-service
            port:
              number: 80
        path: /api(/|$)(.*)
        pathType: ImplementationSpecific
      - backend:
          service:
            name: yatri-frontend-service
            port:
              number: 80
        path: /
        pathType: Prefix
status:
  loadBalancer:
    ingress:
    - ip: 192.168.49.2
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=50
I0917 11:41:19.180659       7 nginx.go:273] "Starting NGINX Ingress controller"
I0917 11:41:19.184077       7 event.go:377] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"ingress-nginx", Name:"udp-services", UID:"abc42e4c-45ee-4716-9ad5-58c1210bfced", APIVersion:"v1", ResourceVersion:"5123", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap ingress-nginx/udp-services
I0917 11:41:19.184165       7 event.go:377] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"ingress-nginx", Name:"ingress-nginx-controller", UID:"ce6226df-1cb3-4110-9ee2-3751b92e3844", APIVersion:"v1", ResourceVersion:"5121", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap ingress-nginx/ingress-nginx-controller
I0917 11:41:19.186114       7 event.go:377] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"ingress-nginx", Name:"tcp-services", UID:"c6f3da99-f8a5-4245-9e3c-a0ad6b8e9898", APIVersion:"v1", ResourceVersion:"5122", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap ingress-nginx/tcp-services
I0917 11:41:20.284304       7 store.go:443] "Found valid IngressClass" ingress="default/yatri-ingress" ingressclass="nginx"
I0917 11:41:20.284489       7 event.go:377] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"yatri-ingress", UID:"d96fb78b-bd20-4fe5-86b1-636872d96e39", APIVersion:"networking.k8s.io/v1", ResourceVersion:"6159", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
I0917 11:41:20.382328       7 nginx.go:319] "Starting NGINX process"
I0917 11:41:20.382400       7 leaderelection.go:258] "Attempting to acquire leader lease..." lock="ingress-nginx/ingress-nginx-leader"
I0917 11:41:20.383078       7 nginx.go:339] "Starting validation webhook" address=":8443" certPath="/usr/local/certificates/cert" keyPath="/usr/local/certificates/key"
W0917 11:41:20.383198       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-backend-service": no object matching key "default/yatri-backend-service" in local store
W0917 11:41:20.383208       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-frontend-service": no object matching key "default/yatri-frontend-service" in local store
I0917 11:41:20.383770       7 controller.go:217] "Configuration changes detected, backend reload required"
I0917 11:41:20.390053       7 leaderelection.go:272] "Successfully acquired lease" lock="ingress-nginx/ingress-nginx-leader"
I0917 11:41:20.390159       7 status.go:85] "New leader elected" identity="ingress-nginx-controller-d7cd8c989-hm9x7"
I0917 11:41:20.392911       7 status.go:224] "POD is not ready" pod="ingress-nginx/ingress-nginx-controller-d7cd8c989-hm9x7" node="minikube"
I0917 11:41:20.394716       7 status.go:311] "updating Ingress status" namespace="default" ingress="yatri-ingress" currentValue=[{"ip":"192.168.49.2"}] newValue=[]
I0917 11:41:20.400582       7 event.go:377] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"yatri-ingress", UID:"d96fb78b-bd20-4fe5-86b1-636872d96e39", APIVersion:"networking.k8s.io/v1", ResourceVersion:"6478", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
I0917 11:41:20.416306       7 controller.go:231] "Backend successfully reloaded"
I0917 11:41:20.416380       7 controller.go:243] "Initial sync, sleeping for 1 second"
I0917 11:41:20.416421       7 event.go:377] Event(v1.ObjectReference{Kind:"Pod", Namespace:"ingress-nginx", Name:"ingress-nginx-controller-d7cd8c989-hm9x7", UID:"1492902e-9e38-4e0d-9ea2-849a0bf19642", APIVersion:"v1", ResourceVersion:"6363", FieldPath:""}): type: 'Normal' reason: 'RELOAD' NGINX reload triggered due to a change in configuration
I0917 11:41:20.493076       7 status.go:224] "POD is not ready" pod="ingress-nginx/ingress-nginx-controller-d7cd8c989-hm9x7" node="minikube"
W0917 11:41:23.718048       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-backend-service": no object matching key "default/yatri-backend-service" in local store
W0917 11:41:23.718098       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-frontend-service": no object matching key "default/yatri-frontend-service" in local store
W0917 11:41:27.052608       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-backend-service": no object matching key "default/yatri-backend-service" in local store
W0917 11:41:27.052666       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-frontend-service": no object matching key "default/yatri-frontend-service" in local store
W0917 11:41:30.383524       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-backend-service": no object matching key "default/yatri-backend-service" in local store
W0917 11:41:30.383576       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-frontend-service": no object matching key "default/yatri-frontend-service" in local store
I0917 11:42:20.394016       7 status.go:311] "updating Ingress status" namespace="default" ingress="yatri-ingress" currentValue=null newValue=[{"ip":"192.168.49.2"}]
W0917 11:42:20.398806       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-backend-service": no object matching key "default/yatri-backend-service" in local store
W0917 11:42:20.398831       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-frontend-service": no object matching key "default/yatri-frontend-service" in local store
I0917 11:42:20.398914       7 event.go:377] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"yatri-ingress", UID:"d96fb78b-bd20-4fe5-86b1-636872d96e39", APIVersion:"networking.k8s.io/v1", ResourceVersion:"6551", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
W0917 11:49:43.027561       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-backend-service": no object matching key "default/yatri-backend-service" in local store
W0917 11:49:43.029497       7 controller.go:1241] Service "default/yatri-frontend-service" does not have any active Endpoint.
I0917 11:49:43.030761       7 controller.go:217] "Configuration changes detected, backend reload required"
I0917 11:49:43.095736       7 controller.go:231] "Backend successfully reloaded"
I0917 11:49:43.096174       7 event.go:377] Event(v1.ObjectReference{Kind:"Pod", Namespace:"ingress-nginx", Name:"ingress-nginx-controller-d7cd8c989-hm9x7", UID:"1492902e-9e38-4e0d-9ea2-849a0bf19642", APIVersion:"v1", ResourceVersion:"6363", FieldPath:""}): type: 'Normal' reason: 'RELOAD' NGINX reload triggered due to a change in configuration
W0917 11:49:46.362432       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-backend-service": no object matching key "default/yatri-backend-service" in local store
W0917 11:49:49.694302       7 controller.go:1135] Error obtaining Endpoints for Service "default/yatri-backend-service": no object matching key "default/yatri-backend-service" in local store
W0917 11:50:16.052710       7 controller.go:1241] Service "default/yatri-backend-service" does not have any active Endpoint.
I0917 11:50:16.054020       7 controller.go:217] "Configuration changes detected, backend reload required"
I0917 11:50:16.108387       7 controller.go:231] "Backend successfully reloaded"
I0917 11:50:16.108692       7 event.go:377] Event(v1.ObjectReference{Kind:"Pod", Namespace:"ingress-nginx", Name:"ingress-nginx-controller-d7cd8c989-hm9x7", UID:"1492902e-9e38-4e0d-9ea2-849a0bf19642", APIVersion:"v1", ResourceVersion:"6363", FieldPath:""}): type: 'Normal' reason: 'RELOAD' NGINX reload triggered due to a change in configuration
I0917 11:51:08.113651       7 main.go:107] "successfully validated configuration, accepting" ingress="default/yatri-ingress"
I0917 11:51:08.117716       7 event.go:377] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"yatri-ingress", UID:"d96fb78b-bd20-4fe5-86b1-636872d96e39", APIVersion:"networking.k8s.io/v1", ResourceVersion:"7185", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
I0917 11:51:08.118417       7 controller.go:217] "Configuration changes detected, backend reload required"
I0917 11:51:08.146184       7 controller.go:231] "Backend successfully reloaded"
I0917 11:51:08.146553       7 event.go:377] Event(v1.ObjectReference{Kind:"Pod", Namespace:"ingress-nginx", Name:"ingress-nginx-controller-d7cd8c989-hm9x7", UID:"1492902e-9e38-4e0d-9ea2-849a0bf19642", APIVersion:"v1", ResourceVersion:"6363", FieldPath:""}): type: 'Normal' reason: 'RELOAD' NGINX reload triggered due to a change in configuration
192.168.49.2 - - [17/Sep/2026:12:01:16 +0000] "GET / HTTP/1.1" 400 150 "-" "curl/7.88.1" 56 0.000 [] [] - - - - d80e3ff5d5315c04615eff891aa5c6f1
192.168.49.2 - - [17/Sep/2026:12:02:17 +0000] "GET / HTTP/1.1" 400 150 "-" "curl/7.88.1" 56 0.000 [] [] - - - - 584bbc4022e7032059ed114b045d3881
192.168.49.2 - - [17/Sep/2026:12:02:40 +0000] "GET /api/ HTTP/1.1" 400 150 "-" "curl/7.88.1" 60 0.000 [] [] - - - - 80c64cc16430a154742b90a0c5f20cd9
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingressclass
NAME              CONTROLLER             PARAMETERS   AGE
nginx (default)   k8s.io/ingress-nginx   &lt;none&gt;       99m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get svc yatri-frontend-service yatri-backend-service
NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
yatri-frontend-service   ClusterIP   10.107.93.193   &lt;none&gt;        80/TCP    14m
yatri-backend-service    ClusterIP   10.97.215.2     &lt;none&gt;        80/TCP    14m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ curl -v --max-time 10 -H "Host: yatri.local" http://192.168.49.2/
*   Trying 192.168.49.2:80...
* Connection timed out after 10002 milliseconds
* closing connection #0
curl: (28) Connection timed out after 10002 milliseconds
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get pods -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
yatri-backend-6c58cb99c7-db4hk   1/1     Running   0          15m   10.244.0.6   minikube   &lt;none&gt;           &lt;none&gt;
yatri-backend-6c58cb99c7-fbfzt   1/1     Running   0          15m   10.244.0.7   minikube   &lt;none&gt;           &lt;none&gt;
yatri-frontend-ddcfc4b5f-j7czj   1/1     Running   0          15m   10.244.0.5   minikube   &lt;none&gt;           &lt;none&gt;
yatri-frontend-ddcfc4b5f-p4v4d   1/1     Running   0          15m   10.244.0.4   minikube   &lt;none&gt;           &lt;none&gt;
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get endpoints yatri-frontend-service yatri-backend-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                     ENDPOINTS                         AGE
yatri-frontend-service   10.244.0.4:80,10.244.0.5:80       15m
yatri-backend-service    10.244.0.6:5000,10.244.0.7:5000   15m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl run test-curl --rm -it --image=curlimages/curl -- sh
All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
If you don't see a command prompt, try pressing enter.
<span style="color: #38bdf8; font-weight: bold;">~ $</span> curl -v http://yatri-frontend-service
* Host yatri-frontend-service:80 was resolved.
* IPv6: (none)
* IPv4: 10.107.93.193
*   Trying 10.107.93.193:80...
* Established connection to yatri-frontend-service (10.107.93.193 port 80) from 10.244.0.8 port 51738 
* using HTTP/1.x
> GET / HTTP/1.1
> Host: yatri-frontend-service
> User-Agent: curl/8.22.0
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Thu, 17 Sep 2026 12:06:22 GMT
< Content-Type: text/html
< Content-Length: 615
< Last-Modified: Tue, 16 Apr 2024 15:47:06 GMT
< Connection: keep-alive
< ETag: "661e9d7a-267"
< Accept-Ranges: bytes
< 
&lt;!DOCTYPE html&gt;
&lt;html&gt;
&lt;head&gt;
&lt;title&gt;Welcome to nginx!&lt;/title&gt;
&lt;style&gt;
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
&lt;/style&gt;
&lt;/head&gt;
&lt;body&gt;
&lt;h1&gt;Welcome to nginx!&lt;/h1&gt;
&lt;p&gt;If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.&lt;/p&gt;

&lt;p&gt;For online documentation and support please refer to
&lt;a href="http://nginx.org/"&gt;nginx.org&lt;/a&gt;.&lt;br/&gt;
Commercial support is available at
&lt;a href="http://nginx.com/"&gt;nginx.com&lt;/a&gt;.&lt;/p&gt;

&lt;p&gt;&lt;em&gt;Thank you for using nginx.&lt;/em&gt;&lt;/p&gt;
&lt;/body&gt;
&lt;/html&gt;
* Connection #0 to host yatri-frontend-service:80 left intact
<span style="color: #38bdf8; font-weight: bold;">~ $</span> curl -v http://yatri-backend-service
* Host yatri-backend-service:80 was resolved.
* IPv6: (none)
* IPv4: 10.97.215.2
*   Trying 10.97.215.2:80...
* Established connection to yatri-backend-service (10.97.215.2 port 80) from 10.244.0.8 port 51924 
* using HTTP/1.x
> GET / HTTP/1.1
> Host: yatri-backend-service
> User-Agent: curl/8.22.0
> Accept: */*
> 
* Request completely sent off
* HTTP 1.0, assume close after body
< HTTP/1.0 200 OK
< Server: BaseHTTP/0.6 Python/3.11.11
< Date: Thu, 17 Sep 2026 12:06:33 GMT
< Content-Type: text/plain
< Content-Length: 178
< 
Yatri Backend API
=================
ENVIRONMENT     : production
LOG_LEVEL       : INFO
DEFAULT_CURRENCY: INR
POSTGRES_USER   : yatri_admin
POSTGRES_DB     : yatri_production_db
* shutting down connection #0
<span style="color: #38bdf8; font-weight: bold;">~ $</span> exit
Session ended, resume using 'kubectl attach test-curl -c test-curl -i -t' command when the pod is running
pod "test-curl" deleted from default namespace
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ curl -v --max-time 10 -H "Host: yatri.local" http://192.168.49.2/
*   Trying 192.168.49.2:80...
* Connection timed out after 10002 milliseconds
* closing connection #0
curl: (28) Connection timed out after 10002 milliseconds
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ bash cleanup.sh
: invalid option nameet: pipefail
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
yatri-backend-6c58cb99c7-db4hk   1/1     Running   0          20m
yatri-backend-6c58cb99c7-fbfzt   1/1     Running   0          20m
yatri-frontend-ddcfc4b5f-j7czj   1/1     Running   0          20m
yatri-frontend-ddcfc4b5f-p4v4d   1/1     Running   0          20m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get svc
NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes               ClusterIP   10.96.0.1       &lt;none&gt;        443/TCP   3h5m
yatri-backend-service    ClusterIP   10.97.215.2     &lt;none&gt;        80/TCP    20m
yatri-frontend-service   ClusterIP   10.107.93.193   &lt;none&gt;        80/TCP    20m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingress
NAME            CLASS   HOSTS         ADDRESS        PORTS   AGE
yatri-ingress   nginx   yatri.local   192.168.49.2   80      109m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get configmap
NAME               DATA   AGE
kube-root-ca.crt   1      3h5m
yatri-app-config   5      123m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get secret
NAME              TYPE     DATA   AGE
yatri-db-secret   Opaque   3      121m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get pods | grep yatri
yatri-backend-6c58cb99c7-db4hk   1/1     Running   0          20m
yatri-backend-6c58cb99c7-fbfzt   1/1     Running   0          20m
yatri-frontend-ddcfc4b5f-j7czj   1/1     Running   0          21m
yatri-frontend-ddcfc4b5f-p4v4d   1/1     Running   0          21m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get svc | grep yatri
yatri-backend-service    ClusterIP   10.97.215.2     &lt;none&gt;        80/TCP    20m
yatri-frontend-service   ClusterIP   10.107.93.193   &lt;none&gt;        80/TCP    21m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingress | grep yatri
yatri-ingress   nginx   yatri.local   192.168.49.2   80      109m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ sed -i 's/\r$//' cleanup.sh
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ sed -i 's/\r$//' run-demo.sh
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ head -5 cleanup.sh
#!/usr/bin/env bash
# cleanup.sh — Tear down all demo resources for Session 12
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ bash cleanup.sh
[INFO] Deleting Ingress...
ingress.networking.k8s.io "yatri-ingress" deleted from default namespace
[INFO] Deleting Backend Deployment and Service...
deployment.apps "yatri-backend" deleted from default namespace
service "yatri-backend-service" deleted from default namespace
[INFO] Deleting Frontend Deployment and Service...
deployment.apps "yatri-frontend" deleted from default namespace
service "yatri-frontend-service" deleted from default namespace
[INFO] Deleting Secret...
secret "yatri-db-secret" deleted from default namespace
[INFO] Deleting ConfigMap...
configmap "yatri-app-config" deleted from default namespace
[INFO] All demo resources removed.
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get pods | grep yatri
yatri-backend-6c58cb99c7-db4hk   1/1     Terminating   0          25m
yatri-backend-6c58cb99c7-fbfzt   1/1     Terminating   0          25m
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get svc | grep yatri
No resources found in default namespace.
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingress | grep yatri
No resources found in default namespace.
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get configmap | grep yatri
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get secret | grep yatri
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ bash run-demo.sh
[INFO] Step 1: Enabling NGINX Ingress Controller on Minikube...
💡  ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image registry.k8s.io/ingress-nginx/controller:v1.15.1
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled
[INFO] Waiting 30 seconds for Ingress Controller pods to become Ready...
pod/ingress-nginx-controller-d7cd8c989-hm9x7 condition met
[INFO] Ingress Controller is Ready.

[INFO] Step 2: Applying ConfigMap (plain-text configuration)...
configmap/yatri-app-config created
NAME               DATA   AGE
yatri-app-config   5      0s

[INFO] Step 3: Applying Secret (sensitive database credentials)...
secret/yatri-db-secret created
NAME              TYPE     DATA   AGE
yatri-db-secret   Opaque   3      0s

[INFO] Step 4: Deploying Frontend (Nginx) + ClusterIP Service...
deployment.apps/yatri-frontend created
service/yatri-frontend-service created

[INFO] Step 5: Deploying Backend (Python HTTP server) + ClusterIP Service...
deployment.apps/yatri-backend created
service/yatri-backend-service created

[INFO] Step 6: Waiting for all pods to reach Running state...
Waiting for deployment "yatri-frontend" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "yatri-frontend" rollout to finish: 1 of 2 updated replicas are available...
deployment "yatri-frontend" successfully rolled out
deployment "yatri-backend" successfully rolled out

[INFO] Step 7: Applying Ingress routing rules...
ingress.networking.k8s.io/yatri-ingress created

[INFO] Step 8: Summary of deployed resources...
NAME               DATA   AGE
yatri-app-config   5      1s
NAME              TYPE     DATA   AGE
yatri-db-secret   Opaque   3      1s
NAME                             READY   STATUS    RESTARTS   AGE
yatri-frontend-ddcfc4b5f-p6cwz   1/1     Running   0          1s
yatri-frontend-ddcfc4b5f-vmvwr   1/1     Running   0          1s
NAME                             READY   STATUS    RESTARTS   AGE
yatri-backend-6c58cb99c7-6dldg   1/1     Running   0          2s
yatri-backend-6c58cb99c7-gjlv9   1/1     Running   0          2s
NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
yatri-frontend-service   ClusterIP   10.108.167.179   &lt;none&gt;        80/TCP    2s
yatri-backend-service    ClusterIP   10.98.12.236     &lt;none&gt;        80/TCP    2s
NAME            CLASS   HOSTS         ADDRESS   PORTS   AGE
yatri-ingress   nginx   yatri.local             80      1s

[INFO] Step 9: Adding yatri.local to /etc/hosts (requires sudo)...
[INFO] Minikube IP detected: 192.168.49.2
[INFO] yatri.local already exists in /etc/hosts. Skipping.

[INFO] ============================================================
[INFO] Demo is READY. Test with the following commands:

  Test FRONTEND (path: /):
    curl http://yatri.local
    OR open http://yatri.local in your browser

  Test BACKEND API (path: /api/) -- shows ConfigMap + Secret values:
    curl http://yatri.local/api/

  Verify environment variable injection inside backend pod:
    kubectl exec -it deploy/yatri-backend -- env | grep -E 'ENVIRONMENT|LOG_LEVEL|POSTGRES'

  Decode Secret password:
    kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
[INFO] ============================================================
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingress yatri-ingress
NAME            CLASS   HOSTS         ADDRESS        PORTS   AGE
yatri-ingress   nginx   yatri.local   192.168.49.2   80      96s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingress yatri-ingress -w
NAME            CLASS   HOSTS         ADDRESS        PORTS   AGE
yatri-ingress   nginx   yatri.local   192.168.49.2   80      109s
^C
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl run ingress-test --rm -it --image=curlimages/curl -- sh
All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
If you don't see a command prompt, try pressing enter.
<span style="color: #38bdf8; font-weight: bold;">~ $</span> curl -v -H 'Host: yatri.local' http://192.168.49.2/
*   Trying 192.168.49.2:80...
* Established connection to 192.168.49.2 (192.168.49.2 port 80) from 10.244.0.13 port 55298 
* using HTTP/1.x
> GET / HTTP/1.1
> Host: yatri.local
> User-Agent: curl/8.22.0
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Date: Thu, 17 Sep 2026 12:20:04 GMT
< Content-Type: text/html
< Content-Length: 615
< Connection: keep-alive
< Last-Modified: Tue, 16 Apr 2024 15:47:06 GMT
< ETag: "661e9d7a-267"
< Accept-Ranges: bytes
< 
&lt;!DOCTYPE html&gt;
&lt;html&gt;
&lt;head&gt;
&lt;title&gt;Welcome to nginx!&lt;/title&gt;
&lt;style&gt;
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
&lt;/style&gt;
&lt;/head&gt;
&lt;body&gt;
&lt;h1&gt;Welcome to nginx!&lt;/h1&gt;
&lt;p&gt;If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.&lt;/p&gt;

&lt;p&gt;For online documentation and support please refer to
&lt;a href="http://nginx.org/"&gt;nginx.org&lt;/a&gt;.&lt;br/&gt;
Commercial support is available at
&lt;a href="http://nginx.com/"&gt;nginx.com&lt;/a&gt;.&lt;/p&gt;

&lt;p&gt;&lt;em&gt;Thank you for using nginx.&lt;/em&gt;&lt;/p&gt;
&lt;/body&gt;
&lt;/html&gt;
* Connection #0 to host 192.168.49.2:80 left intact
<span style="color: #38bdf8; font-weight: bold;">~ $</span> curl -v -H 'Host: yatri.local' http://192.168.49.2/api/
*   Trying 192.168.49.2:80...
* Established connection to 192.168.49.2 (192.168.49.2 port 80) from 10.244.0.13 port 44550 
* using HTTP/1.x
> GET /api/ HTTP/1.1
> Host: yatri.local
> User-Agent: curl/8.22.0
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Date: Thu, 17 Sep 2026 12:20:21 GMT
< Content-Type: text/plain
< Content-Length: 178
< Connection: keep-alive
< 
Yatri Backend API
=================
ENVIRONMENT     : production
LOG_LEVEL       : INFO
DEFAULT_CURRENCY: INR
POSTGRES_USER   : yatri_admin
POSTGRES_DB     : yatri_production_db
* Connection #0 to host 192.168.49.2:80 left intact
<span style="color: #38bdf8; font-weight: bold;">~ $</span> exit
Session ended, resume using 'kubectl attach ingress-test -c ingress-test -i -t' command when the pod is running
pod "ingress-test" deleted from default namespace
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ curl -H "Host: yatri.local" http://127.0.0.1:8080/
&lt;!DOCTYPE html&gt;
&lt;html&gt;
&lt;head&gt;
&lt;title&gt;Welcome to nginx!&lt;/title&gt;
&lt;style&gt;
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
&lt;/style&gt;
&lt;/head&gt;
&lt;body&gt;
&lt;h1&gt;Welcome to nginx!&lt;/h1&gt;
&lt;p&gt;If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.&lt;/p&gt;

&lt;p&gt;For online documentation and support please refer to
&lt;a href="http://nginx.org/"&gt;nginx.org&lt;/a&gt;.&lt;br/&gt;
Commercial support is available at
&lt;a href="http://nginx.com/"&gt;nginx.com&lt;/a&gt;.&lt;/p&gt;

&lt;p&gt;&lt;em&gt;Thank you for using nginx.&lt;/em&gt;&lt;/p&gt;
&lt;/body&gt;
&lt;/html&gt;
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ curl -H "Host: yatri.local" http://127.0.0.1:8080/api/
Yatri Backend API
=================
ENVIRONMENT     : production
LOG_LEVEL       : INFO
DEFAULT_CURRENCY: INR
POSTGRES_USER   : yatri_admin
POSTGRES_DB     : yatri_production_db
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
yatri-backend-6c58cb99c7-6dldg   1/1     Running   0          6m30s
yatri-backend-6c58cb99c7-gjlv9   1/1     Running   0          6m30s
yatri-frontend-ddcfc4b5f-p6cwz   1/1     Running   0          6m30s
yatri-frontend-ddcfc4b5f-vmvwr   1/1     Running   0          6m30s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get svc
NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes               ClusterIP   10.96.0.1        &lt;none&gt;        443/TCP   3h19m
yatri-backend-service    ClusterIP   10.98.12.236     &lt;none&gt;        80/TCP    6m39s
yatri-frontend-service   ClusterIP   10.108.167.179   &lt;none&gt;        80/TCP    6m39s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingress
NAME            CLASS   HOSTS         ADDRESS        PORTS   AGE
yatri-ingress   nginx   yatri.local   192.168.49.2   80      6m46s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get ingress yatri-ingress -o wide
NAME            CLASS   HOSTS         ADDRESS        PORTS   AGE
yatri-ingress   nginx   yatri.local   192.168.49.2   80      6m53s
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl exec -it deploy/yatri-backend -- env | grep -E 'ENVIRONMENT|LOG_LEVEL|POSTGRES'
POSTGRES_USER=yatri_admin
POSTGRES_PASSWORD=secretpassword
POSTGRES_DB=yatri_production_db
ENVIRONMENT=production
LOG_LEVEL=INFO
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
secretpassword
<span style="color: #4ade80; font-weight: bold;">amitabh@LAPTOP-3KF17VR3</span>:<span style="color: #60a5fa;">/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session-12-ingress-configmaps-secrets/04-full-demo</span>$ kubectl describe ingress yatri-ingress
Name:             yatri-ingress
Labels:           app=yatri-app
Namespace:        default
Address:          192.168.49.2
Ingress Class:    nginx
Default backend:  &lt;default&gt;
Rules:
  Host         Path  Backends
  ----         ----  --------
  yatri.local  
               /api(/|$)(.*)   yatri-backend-service:80 (10.244.0.12:5000,10.244.0.11:5000)
               /               yatri-frontend-service:80 (10.244.0.10:80,10.244.0.9:80)
Annotations:   nginx.ingress.kubernetes.io/rewrite-target: /$2
               nginx.ingress.kubernetes.io/ssl-redirect: false
               nginx.ingress.kubernetes.io/use-regex: true
Events:
  Type    Reason  Age                   From                      Message
  ----    ------  ----                  ----                      -------
  Normal  Sync    7m2s (x2 over 7m54s)  nginx-ingress-controller  Scheduled for sync
</code></pre>