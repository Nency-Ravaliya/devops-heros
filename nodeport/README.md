kubectl apply -f .\02-nodeport\
![alt text](image.png)

kubectl get pods -l app=web-nodeport -o wide
![alt text](image-1.png)

kubectl get svc web-service-nodeport
![alt text](image-2.png)

kubectl get nodes -o wide
![alt text](image-3.png)

minikube service web-service-nodeport
![alt text](image-5.png)
![alt text](image-6.png)
![alt text](image-4.png)

kubectl delete -f .\02-nodeport\
![alt text](image-7.png)