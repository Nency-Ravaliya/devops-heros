# Session 8 — Docker Networking & Volumes

**Name:** Rohan Ranjan
**Enrollment Number:** 24BCS10428

All four tasks were run on Docker Desktop for macOS. Every code block below is the real output
from that run, and the screenshots are attached at the end of each task.

---

## Task 1: Docker Container Networking

- Create 3 containers: Frontend, Backend, Database.
- Use Nginx or Alpine for the frontend and backend.
- Use the MySQL image for the database.
- Create 3 different Docker networks.
- Add the backend container to 2 networks.
- Check connectivity between the containers.

### Commands

Create the three networks:

```bash
docker network create frontend-net
docker network create backend-net
docker network create database-net
docker network ls
```

Start each container on its own network:

```bash
docker run -dit --name frontend --network frontend-net nginx
docker run -dit --name backend  --network backend-net  alpine
docker run -dit --name database --network database-net -e MYSQL_ROOT_PASSWORD=root mysql:8.0
docker ps
```

### Output

```text
$ docker network ls
NETWORK ID     NAME           DRIVER    SCOPE
ffa1f1187da8   backend-net    bridge    local
7feba9114e77   bridge         bridge    local
d75b850f4906   database-net   bridge    local
8af6b12be1e5   frontend-net   bridge    local
280eb4e99526   host           host      local
23115ddedeb7   none           null      local

$ docker ps
CONTAINER ID   IMAGE           COMMAND                    CREATED          STATUS                  PORTS                                     NAMES
f1424d1044a4   mysql:8.0       "docker-entrypoint.s…"     1 second ago     Up Less than a second   3306/tcp, 33060/tcp                       database
3ad84adb7dc5   alpine          "/bin/sh"                  40 seconds ago   Up 39 seconds                                                     backend
ea86d1aa6ab7   nginx           "/docker-entrypoint.…"     47 seconds ago   Up 47 seconds           80/tcp                                    frontend
```

(`apache-container` from Session 6–7 was also still running on `8080`; it is unrelated to this
task.)

### Commands

Attach `backend` to the other two networks so it sits on all three, then check what it got:

```bash
docker network connect frontend-net backend
docker network connect database-net backend
docker inspect -f '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} -> {{$conf.IPAddress}}{{println}}{{end}}' backend
docker exec backend ping -c 3 frontend
docker exec backend ping -c 3 database
```

### Output

The backend now holds one IP address on each of the three networks:

```text
backend-net  -> 172.19.0.2
database-net -> 172.20.0.3
frontend-net -> 172.18.0.3
```

And it can reach both of the other containers by name:

```text
$ docker exec backend ping -c 3 frontend
PING frontend (172.18.0.2): 56 data bytes
64 bytes from 172.18.0.2: seq=0 ttl=64 time=0.111 ms
64 bytes from 172.18.0.2: seq=1 ttl=64 time=0.186 ms
64 bytes from 172.18.0.2: seq=2 ttl=64 time=0.191 ms

--- frontend ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.111/0.162/0.191 ms

$ docker exec backend ping -c 3 database
PING database (172.20.0.2): 56 data bytes
64 bytes from 172.20.0.2: seq=0 ttl=64 time=0.136 ms
64 bytes from 172.20.0.2: seq=1 ttl=64 time=0.205 ms
64 bytes from 172.20.0.2: seq=2 ttl=64 time=0.221 ms

--- database ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.136/0.187/0.221 ms
```

### Explanation

On a user-defined bridge network Docker runs an embedded DNS server, so containers can address
each other by container name instead of by IP. That is why `ping frontend` works from the
backend without anything being hardcoded.

A container can be attached to several networks at once, and it gets a separate interface and
IP on each — here `172.18.x`, `172.19.x` and `172.20.x`, one per network. That is what makes the
backend able to talk to both the frontend and the database.

The isolation is real, though — being on a network is what grants access, and `frontend` and
`database` share no network. From `backend` the name `database` resolves; from `frontend` it
does not resolve at all. The backend is the only thing bridging the two sides, which is exactly
the point of splitting a three-tier application across separate networks.

![creating three networks, starting the containers, attaching backend to all three networks and pinging frontend and database by name](Screenshots/task-1.png)

---

## Task 2: Host Network

- Pull the Apache2 image from Docker Hub.
- Create an Apache2 container using the host network.
- Access the Apache website directly on port 80.

### Commands

```bash
docker pull ubuntu/apache2
docker run -d --name myapache --network host ubuntu/apache2
docker ps
docker inspect myapache -f 'NetworkMode={{.HostConfig.NetworkMode}}'
curl -s -m 3 http://localhost:80 | head
docker run --rm --network host curlimages/curl:latest -s http://localhost:80 | head -6
```

### Output

```text
$ docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED                  STATUS                  PORTS                NAMES
9ab854f0ef4c   ubuntu/apache2   "apache2-foreground"     Less than a second ago   Up Less than a second                        myapache
...

$ docker inspect myapache -f 'NetworkMode={{.HostConfig.NetworkMode}}'
NetworkMode=host
```

