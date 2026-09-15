# Docker Networking & Volume Homework

## Task 1: Docker Container Networking

**1. Create 3 different Docker networks:**
```bash
docker network create frontend-net
docker network create backend-net
docker network create database-net
```

**2. Create 3 containers (Frontend, Backend, Database):**
```bash
# Create Frontend container using Nginx
docker run -d --name frontend --network frontend-net nginx

# Create Database container using MySQL
docker run -d --name database --network database-net -e MYSQL_ROOT_PASSWORD=root mysql

# Create Backend container using Alpine
docker run -d --name backend --network backend-net alpine sleep 3600
```

**3. Add the backend container to 2 additional networks:**
```bash
# Connect backend to frontend-net
docker network connect frontend-net backend

# Connect backend to database-net
docker network connect database-net backend
```

**4. Check connectivity between the containers:**
```bash
# Verify backend can reach frontend
docker exec backend ping -c 3 frontend

# Verify backend can reach database
docker exec backend ping -c 3 database
```

*Screenshot placeholder: Add screenshot of connectivity test here*
![Task 1 - Connectivity](screenshot_task1.png)

---

## Task 2: Host Network

**1. Pull the Apache2 image from Docker Hub:**
```bash
docker pull httpd
```

**2. Create an Apache2 container using the host network:**
```bash
docker run -d --name apache-host --network host httpd
```

**3. Access the Apache website directly on port 80:**
```bash
curl http://localhost
```

*Screenshot placeholder: Add screenshot of Apache website access here*
![Task 2 - Host Network](screenshot_task2.png)

---

## Task 3: Bind Mount

**1. Create a folder and `index.html` on your local machine:**
```bash
mkdir html-website
cd html-website
echo "Hello students" > index.html
```

**2. Bind mount the folder to an Nginx container:**
```bash
# We use an absolute path for Windows, e.g., C:\path\to\html-website, or $(pwd) in PowerShell:
docker run -d --name nginx-bind -p 8085:80 -v ${PWD}:/usr/share/nginx/html nginx
```

**3. Access the Nginx website and verify the content:**
```bash
curl http://localhost:8085
```

**4. Modify the `index.html` file and verify without restarting:**
```bash
echo "Hello students - Updated" > index.html
curl http://localhost:8085
```

*Screenshot placeholder: Add screenshot showing the updated content here*
![Task 3 - Bind Mount](screenshot_task3.png)

---

## Task 4: Overlay Network

### What is a Docker Overlay Network?
A Docker overlay network is a distributed network that spans across multiple Docker daemon hosts. It allows containers connected to it (such as those in a Docker Swarm service) to communicate securely and directly with each other, even if they are hosted on entirely different physical machines.

### Use Cases:
- **Multi-Host Networking:** The primary use case is connecting containers running on different hosts within a Docker Swarm or Kubernetes cluster.
- **High Availability & Service Discovery:** It allows services to scale across multiple nodes while maintaining seamless communication and built-in load balancing.
- **Isolation:** You can isolate different applications and environments (e.g., staging vs. production) across a cluster by keeping them on separate overlay networks.

### How Overlay Networks Work Across Multiple Hosts:
Overlay networks operate by encapsulating the container's network traffic into a different format (usually VXLAN - Virtual eXtensible Local Area Network). 
1. When Container A on Host 1 wants to talk to Container B on Host 2, it sends standard network packets.
2. The Docker engine intercepts these packets and encapsulates them into UDP packets.
3. These UDP packets are sent across the underlying physical network from Host 1 to Host 2.
4. Host 2 receives the UDP packets, unpackages them, and delivers the original network packets to Container B.
This creates a virtual, private subnet that the containers see as a single, contiguous network, completely abstracting away the physical network topology.
