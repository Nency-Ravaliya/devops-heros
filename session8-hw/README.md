# Session 8 - Docker Networking and Volumes

## Screenshots

![Screenshot 1](Screenshot%202026-09-03%20170744.png)

![Screenshot 2](Screenshot%202026-09-03%20171931.png)

![Screenshot 3](Screenshot%202026-09-03%20171938.png)

![Screenshot 4](Screenshot%202026-09-03%20173406.png)

![Screenshot 5](Screenshot%202026-09-03%20173933.png)


## Overlay Network

An overlay network is a virtual network that connects multiple Docker hosts together so containers running on completely different physical or virtual servers can talk to each other as if they were plugged into the same local network switch. While a standard Docker bridge network only connects containers residing on a single computer, an overlay network acts like an invisible tunnel across the internet or a data center. Under the hood, it uses an encapsulation technology called VXLAN to wrap standard container traffic inside regular network packets. This means containers on different machines can use private, internal IP addresses to exchange data directly and securely without you having to open up ports to the public internet or worry about the complex underlying server hardware.

This multi-host connectivity is essential when managing production applications that outgrow a single machine. Its primary role is powering Docker Swarm clusters, allowing services spread across dozens of servers to automatically discover one another by name and communicate without manual networking configuration. It also provides strong security segmentation by letting you keep sensitive microservices, like databases or payment gateways, on an isolated internal network that spans multiple servers, completely shielded from the public-facing web tier. Finally, it enables Swarm’s routing mesh, an intelligent routing system where an incoming user request hitting any server in your cluster automatically gets routed through the overlay network directly to whichever container is ready to handle it, no matter where that container physically lives.