Note the empty `PORTS` column. With `--network host` there is no port mapping at all, because
there is no separate container network namespace to map out of — the container binds port 80
directly on the host.

On this machine Docker Desktop runs the engine inside a Linux VM, so "the host" is that VM and
not macOS. Curling from macOS therefore returns nothing, while a second container placed on the
same host network reaches Apache immediately:

```text
$ curl -s -m 3 http://localhost:80 | head
                                    <- no output from macOS

$ docker run --rm --network host curlimages/curl:latest -s http://localhost:80 | head -6
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <!--
    Modified from the Debian original for Ubuntu
    Last updated: 2022-03-22
    See: https://launchpad.net/bugs/1966004
```

Both containers share the VM's network namespace, so the second one sees Apache on
`localhost:80` with no publishing involved. On a native Linux host, `curl http://localhost:80`
from the terminal would have worked directly.

![apache2 running on the host network and served to another host-network container](Screenshots/task-2.png)

---

## Task 3: Bind Mount

- Create a folder on the local machine.
- Create an `index.html` file with `Hello students` as the content.
- Bind mount the folder to an Nginx container.
- Access the Nginx website and verify the content.
- Modify `index.html`.
- Verify the change is reflected without restarting the container.

### Commands

```bash
mkdir -p bindmount
echo "Hello students" > bindmount/index.html
docker run -dit --name bind-nginx -p 8080:80 -v "$PWD/bindmount":/usr/share/nginx/html nginx
curl -s http://localhost:8080
```

Then edit the file on the host — without touching the container:

```bash
echo "Hello students - Welcome to Docker" > bindmount/index.html
curl -s http://localhost:8080
docker ps --filter name=bind-nginx
```

### Output

```text
$ curl -s http://localhost:8080
Hello students

  ... after editing the file on the host ...

$ curl -s http://localhost:8080
Hello students - Welcome to Docker

NAMES        STATUS
bind-nginx   Up 23 seconds
```

The container was never restarted — its uptime simply keeps counting.

![creating the bind mount, serving it and editing the file in place](Screenshots/task-3.png)

Before the edit:

![browser showing Hello students](Screenshots/bindmount-before.png)

After the edit, same container, no restart:

![browser showing the updated text after editing the file on the host](Screenshots/bindmount-after.png)

### Explanation

A bind mount maps a directory on the host straight into the container. Nginx is not serving a
copy of `index.html` — it is reading the same file on disk, so an edit on the host is visible
on the very next request.

This is the difference from `COPY` in a Dockerfile. `COPY` bakes the file into the image at
build time, and changing it afterwards means rebuilding the image and recreating the container.
A bind mount keeps the file outside the image entirely, which is what makes it useful for local
development.

---

## Task 4: Overlay Network

- Research Docker overlay networks.
- Understand their use cases.
- Understand how overlay networks work across multiple Docker hosts.

### What is an overlay network?

An overlay network is a virtual network that spans **multiple Docker hosts**. The bridge
networks used in Task 1 exist only inside one machine — two containers on separate hosts cannot
reach each other over a bridge. An overlay network sits on top of the physical network and lets
containers on different hosts communicate as if they shared a single LAN.

### How does it work?

Docker encapsulates each container packet inside a **VXLAN** packet, sends it across the real
network to the host holding the destination container, and unwraps it there. The containers
only ever see the virtual network, so neither of them needs to know the other's host.

This requires a cluster, which is why an overlay network can only be created once the engine is
part of a swarm — the swarm's control plane distributes the network definition and keeps the
service discovery records in sync across nodes.

### Commands

```bash
docker swarm init
docker network create -d overlay --attachable my-overlay
docker network ls --filter driver=overlay
```

### Output

```text
$ docker swarm init
Swarm initialized: current node (m9hwsxv89p26rf1dh9xiekwbv) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-1nflut5zx7d4tp10humk2rbbfldeyx5dq2m86m0izcynbi7o89-54spo8ipjwtmf5j62v5sxzqep 192.168.65.3:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

$ docker network ls --filter driver=overlay
NETWORK ID     NAME         DRIVER    SCOPE
gh67rrm142zf   ingress      overlay   swarm
bxvcq2y3qo03   my-overlay   overlay   swarm
```

The `SCOPE` column is the giveaway. The bridge networks from Task 1 are scoped `local` — they
stop at this machine. Both overlay networks are scoped `swarm`, meaning their definition is
shared with every node in the cluster. `ingress` is created automatically by `swarm init` and is
what routes external traffic to published service ports.

![initialising a swarm and creating an overlay network](Screenshots/task-4.png)

### Use cases

- Running a service across several Docker hosts in a swarm, where replicas move between nodes.
- Microservices that need to talk to each other by name regardless of which host they land on.
- Splitting frontend, backend and database across different machines while keeping the same
  network isolation model as Task 1.
- Scaling a service horizontally, where new replicas must join the same network automatically.
