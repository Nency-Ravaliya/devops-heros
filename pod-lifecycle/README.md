POD LIFECYCLE
created all pods in session10/pod-lifecycle
Used command kubectl apply -f session10/pod-lifecycle
![alt text](image.png)

kubectl get pods 
![](image-1.png)

Logs of each pods

kubectl logs lifecycle-running 
![alt text](image-8.png)

kubectl logs lifecycle-pending
![alt text](image-9.png)

kubectl logs lifecycle-succeeded
![alt text](image-10.png)

kubectl logs lifecycle-crashloop
![alt text](image-2.png)

kubectl logs lifecycle-failed
![alt text](image-3.png)

kubectl logs lifecycle-image-error
![alt text](image-4.png)

kubectl logs lifecycle-init
![alt text](image-5.png)

kubectl logs lifecycle-liveness
![alt text](image-6.png)

kubectl logs lifecycle-image-error
![alt text](image-7.png)


