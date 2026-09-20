![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)
![alt text](image-3.png)
![alt text](image-4.png)

## Ingress and Ingreess controller
**Ingress** is a Kubernetes resource that contains the rules for how external HTTP/HTTPS traffic should reach different Services inside the cluster. For example, it can route `/login` to one Service and `/products` to another Service. **Ingress Controller** is the actual component that reads these Ingress rules and implements them by handling and routing the incoming traffic. In simple words, **Ingress defines the rules, while Ingress Controller applies those rules**. Ingress itself does not handle traffic; an Ingress Controller such as NGINX Ingress Controller is required for it to work.
