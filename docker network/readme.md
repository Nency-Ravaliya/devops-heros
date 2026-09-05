![alt text](<Screenshot 2026-09-04 at 11.37.13 PM.png>) 

![alt text](<Screenshot 2026-09-04 at 11.41.44 PM.png>) 

![alt text](<Screenshot 2026-09-04 at 11.42.36 PM.png>) 

![alt text](<Screenshot 2026-09-04 at 11.45.09 PM.png>) 

![alt text](<Screenshot 2026-09-04 at 11.45.50 PM.png>) 

![alt text](<Screenshot 2026-09-04 at 11.49.12 PM.png>)

## Docker Overlay Network

A Docker overlay network is a virtual network that allows Docker containers and services running on different Docker hosts to communicate with each other. Overlay networks are commonly used with Docker Swarm and distributed applications.

Overlay networks are useful for multi-host communication, microservices, Docker Swarm services, service discovery, and distributed applications.

In a multi-host environment, an overlay network creates a logical network between Docker hosts. Containers or services connected to the same overlay network can communicate even when they are running on different hosts.

A bridge network is generally used for communication between containers on the same Docker host, whereas an overlay network can provide communication across multiple Docker hosts.