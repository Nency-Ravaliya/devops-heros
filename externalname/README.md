kubectl apply -f 04-externalname
![alt text](image.png)

kubectl get pod dns-test-client
![alt text](image-1.png)

kubectl exec -it dns-test-client -- nslookup external-database-service
![alt text](image-2.png)

kubectl exec -it dns-test-client -- curl -k -s -H "Host: api.github.com" https://external-database-service
![alt text](image-3.png)

kubectl delete -f .\04-loadbalancer\
![alt text](image-4.png)