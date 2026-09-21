# Kubernetes Networking

By default in a kubernetes cluster, every pod has an IP address. These pods can be accessed by each other (on an internal/private) network via their IP address. A pods IP address however is not stable. If a pod restarts it may get a new IP address. To provide a stable way to connect to pods we have services that have a single IP address and communicates with all the pods having same label as the service selector. Depending on the networking requirement there are 5 types of services.

## ClusterIP

The service exposes an internal IP that can be accessed by other objects in the cluster. This is the default type.

## NodePort

The service also exposes a port allowing external connections (from outside the cluster)

## LoadBalancer

The service acts as a load balancer as provided by an external service such as AWS or Azure

## ExternalName

The service acts as a DNS alias to an external resource. For example service name -> github. ExternalName -> `https://github.com/Nency-Ravaliya/devops-heros`. Then any object can access the devops repo just by searching `github`

## Headless

ClusterIp acts as a load balancer between all the pods associated to that service. IF you communicate to the service you dont know what pod exactly you are talking to, like a stateless LB. If you want individual pod then u can use headless. Headless service doesnt have an IP address.