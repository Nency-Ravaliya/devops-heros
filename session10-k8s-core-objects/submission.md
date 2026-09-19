rolling update-01
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main$ cd session10-k8s-core-objects
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 01-rolling-update/deployment-v1.yaml
deployment.apps/app-rolling created
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 01-rolling-update/service.yaml
service/app-rolling-service created
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout status deployment/app-rolling
deployment "app-rolling" successfully rolled out
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-rolling --show-labels
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
app-rolling-86d7d44d5b-4k76t   1/1     Running   0          14m   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
app-rolling-86d7d44d5b-4qgv6   1/1     Running   0          14m   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
app-rolling-86d7d44d5b-khz7v   1/1     Running   0          14m   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
app-rolling-86d7d44d5b-zfr5k   1/1     Running   0          14m   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ minikube service app-rolling-service --url
http://127.0.0.1:40819
❗  Because you are using a Docker driver on linux, the terminal needs to be open to run it.
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objectskubectl apply -f 01-rolling-update/deployment-v2.yamlml
deployment.apps/app-rolling configured
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ ^C
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-rolling -w
NAME                           READY   STATUS    RESTARTS   AGE
app-rolling-56bff6d88c-6tq9g   1/1     Running   0          9s
app-rolling-56bff6d88c-6zbqz   0/1     Running   0          2s
app-rolling-56bff6d88c-dr7r4   1/1     Running   0          16s
app-rolling-86d7d44d5b-khz7v   1/1     Running   0          15m
app-rolling-86d7d44d5b-zfr5k   1/1     Running   0          15m
app-rolling-56bff6d88c-6zbqz   1/1     Running   0          7s
app-rolling-56bff6d88c-6zbqz   1/1     Running   0          7s
app-rolling-86d7d44d5b-zfr5k   1/1     Terminating   0          15m
app-rolling-86d7d44d5b-zfr5k   1/1     Terminating   0          15m
app-rolling-56bff6d88c-b8dpx   0/1     Pending       0          0s
app-rolling-56bff6d88c-b8dpx   0/1     Pending       0          0s
app-rolling-56bff6d88c-b8dpx   0/1     ContainerCreating   0          0s
app-rolling-86d7d44d5b-zfr5k   0/1     Completed           0          15m
app-rolling-56bff6d88c-b8dpx   0/1     ContainerCreating   0          1s
app-rolling-86d7d44d5b-zfr5k   0/1     Completed           0          15m
app-rolling-86d7d44d5b-zfr5k   0/1     Completed           0          15m
app-rolling-56bff6d88c-b8dpx   0/1     Running             0          1s
app-rolling-56bff6d88c-b8dpx   1/1     Running             0          7s
app-rolling-56bff6d88c-b8dpx   1/1     Running             0          7s
app-rolling-86d7d44d5b-khz7v   1/1     Terminating         0          16m
app-rolling-86d7d44d5b-khz7v   1/1     Terminating         0          16m
app-rolling-86d7d44d5b-khz7v   0/1     Completed           0          16m
app-rolling-86d7d44d5b-khz7v   0/1     Completed           0          16m
app-rolling-86d7d44d5b-khz7v   0/1     Completed           0          16m
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-rolling -w
NAME                           READY   STATUS    RESTARTS   AGE
app-rolling-56bff6d88c-6tq9g   1/1     Running   0          37s
app-rolling-56bff6d88c-6zbqz   1/1     Running   0          30s
app-rolling-56bff6d88c-b8dpx   1/1     Running   0          23s
app-rolling-56bff6d88c-dr7r4   1/1     Running   0          44s
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objectskubectl rollout status deployment/app-rollingng
deployment "app-rolling" successfully rolled out
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-rolling --show-labels
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
app-rolling-56bff6d88c-6tq9g   1/1     Running   0          85s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-6zbqz   1/1     Running   0          78s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-b8dpx   1/1     Running   0          71s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-dr7r4   1/1     Running   0          92s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout undo deployment/app-rolling
deployment.apps/app-rolling rolled back
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-rolling --show-labels
NAME                           READY   STATUS    RESTARTS   AGE     LABELS
app-rolling-56bff6d88c-6tq9g   1/1     Running   0          2m9s    app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-b8dpx   1/1     Running   0          115s    app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-dr7r4   1/1     Running   0          2m16s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-86d7d44d5b-5rqh4   0/1     Running   0          4s      app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
app-rolling-86d7d44d5b-7s95v   1/1     Running   0          10s     app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
2         <none>
3         <none>

amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 01-rolling-update/deployment-v3.yaml
deployment.apps/app-rolling configured
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-rolling -w
NAME                           READY   STATUS              RESTARTS   AGE
app-rolling-86d7d44d5b-5rqh4   1/1     Running             0          47m
app-rolling-86d7d44d5b-7s95v   1/1     Terminating         0          47m
app-rolling-86d7d44d5b-nb9f9   1/1     Running             0          47m
app-rolling-86d7d44d5b-zfnnr   1/1     Running             0          47m
app-rolling-c689dbd6-fv4gv     0/1     ContainerCreating   0          0s
app-rolling-c689dbd6-p88l4     1/1     Running             0          24s
app-rolling-c689dbd6-fv4gv     0/1     ContainerCreating   0          0s
app-rolling-86d7d44d5b-7s95v   0/1     Completed           0          47m
app-rolling-c689dbd6-fv4gv     0/1     Running             0          0s
app-rolling-86d7d44d5b-7s95v   0/1     Completed           0          47m
app-rolling-86d7d44d5b-7s95v   0/1     Completed           0          47m
app-rolling-c689dbd6-fv4gv     1/1     Running             0          3s
app-rolling-86d7d44d5b-nb9f9   1/1     Terminating         0          47m
app-rolling-c689dbd6-kh6s8     0/1     Pending             0          0s
app-rolling-86d7d44d5b-nb9f9   1/1     Terminating         0          47m
app-rolling-c689dbd6-kh6s8     0/1     Pending             0          0s
app-rolling-c689dbd6-kh6s8     0/1     ContainerCreating   0          0s
app-rolling-86d7d44d5b-nb9f9   0/1     Completed           0          47m
app-rolling-c689dbd6-kh6s8     0/1     ContainerCreating   0          0s
app-rolling-c689dbd6-kh6s8     0/1     Running             0          0s
app-rolling-86d7d44d5b-nb9f9   0/1     Completed           0          47m
app-rolling-86d7d44d5b-nb9f9   0/1     Completed           0          47m
app-rolling-c689dbd6-kh6s8     1/1     Running             0          3s
app-rolling-86d7d44d5b-zfnnr   1/1     Terminating         0          47m
app-rolling-86d7d44d5b-zfnnr   1/1     Terminating         0          47m
app-rolling-c689dbd6-69ls8     0/1     Pending             0          0s
app-rolling-c689dbd6-69ls8     0/1     Pending             0          0s
app-rolling-c689dbd6-69ls8     0/1     ContainerCreating   0          0s
app-rolling-c689dbd6-69ls8     0/1     ContainerCreating   0          0s
app-rolling-c689dbd6-69ls8     0/1     Running             0          0s
app-rolling-86d7d44d5b-zfnnr   0/1     Completed           0          47m
app-rolling-86d7d44d5b-zfnnr   0/1     Completed           0          47m
app-rolling-86d7d44d5b-zfnnr   0/1     Completed           0          47m
app-rolling-c689dbd6-69ls8     1/1     Running             0          3s
app-rolling-86d7d44d5b-5rqh4   1/1     Terminating         0          47m
app-rolling-86d7d44d5b-5rqh4   1/1     Terminating         0          47m
app-rolling-86d7d44d5b-5rqh4   0/1     Completed           0          47m
app-rolling-86d7d44d5b-5rqh4   0/1     Completed           0          47m
app-rolling-86d7d44d5b-5rqh4   0/1     Completed           0          47m
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-rolling -w
NAME                         READY   STATUS    RESTARTS   AGE
app-rolling-c689dbd6-69ls8   1/1     Running   0          5m2s
app-rolling-c689dbd6-fv4gv   1/1     Running   0          5m8s
app-rolling-c689dbd6-kh6s8   1/1     Running   0          5m5s
app-rolling-c689dbd6-p88l4   1/1     Running   0          5m32s
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objectskubectl rollout status deployment/app-rolling
deployment "app-rolling" successfully rolled out
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
2         <none>
3         <none>
4         <none>

amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout undo deployment/app-rolling
deployment.apps/app-rolling rolled back
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
2         <none>
4         <none>
5         <none>

amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 01-rolling-update/deployment-v4.yaml
Warning: spec.template.spec.containers[1].ports[0]: duplicate port definition with spec.template.spec.containers[0].ports[0]
deployment.apps/app-rolling configured
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
2         <none>
4         <none>
5         <none>
6         <none>

amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout undo deployment/app-rolling
deployment.apps/app-rolling rolled back
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
2         <none>
4         <none>
6         <none>
7         <none>

Blue-Green-02

amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 02-blue-green/deployment-blue.yaml
kubectl apply -f 02-blue-green/deployment-green.yaml
deployment.apps/app-blue created
deployment.apps/app-green created
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=myapp --show-labels
NAME                        READY   STATUS    RESTARTS   AGE   LABELS
app-blue-5c69d7785c-9cl6t   1/1     Running   0          27s   app=myapp,pod-template-hash=5c69d7785c,slot=blue,version=v1
app-blue-5c69d7785c-kb4v7   1/1     Running   0          27s   app=myapp,pod-template-hash=5c69d7785c,slot=blue,version=v1
app-blue-5c69d7785c-qdxh2   1/1     Running   0          27s   app=myapp,pod-template-hash=5c69d7785c,slot=blue,version=v1
app-green-84df7f978-csr4w   1/1     Running   0          27s   app=myapp,pod-template-hash=84df7f978,slot=green,version=v2
app-green-84df7f978-l46t6   1/1     Running   0          27s   app=myapp,pod-template-hash=84df7f978,slot=green,version=v2
app-green-84df7f978-t8mtg   1/1     Running   0          27s   app=myapp,pod-template-hash=84df7f978,slot=green,version=v2
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 02-blue-green/service-blue.yaml
service/myapp-service created
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ minikube service myapp-service --url
http://127.0.0.1:35857
❗  Because you are using a Docker driver on linux, the terminal needs to be open to run it.
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objectskubectl describe svc myapp-service | grep Selectoror
Selector:                 app=myapp,slot=blue
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get endpoints myapp-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME            ENDPOINTS                                      AGE
myapp-service   10.244.0.36:80,10.244.0.37:80,10.244.0.38:80   45s
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 02-blue-green/service-green.yaml
service/myapp-service configured
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ curl http://$(minikube ip):30020
^C
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ minikube service myapp-service --url
http://127.0.0.1:46311
❗  Because you are using a Docker driver on linux, the terminal needs to be open to run it.
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objectskubectl describe svc myapp-service | grep Selectoror
Selector:                 app=myapp,slot=green
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get endpoints myapp-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME            ENDPOINTS                                      AGE
myapp-service   10.244.0.39:80,10.244.0.40:80,10.244.0.41:80   3m3s

Canary-03

amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 03-canary/deployment-stable.yaml
deployment.apps/app-stable created
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout status deployment/app-stable
deployment "app-stable" successfully rolled out
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 03-canary/service.yaml
service/myapp-canary-service created
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ for i in $(seq 1 10); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done
^C
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=myapp-canary --show-labels
NAME                          READY   STATUS    RESTARTS   AGE     LABELS
app-stable-6ffb777f9d-9zpxw   1/1     Running   0          5m30s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-cp9gq   1/1     Running   0          5m30s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-fjpcc   1/1     Running   0          5m30s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-lbb6z   1/1     Running   0          5m30s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-ldns8   1/1     Running   0          5m30s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-ljt2c   1/1     Running   0          5m30s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-qwnr8   1/1     Running   0          5m30s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zh7zq   1/1     Running   0          5m30s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zjbtj   1/1     Running   0          5m30s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get svc myapp-canary-service
NAME                   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
myapp-canary-service   NodePort   10.98.207.139   <none>        80:30030/TCP   5m38s
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get endpoints myapp-canary-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                   ENDPOINTS                                                  AGE
myapp-canary-service   10.244.0.42:80,10.244.0.43:80,10.244.0.44:80 + 6 more...   5m53s
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ for i in $(seq 1 10); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done
^C
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=myapp-canary --show-labels
NAME                          READY   STATUS    RESTARTS   AGE     LABELS
app-stable-6ffb777f9d-9zpxw   1/1     Running   0          9m39s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-cp9gq   1/1     Running   0          9m39s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-fjpcc   1/1     Running   0          9m39s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-lbb6z   1/1     Running   0          9m39s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-ldns8   1/1     Running   0          9m39s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-ljt2c   1/1     Running   0          9m39s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-qwnr8   1/1     Running   0          9m39s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zh7zq   1/1     Running   0          9m39s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zjbtj   1/1     Running   0          9m39s   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get svc myapp-canary-service
NAME                   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
myapp-canary-service   NodePort   10.98.207.139   <none>        80:30030/TCP   9m23s
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get endpoints myapp-canary-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                   ENDPOINTS                                                  AGE
myapp-canary-service   10.244.0.42:80,10.244.0.43:80,10.244.0.44:80 + 6 more...   9m34s
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ curl -v http://$(minikube ip):30030
*   Trying 192.168.49.2:30030...
* connect to 192.168.49.2 port 30030 from 172.27.36.164 port 53918 failed: Connection timed out
* Failed to connect to 192.168.49.2 port 30030 after 134658 ms: Could not connect to server
* closing connection #0
curl: (28) Failed to connect to 192.168.49.2 port 30030 after 134658 ms: Could not connect to server
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl run canary-test --rm -it --image=curlimages/curl -- sh
All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
If you don't see a command prompt, try pressing enter.
~ $ curl -v http://myapp-canary-service
* Host myapp-canary-service:80 was resolved.
* IPv6: (none)
* IPv4: 10.98.207.139
*   Trying 10.98.207.139:80...
* Established connection to myapp-canary-service (10.98.207.139 port 80) from 10.244.0.51 port 55418 
* using HTTP/1.x
> GET / HTTP/1.1
> Host: myapp-canary-service
> User-Agent: curl/8.22.0
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Server: nginx/1.24.0
< Date: Thu, 17 Sep 2026 15:12:15 GMT
< Content-Type: text/html
< Content-Length: 230
< Last-Modified: Thu, 17 Sep 2026 14:59:02 GMT
< Connection: keep-alive
< ETag: "6aac0036-e6"
< Accept-Ranges: bytes
< 
<html><body style="background:#1a1a2e;color:#e2e2e2;font-family:monospace;font-size:3em;text-align:center;padding-top:20vh">
<p>STABLE v1</p>
<p style="font-size:0.4em;color:#888">Track: stable | 90% of traffic</p>
</body></html>
* Connection #0 to host myapp-canary-service:80 left intact
~ $ exit
Session ended, resume using 'kubectl attach canary-test -c canary-test -i -t' command when the pod is running
pod "canary-test" deleted from default namespace
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 03-canary/deployment-canary.yaml
deployment.apps/app-canary created
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout status deployment/app-canary
deployment "app-canary" successfully rolled out
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=myapp-canary --show-labels
NAME                          READY   STATUS    RESTARTS   AGE   LABELS
app-canary-5849994497-4p889   1/1     Running   0          22s   app=myapp-canary,pod-template-hash=5849994497,track=canary,version=v2
app-stable-6ffb777f9d-9zpxw   1/1     Running   0          15m   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-cp9gq   1/1     Running   0          15m   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-fjpcc   1/1     Running   0          15m   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-lbb6z   1/1     Running   0          15m   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-ldns8   1/1     Running   0          15m   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-ljt2c   1/1     Running   0          15m   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-qwnr8   1/1     Running   0          15m   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zh7zq   1/1     Running   0          15m   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zjbtj   1/1     Running   0          15m   app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get endpoints myapp-canary-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                   ENDPOINTS                                                  AGE
myapp-canary-service   10.244.0.42:80,10.244.0.43:80,10.244.0.44:80 + 7 more...   15m
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl run canary-test --rm -it --image=curlimages/curl -- sh
All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
If you don't see a command prompt, try pressing enter.
~ $ for i in $(seq 1 20); do curl -s http://myapp-canary-service | grep -o "STABLE v1\|CANARY v2"; done
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
CANARY v2
STABLE v1
CANARY v2
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
~ $ exit
Session ended, resume using 'kubectl attach canary-test -c canary-test -i -t' command when the pod is running
pod "canary-test" deleted from default namespace
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 03-canary/deployment-canary.yaml
deployment.apps/app-canary unchanged
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout status deployment/app-canary
deployment "app-canary" successfully rolled out
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=myapp-canary --show-labels
NAME                          READY   STATUS    RESTARTS   AGE    LABELS
app-canary-5849994497-4p889   1/1     Running   0          3m7s   app=myapp-canary,pod-template-hash=5849994497,track=canary,version=v2
app-stable-6ffb777f9d-9zpxw   1/1     Running   0          18m    app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-cp9gq   1/1     Running   0          18m    app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-fjpcc   1/1     Running   0          18m    app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-lbb6z   1/1     Running   0          18m    app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-ldns8   1/1     Running   0          18m    app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-ljt2c   1/1     Running   0          18m    app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-qwnr8   1/1     Running   0          18m    app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zh7zq   1/1     Running   0          18m    app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zjbtj   1/1     Running   0          18m    app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl scale deployment app-canary --replicas=3
kubectl scale deployment app-stable --replicas=7
deployment.apps/app-canary scaled
deployment.apps/app-stable scaled
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=myapp-canary --show-labels
NAME                          READY   STATUS    RESTARTS   AGE     LABELS
app-canary-5849994497-4p889   1/1     Running   0          4m21s   app=myapp-canary,pod-template-hash=5849994497,track=canary,version=v2
app-canary-5849994497-f88s7   1/1     Running   0          13s     app=myapp-canary,pod-template-hash=5849994497,track=canary,version=v2
app-canary-5849994497-fvw59   1/1     Running   0          13s     app=myapp-canary,pod-template-hash=5849994497,track=canary,version=v2
app-stable-6ffb777f9d-9zpxw   1/1     Running   0          19m     app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-cp9gq   1/1     Running   0          19m     app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-lbb6z   1/1     Running   0          19m     app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-ldns8   1/1     Running   0          19m     app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-qwnr8   1/1     Running   0          19m     app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zh7zq   1/1     Running   0          19m     app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
app-stable-6ffb777f9d-zjbtj   1/1     Running   0          19m     app=myapp-canary,pod-template-hash=6ffb777f9d,track=stable,version=v1
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get endpoints myapp-canary-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                   ENDPOINTS                                                  AGE
myapp-canary-service   10.244.0.42:80,10.244.0.44:80,10.244.0.45:80 + 7 more...   19m

