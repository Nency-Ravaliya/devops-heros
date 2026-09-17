PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl get all
NAME                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/app-rolling-service   NodePort    10.100.118.84   <none>        80:30010/TCP   41s
service/kubernetes            ClusterIP   10.96.0.1       <none>        443/TCP        36h
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl apply -f .\deployment-v1.yaml
deployment.apps/app-rolling created
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl rollout status deployment/app-rolling
deployment "app-rolling" successfully rolled out
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl get pods -l app=app-rolling --show-labels
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
app-rolling-86d7d44d5b-lfr8q   1/1     Running   0          52s   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
app-rolling-86d7d44d5b-lnn2p   1/1     Running   0          52s   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
app-rolling-86d7d44d5b-n7bvs   1/1     Running   0          52s   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
app-rolling-86d7d44d5b-qx5vl   1/1     Running   0          52s   app=app-rolling,pod-template-hash=86d7d44d5b,version=v1
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> minikube service app-rolling-service --url
http://127.0.0.1:47472
❗  Because you are using a Docker driver on windows, the terminal needs to be open to run it.
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl apply -f .\deployment-v2.yaml
deployment.apps/app-rolling configured
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl get pods -l app=app-rolling -w
NAME                           READY   STATUS    RESTARTS   AGE
app-rolling-56bff6d88c-2zxb5   0/1     Running   0          3s
app-rolling-56bff6d88c-lzbbm   1/1     Running   0          10s
app-rolling-86d7d44d5b-lnn2p   1/1     Running   0          95s
app-rolling-86d7d44d5b-n7bvs   1/1     Running   0          95s
app-rolling-86d7d44d5b-qx5vl   1/1     Running   0          95s
app-rolling-56bff6d88c-2zxb5   1/1     Running   0          7s
app-rolling-56bff6d88c-2zxb5   1/1     Running   0          7s
app-rolling-86d7d44d5b-lnn2p   1/1     Terminating   0          99s
app-rolling-86d7d44d5b-lnn2p   1/1     Terminating   0          99s
app-rolling-56bff6d88c-55bml   0/1     Pending       0          0s
app-rolling-56bff6d88c-55bml   0/1     Pending       0          0s
app-rolling-56bff6d88c-55bml   0/1     ContainerCreating   0          0s
app-rolling-86d7d44d5b-lnn2p   0/1     Completed           0          100s
app-rolling-56bff6d88c-55bml   0/1     ContainerCreating   0          1s
app-rolling-86d7d44d5b-lnn2p   0/1     Completed           0          100s
app-rolling-86d7d44d5b-lnn2p   0/1     Completed           0          100s
app-rolling-86d7d44d5b-lnn2p   0/1     Completed           0          100s
app-rolling-56bff6d88c-55bml   0/1     Running             0          1s
app-rolling-56bff6d88c-55bml   1/1     Running             0          7s
app-rolling-86d7d44d5b-qx5vl   1/1     Terminating         0          106s
app-rolling-86d7d44d5b-qx5vl   1/1     Terminating         0          106s
app-rolling-56bff6d88c-t9nqn   0/1     Pending             0          0s
app-rolling-56bff6d88c-t9nqn   0/1     Pending             0          0s
app-rolling-56bff6d88c-t9nqn   0/1     ContainerCreating   0          0s
app-rolling-86d7d44d5b-qx5vl   0/1     Completed           0          107s
app-rolling-56bff6d88c-t9nqn   0/1     ContainerCreating   0          1s
app-rolling-86d7d44d5b-qx5vl   0/1     Completed           0          107s
app-rolling-86d7d44d5b-qx5vl   0/1     Completed           0          107s
app-rolling-56bff6d88c-t9nqn   0/1     Running             0          1s
app-rolling-56bff6d88c-t9nqn   1/1     Running             0          7s
app-rolling-56bff6d88c-t9nqn   1/1     Running             0          7s
app-rolling-86d7d44d5b-n7bvs   1/1     Terminating         0          113s
app-rolling-86d7d44d5b-n7bvs   1/1     Terminating         0          113s
app-rolling-86d7d44d5b-n7bvs   0/1     Completed           0          114s
app-rolling-86d7d44d5b-n7bvs   0/1     Completed           0          114s
app-rolling-86d7d44d5b-n7bvs   0/1     Completed           0          114s
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl rollout status deployment/app-rolling 
deployment "app-rolling" successfully rolled out
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl get pods -l app=app-rolling --show-labels
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
app-rolling-56bff6d88c-2zxb5   1/1     Running   0          67s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-55bml   1/1     Running   0          60s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-lzbbm   1/1     Running   0          74s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
app-rolling-56bff6d88c-t9nqn   1/1     Running   0          53s   app=app-rolling,pod-template-hash=56bff6d88c,version=v2
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> minikube service app-rolling-service --url
http://127.0.0.1:3298
❗  Because you are using a Docker driver on windows, the terminal needs to be open to run it.
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl apply -f .\deployment-v3.yaml     
deployment.apps/app-rolling configured
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl rollout status deployment/app-rolling
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
deployment "app-rolling" successfully rolled out
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl get pods -l app=app-rolling --show-labels
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
app-rolling-85b5dcf59f-5sg7j   1/1     Running   0          55s   app=app-rolling,pod-template-hash=85b5dcf59f,version=v3
app-rolling-85b5dcf59f-65vvx   1/1     Running   0          61s   app=app-rolling,pod-template-hash=85b5dcf59f,version=v3
app-rolling-85b5dcf59f-6l5h5   1/1     Running   0          40s   app=app-rolling,pod-template-hash=85b5dcf59f,version=v3
app-rolling-85b5dcf59f-7svl8   1/1     Running   0          47s   app=app-rolling,pod-template-hash=85b5dcf59f,version=v3
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>

PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl apply -f .\deployment-v4.yaml            
deployment.apps/app-rolling configured
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl rollout status deployment/app-rolling    
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
deployment "app-rolling" successfully rolled out
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> minikube service app-rolling-service --url
http://127.0.0.1:63747
❗  Because you are using a Docker driver on windows, the terminal needs to be open to run it.
PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
4         <none>

PS C:\Users\Tejas\Desktop\devops-heros\session10-k8s-core-objects\01-rolling-update> minikube service app-rolling-service --url    
http://127.0.0.1:55216
❗  Because you are using a Docker driver on windows, the terminal needs to be open to run it.