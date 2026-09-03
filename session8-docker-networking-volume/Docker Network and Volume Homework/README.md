# Docker Network and Volume Homework Task:

## Task 1:

### What task was:

- Created Frontend, Backend, and Database containers using Nginx, Alpine, and MySQL images.

- Created 3 different Docker networks and connected the Backend container to 2 networks.

- Verified connectivity between Frontend ↔ Backend and Backend ↔ Database.

### Screenshots:

- docker ps:
    ![docker ps](./screenshots/Task-1/docker-ps.png)

- docker exec:
    ![docker exec](./screenshots/Task-1/docker%20exec.png)

- docker inspect:
    ![docker inspect](./screenshots/Task-1/docker%20inspect.png)

- docker network:
    ![docker network](./screenshots/Task-1/docker%20network.png)

---

## Task 2:

### What task was:

- Pull the Apache2 image from Docker Hub.
- Create and run an Apache2 container using the host network.
- Access the Apache website directly through port 80 and verify that it is working.

### Screenshots:

- Website Screenshot:
    ![Running on brave](./screenshots/Task-2/Running%20Task%202%20of%20Network.png)

- Commands:
    ![Commands](./screenshots/Task-2/commands%20of%20task%202.png)

---

## Task 3:

### What task was:

- Create a local folder with an index.html file containing Hello students and bind mount it to an Nginx container.

- Access the Nginx website and verify that Hello students is displayed.

- Modify the index.html file and verify that the changes appear without restarting the container.

### Screenshots:

- docker ps before modifying:
    ![docker pd before modifying](./screenshots/Task-3/docker%20ps%20before%20modification.png)

- Website before modifying:
    ![Website before modifying](./screenshots/Task-3/Website%20before%20modification.png)

- docker ps after modifying:
    ![docker ps after modifying](./screenshots/Task-3/docker%20ps%20after%20modification.png)

- Website after modifying:
    ![Website after modifying](./screenshots/Task-3/Website%20after%20modification.png)

---

## Task 4:

### What task was:

- Research and understand what Docker Overlay Networks are and how they are used.

- Understand how Overlay Networks allow containers running on multiple Docker hosts to communicate with each other.

- Understand the use cases of Overlay Networks, especially in Docker Swarm and distributed applications.

### Screenshots:

- No screenshots required for this task as it is mainly a research and understanding task.

