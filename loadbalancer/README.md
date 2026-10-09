kubectl apply -d 03-loadbalancer
![alt text](image.png)

kubectl get pods -l app=web-loadbalancer
![alt text](image-1.png)

kubectl get svc web-service-loadbalancer
![alt text](image-2.png)

minikube tunnel
![alt text](image-3.png)

In browser, https://localhost
minikube service web-service-loadbalancer

minikube service web-service-loadbalancer
![alt text](image-4.png)

kubectl delete -f 03-loadbalancer
![alt text](image-5.png)