Recreate-04

amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl apply -f 04-recreate/deployment-v1.yaml
kubectl apply -f 04-recreate/service.yaml
deployment.apps/app-recreate created
service/app-recreate-service created
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-recreate
NAME                            READY   STATUS    RESTARTS   AGE
app-recreate-6c78cb55bb-sd7zn   1/1     Running   0          9s
app-recreate-6c78cb55bb-szqvs   1/1     Running   0          9s
app-recreate-6c78cb55bb-tk924   1/1     Running   0          9s
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ curl http://localhost:30040
curl: (7) Failed to connect to localhost port 30040 after 0 ms: Could not connect to server
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-recreate -w
NAME                            READY   STATUS    RESTARTS   AGE
app-recreate-6c78cb55bb-sd7zn   1/1     Running   0          56s
app-recreate-6c78cb55bb-szqvs   1/1     Running   0          56s
app-recreate-6c78cb55bb-tk924   1/1     Running   0          56s
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objectskubectl apply -f 04-recreate/deployment-v2.yamlml
deployment.apps/app-recreate configured
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl get pods -l app=app-recreate -w
NAME                            READY   STATUS    RESTARTS   AGE
app-recreate-7bd8d89b8b-785gc   1/1     Running   0          22s
app-recreate-7bd8d89b8b-tcq4x   1/1     Running   0          22s
app-recreate-7bd8d89b8b-xnrft   1/1     Running   0          22s
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectget pods -l app=app-recreate -w
NAME                            READY   STATUS    RESTARTS   AGE
app-recreate-7bd8d89b8b-785gc   1/1     Running   0          37s
app-recreate-7bd8d89b8b-tcq4x   1/1     Running   0          37s
app-recreate-7bd8d89b8b-xnrft   1/1     Running   0          37s
^Camitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objectskubectl rollout undo deployment/app-recreatete
deployment.apps/app-recreate rolled back
amitabh@LAPTOP-3KF17VR3:/mnt/c/Users/USER/Downloads/devops-heros-branch10104-main/devops-heros-branch10104-main/session10-k8s-core-objects$ kubectl rollout status deployment/app-recreate
deployment "app-recreate" successfully rolled out
