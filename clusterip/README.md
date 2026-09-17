![alt text](image.png)

![alt text](image-1.png)

kubectl exec -it curl-client -- curl -s web-service-clusterip:8080
![alt text](image-2.png)

port-forwarding 
kubectl port-forward servuce/web-service-clusterip 8080:8080
![alt text](image-3.png)