# Session 8 — Docker Networking & Volumes

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Topic:** Docker container networking, host network, bind mounts and overlay networks

All commands were run on a Linux host with its own Docker daemon. Every output block below
is actual terminal output.

---

## Task 1 — Docker Container Networking

**Goal:** 3 containers (frontend, backend, database), 3 networks, backend attached to 2 of
them, then check connectivity.

### 1.1 Create 3 Docker networks

```bash
docker network create frontend-net
docker network create backend-net
docker network create database-net
```

```
30e9ca43731d812f3a7da0e030cae67e0d505938349a03f548850e364ee5269f
135ef37c23b3cba6f0b19c278a763091eccdda89f3c8b7e7eaa4c15b63d4de1b
df276c166d61133a57ded4e315017664499fc5d6c83e63e6c7eda3c7e282f92a
```

```bash
docker network ls
```

```
NETWORK ID     NAME           DRIVER    SCOPE
135ef37c23b3   backend-net    bridge    local
87a617a9c8e2   bridge         bridge    local
df276c166d61   database-net   bridge    local
30e9ca43731d   frontend-net   bridge    local
33da92d29fa0   host           host      local
73d7a0c401e5   none           null      local
```

The three defaults are always there: `bridge` (the default for new containers), `host`
(no isolation — Task 2) and `none` (no networking at all). My three new networks use the
**bridge** driver with **local** scope.

### 1.2 Create the 3 containers

```bash
# frontend - nginx, on frontend-net
docker run -d --name frontend --network frontend-net nginx:alpine

# backend - alpine, on frontend-net
docker run -d --name backend --network frontend-net alpine:3.20 sleep infinity

# database - MySQL, on database-net
docker run -d --name database --network database-net \
  -e MYSQL_ROOT_PASSWORD=Root@1234 -e MYSQL_DATABASE=devops mysql:8.0
```

### 1.3 Add the backend container to a 2nd network

A container can only be given **one** network with `docker run --network`. Additional
networks are attached afterwards with `docker network connect`:

```bash
docker network connect database-net backend
```

```
backend is now attached to BOTH frontend-net and database-net
```

### 1.4 Verify which container is on which network

```bash
docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}({{$v.IPAddress}}) {{end}}' <container>
```

```
frontend -> frontend-net(172.19.0.2)
backend  -> database-net(172.21.0.2) frontend-net(172.19.0.3)
database -> database-net(172.21.0.3)
```

**The backend has two IP addresses** — one on each network. That is the whole point: it acts
as the bridge between the frontend tier and the database tier, and it is the only container
that can reach both.

```bash
docker ps
```

```
NAMES      IMAGE          STATUS
database   mysql:8.0      Up Less than a second
backend    alpine:3.20    Up 52 seconds
frontend   nginx:alpine   Up 57 seconds
```

### 1.5 Check connectivity

#### backend → frontend (share `frontend-net`) — expect success

```bash
docker exec backend ping -c 3 frontend
```

```
PING frontend (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.692 ms
64 bytes from 172.19.0.2: seq=1 ttl=64 time=0.084 ms
64 bytes from 172.19.0.2: seq=2 ttl=64 time=0.091 ms

--- frontend ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
```

Notice I pinged **`frontend`** by name, not by IP. Docker runs an embedded DNS server on
every user-defined network that resolves container names automatically. (This does *not*
work on the default `bridge` network — one of the main reasons to always create your own.)

```bash
docker exec backend wget -qO- http://frontend
```

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

Real HTTP traffic between containers, addressed by name.

#### backend → database (share `database-net`) — expect success

```bash
docker exec backend ping -c 3 database
```

```
PING database (172.21.0.3): 56 data bytes
64 bytes from 172.21.0.3: seq=0 ttl=64 time=1.197 ms
64 bytes from 172.21.0.3: seq=1 ttl=64 time=0.088 ms
64 bytes from 172.21.0.3: seq=2 ttl=64 time=0.110 ms

--- database ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
```

```bash
docker exec backend sh -c 'nc -z -w 3 database 3306 && echo "port 3306 OPEN on database"'
```

```
port 3306 OPEN on database
```

The MySQL port is reachable from the backend — so this is not just ICMP, the actual service
is available.

#### frontend → database (NO shared network) — expect failure

```bash
docker exec frontend ping -c 2 -W 3 database
```

```
ping: bad address 'database'
(exit code: 1)
```

**This failure is the most important result in Task 1.** The name does not even resolve —
Docker's embedded DNS only answers for containers on a network you are *also* attached to.
Since `frontend` is on `frontend-net` and `database` is on `database-net`, the frontend
cannot see the database at all. That is network segmentation working: a compromised
frontend cannot reach the database directly.

#### frontend → backend (share `frontend-net`) — expect success

```bash
docker exec frontend ping -c 2 backend
```

```
PING backend (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.068 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.139 ms

--- backend ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```

### 1.6 Inspect the networks

```bash
docker network inspect frontend-net -f '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
docker network inspect database-net -f '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
docker network inspect backend-net  -f 'Containers attached: {{len .Containers}}'
```

```
frontend-net:
backend 172.19.0.3/16
frontend 172.19.0.2/16

database-net:
backend 172.21.0.2/16
database 172.21.0.3/16

backend-net:
Containers attached: 0
```

`backend` appears in **both** lists, with a different IP in each. `backend-net` was created
as the third network but deliberately left empty, to show that a network with no containers
is perfectly valid — it is just an unused bridge.

### 1.7 The database really is running

```bash
docker exec database mysql -uroot -pRoot@1234 -e "SHOW DATABASES;"
```

```
Database
devops
information_schema
mysql
performance_schema
sys
```

The `devops` database from `MYSQL_DATABASE` was created.

### Task 1 connectivity matrix

| From → To | Shared network | Result |
|---|---|---|
| backend → frontend | `frontend-net` | Reachable (ping + HTTP) |
| backend → database | `database-net` | Reachable (ping + port 3306) |
| frontend → backend | `frontend-net` | Reachable |
| frontend → database | **none** | **Not reachable — name does not resolve** |

---

## Task 2 — Host Network

### 2.1 Pull the Apache2 image

```bash
docker pull httpd:2.4
```

### 2.2 Create an Apache container using the host network

```bash
docker run -d --name apache-host --network host httpd:2.4
```

```
74331476f92d8ace5a127f3c9970ca517b2faa5029c792aa15edafac3e7636fc
```

Note there is **no `-p` flag**. With `--network host` there is nothing to publish — the
container is already on the host's network interfaces.

```bash
docker ps
```

```
NAMES         IMAGE       PORTS     STATUS
apache-host   httpd:2.4             Up 6 seconds
```

The `PORTS` column is **empty**, which surprises people at first. There is no port mapping
because there is no network boundary to map across.

```bash
docker inspect apache-host -f 'NetworkMode={{.HostConfig.NetworkMode}} | PortBindings={{.HostConfig.PortBindings}} | Networks={{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}'
```

```
NetworkMode=host | PortBindings=map[] | Networks=host
```

No port bindings, and the container has **no IP of its own** — it uses the host's.

### 2.3 Access the Apache website directly on port 80

```bash
curl http://localhost:80/
```

```html
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>
```

**Apache is reachable directly on port 80 with no port publishing.**

```bash
curl -sI http://localhost:80/
curl -s -o /dev/null -w "http_code=%{http_code} port=%{remote_port} ip=%{remote_ip}\n" http://localhost:80/
```

```
HTTP/1.1 200 OK
Date: Thu, 17 Sep 2026 20:53:06 GMT
Server: Apache/2.4.68 (Unix)
Last-Modified: Fri, 07 Nov 2025 08:23:08 GMT
ETag: "bf-642fce432f300"

http_code=200 port=80 ip=::1
```

### 2.4 Proof: the container's process is listening on the host's own port 80

```bash
netstat -tulpn | grep ':80 '
```

```
tcp        0      0 :::80                   :::*                    LISTEN      1704/httpd
```

This is the clincher. Run on the **host**, `netstat` shows `httpd` itself bound to port 80.
In bridge mode you would instead see `docker-proxy` holding the port and forwarding into the
container. Here there is no forwarding at all — the container's process *is* the host's
listener.

```bash
docker logs apache-host
```

```
[Thu Sep 17 20:52:59.990775 2026] [core:notice] [pid 1:tid 1] AH00094: Command line: 'httpd -D FOREGROUND'
::1 - - [17/Sep/2026:20:53:06 +0000] "GET / HTTP/1.1" 200 191
::1 - - [17/Sep/2026:20:53:06 +0000] "HEAD / HTTP/1.1" 200 -
::1 - - [17/Sep/2026:20:53:06 +0000] "GET / HTTP/1.1" 200 191
```

Apache logged the requests arriving from `::1` — the host's own loopback address, not a
Docker bridge IP.

### 2.5 Bridge vs host, side by side

```bash
docker ps --format "{{.Names}} PORTS='{{.Ports}}'"
```

```
frontend    PORTS='80/tcp'
apache-host PORTS=''
```

| | Bridge (default) | Host (`--network host`) |
|---|---|---|
| Container IP | Its own, e.g. `172.19.0.2` | None — shares the host's |
| Port publishing | Required (`-p 8080:80`) | Not applicable |
| NAT / `docker-proxy` | Yes, adds a hop | No — zero overhead |
| Isolation | Isolated network namespace | **None** — full access to host interfaces |
| Port conflicts | No (each container has its own stack) | Yes — two containers cannot both take port 80 |
| Container-name DNS | Yes, on user-defined networks | No |

**When to use host networking:** performance-sensitive workloads where the NAT hop matters,
and tools that must see the host's real interfaces — monitoring agents, packet capture,
service discovery. **The cost is isolation**, so it is not the default for a reason.

---

## Task 3 — Bind Mount

### 3.1 Create a folder and an `index.html` on the host

```bash
mkdir -p /root/bindmount
cat > /root/bindmount/index.html <<'EOF'
<!doctype html>
<html>
  <head><title>Bind Mount Demo</title></head>
  <body>
    <h1>Hello students</h1>
  </body>
</html>
EOF
ls -l /root/bindmount
```

```
total 4
-rw-r--r--    1 root     root           124 Sep 17 20:53 index.html
```

### 3.2 Bind mount the folder into an Nginx container

```bash
docker run -d --name nginx-bind -p 8085:80 \
  -v /root/bindmount:/usr/share/nginx/html nginx:alpine
```

```
1bd8caf28e4ee818672f0be573dea84a3967dc28c37c219fb5d7606bc8957745
```

### 3.3 Access the Nginx website and verify the content

```bash
curl http://localhost:8085/
```

```html
<!doctype html>
<html>
  <head><title>Bind Mount Demo</title></head>
  <body>
    <h1>Hello students</h1>
  </body>
</html>
```

**"Hello students" is served** — nginx is serving the file from the host folder, not from
the image.

```bash
docker inspect nginx-bind -f '{{range .Mounts}}Type={{.Type}} Source={{.Source}} Destination={{.Destination}} RW={{.RW}}{{end}}'
```

```
Type=bind Source=/root/bindmount Destination=/usr/share/nginx/html RW=true
```

### 3.4 Proof it is literally the same file, not a copy

```bash
docker exec nginx-bind stat -c 'inode=%i size=%s' /usr/share/nginx/html/index.html
stat -c 'inode=%i size=%s' /root/bindmount/index.html
```

```
inode=280428 size=124
inode=280428 size=124
```

**The same inode number** inside the container and on the host. A bind mount is not a copy
or a sync — the container sees the host's actual file through the same filesystem.

### 3.5 Modify `index.html` on the host

First, record the container's start time so we can prove it was never restarted:

```bash
docker inspect nginx-bind -f 'StartedAt={{.State.StartedAt}} RestartCount={{.RestartCount}}'
```

```
StartedAt=2026-09-17T20:53:06.534998631Z RestartCount=0
```

Now edit the file on the host while the container keeps running:

```bash
cat > /root/bindmount/index.html <<'EOF'
<!doctype html>
<html>
  <head><title>Bind Mount Demo</title></head>
  <body>
    <h1>Hello students</h1>
    <h2>This line was added on the HOST while the container kept running.</h2>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
  </body>
</html>
EOF
```

### 3.6 Verify the change is reflected without restarting the container

```bash
curl http://localhost:8085/
```

```html
<!doctype html>
<html>
  <head><title>Bind Mount Demo</title></head>
  <body>
    <h1>Hello students</h1>
    <h2>This line was added on the HOST while the container kept running.</h2>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
  </body>
</html>
```

**The new content is served immediately.** And the container demonstrably never restarted:

```bash
docker inspect nginx-bind -f 'StartedAt={{.State.StartedAt}} RestartCount={{.RestartCount}}'
docker ps --filter name=nginx-bind --format "{{.Names}} {{.Status}}"
```

```
StartedAt=2026-09-17T20:53:06.534998631Z RestartCount=0
nginx-bind Up 5 seconds
```

`StartedAt` is **identical** to the value recorded before the edit and `RestartCount=0` —
so the change was picked up with no restart, no rebuild and no `docker cp`.

### 3.7 It works in both directions

```bash
docker exec nginx-bind sh -c 'echo "<!-- written from inside the container -->" >> /usr/share/nginx/html/index.html'
tail -2 /root/bindmount/index.html
```

```
</html>
<!-- written from inside the container -->
```

A write from inside the container appears on the host. Bind mounts are read-write unless
you append `:ro`.

### 3.8 Bind mount vs named volume

```bash
docker volume create demo-vol
docker volume inspect demo-vol -f 'Name={{.Name}} Driver={{.Driver}} Mountpoint={{.Mountpoint}}'
docker run --rm -v demo-vol:/data alpine:3.20 sh -c 'echo "data in a named volume" > /data/file.txt; cat /data/file.txt'
ls -l /var/lib/docker/volumes/demo-vol/_data
```

```
Name=demo-vol Driver=local Mountpoint=/var/lib/docker/volumes/demo-vol/_data
data in a named volume
total 4
-rw-r--r--    1 root     root            23 Sep 17 20:53 file.txt
```

| | Bind mount | Named volume |
|---|---|---|
| Location | Any path you choose on the host | Managed by Docker under `/var/lib/docker/volumes/` |
| Syntax | `-v /host/path:/container/path` | `-v volume-name:/container/path` |
| Host dependency | Tied to that exact host path | Portable — Docker manages it |
| Best for | **Development** — live-editing source and config | **Production data** — databases, uploads |
| Backup | Ordinary file tools | `docker volume` commands / volume drivers |
| Permissions | Host ownership applies directly (a common source of errors) | Docker initialises them |

Rule of thumb: **bind mounts for code you are editing, named volumes for data you must not
lose.**

---

## Task 4 — Overlay Network

The task asks for research. I researched it **and** created a working overlay network to
confirm the behaviour.

### 4.1 What an overlay network is

Bridge networks are **local** — they exist on a single Docker host, so two containers on two
different machines cannot talk over a bridge. An **overlay network** spans multiple Docker
hosts, giving containers on different physical machines one flat virtual network where they
can reach each other by container name as if they were side by side.

### 4.2 How it works

1. **VXLAN encapsulation.** Overlay networks use VXLAN (a standard tunnelling protocol).
   A container's Ethernet frame is wrapped inside a UDP packet (port **4789**), sent across
   the physical network to the target host, unwrapped there and delivered to the destination
   container. The containers never know their traffic was tunnelled — that is the "overlay":
   a virtual layer-2 network riding on top of the real layer-3 network.
2. **A distributed key-value store.** The hosts must agree on which container has which
   overlay IP and lives on which host. In Docker Swarm this state is kept in the managers'
   built-in Raft store and gossiped between nodes.
3. **Required ports between hosts:** TCP **2377** (cluster management), TCP+UDP **7946**
   (node discovery/gossip), UDP **4789** (the VXLAN data plane).
4. **Built-in service discovery and load balancing.** A Swarm service name resolves to a
   virtual IP that load-balances across all its tasks, wherever they are running.
5. **Optional encryption** with `--opt encrypted`, which wraps the VXLAN traffic in IPSec —
   valuable because the tunnel otherwise crosses the physical network in the clear.

### 4.3 Overlay requires swarm mode

```bash
docker info --format '{{.Plugins.Network}}'
docker info --format 'Swarm: {{.Swarm.LocalNodeState}}'
```

```
[bridge host ipvlan macvlan null overlay]
Swarm: inactive
```

The `overlay` driver ships with Docker, but it needs a cluster to coordinate state, so it
requires swarm mode (or an external key-value store).

```bash
docker swarm init --advertise-addr 127.0.0.1
```

```
Swarm initialized: current node (2vuao6o2i90bcn1wqdhmlk9g1) is now a manager.
```

### 4.4 Creating an overlay network

```bash
docker network create --driver overlay --attachable app-overlay
docker network ls --filter driver=overlay
```

```
NETWORK ID     NAME          DRIVER    SCOPE
k3pjquy8ksb0   app-overlay   overlay   swarm
uy279wg3wvm5   ingress       overlay   swarm
```

```bash
docker network inspect app-overlay -f 'Name={{.Name}} Driver={{.Driver}} Scope={{.Scope}} Attachable={{.Attachable}} Subnet={{range .IPAM.Config}}{{.Subnet}}{{end}}'
```

```
Name=app-overlay Driver=overlay Scope=swarm Attachable=true Subnet=10.0.1.0/24
```

Two things to note:

- **`Scope=swarm`**, not `local`. This is the key difference from a bridge network — the
  network definition is cluster-wide, so every node in the swarm knows about it.
- The `ingress` overlay network was created automatically by `swarm init`. It is what
  implements the **routing mesh**: a request hitting a published port on *any* node is
  routed over `ingress` to a node actually running the service.

`--attachable` lets plain `docker run` containers join; without it only Swarm services can.

### 4.5 Containers communicating over the overlay

```bash
docker run -d --name ov-a --network app-overlay alpine:3.20 sleep infinity
docker run -d --name ov-b --network app-overlay alpine:3.20 sleep infinity
docker exec ov-a ping -c 3 ov-b
```

```
PING ov-b (10.0.1.4): 56 data bytes
64 bytes from 10.0.1.4: seq=0 ttl=64 time=1.128 ms
64 bytes from 10.0.1.4: seq=1 ttl=64 time=0.067 ms
64 bytes from 10.0.1.4: seq=2 ttl=64 time=0.073 ms

--- ov-b ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
```

Containers on the overlay reach each other **by name**, with addresses from the overlay
subnet `10.0.1.0/24` rather than any host's bridge range. In a multi-node swarm the exact
same command works when `ov-b` is running on a different physical machine — the VXLAN tunnel
makes the host boundary invisible.

### 4.6 Scope comparison

```bash
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
```

```
NAME              DRIVER    SCOPE
app-overlay       overlay   swarm
frontend-net      bridge    local
host              host      local
ingress           overlay   swarm
```

One table, the whole lesson: `bridge` and `host` are **local**; `overlay` is **swarm**-scoped.

### 4.7 Use cases

| Use case | Why overlay |
|---|---|
| Multi-host container clusters | The only built-in driver that spans hosts |
| Docker Swarm services | Services are scheduled across nodes and still need one network |
| Microservices at scale | Name-based discovery and VIP load balancing across replicas |
| Separating environments | Multiple isolated overlays on the same cluster hardware |
| Encrypted east-west traffic | `--opt encrypted` gives IPSec between nodes |

**Kubernetes note:** Kubernetes solves the same problem with CNI plugins (Flannel, Calico,
Cilium, Weave) instead of Docker's overlay driver. Flannel's VXLAN backend works on
essentially the same principle, which is why understanding overlay networking transfers
directly to understanding Kubernetes pod networking.

### 4.8 Network driver summary

| Driver | Scope | Use it for |
|---|---|---|
| `bridge` | local | The default — isolated single-host container networking |
| `host` | local | No isolation, no NAT, direct access to host interfaces |
| `none` | local | Completely disable networking |
| `overlay` | swarm | Multi-host container networking |
| `macvlan` | local | Give a container a real MAC/IP on the physical LAN |
| `ipvlan` | local | Like macvlan but sharing the host's MAC |

---

## Final state

```bash
docker ps
```

```
NAMES         IMAGE          PORTS
ov-b          alpine:3.20
ov-a          alpine:3.20
nginx-bind    nginx:alpine   0.0.0.0:8085->80/tcp, [::]:8085->80/tcp
apache-host   httpd:2.4
database      mysql:8.0      3306/tcp, 33060/tcp
backend       alpine:3.20
frontend      nginx:alpine   80/tcp
```

```bash
docker network ls
```

```
NETWORK ID     NAME              DRIVER    SCOPE
k3pjquy8ksb0   app-overlay       overlay   swarm
135ef37c23b3   backend-net       bridge    local
87a617a9c8e2   bridge            bridge    local
df276c166d61   database-net      bridge    local
f71f49a8da2a   docker_gwbridge   bridge    local
30e9ca43731d   frontend-net      bridge    local
33da92d29fa0   host              host      local
uy279wg3wvm5   ingress           overlay   swarm
73d7a0c401e5   none              null      local
```

(`docker_gwbridge` also appeared — swarm creates it to give overlay-attached containers
outbound access to the outside world.)

---

## Commands used

```bash
# networks
docker network create <name>
docker network create --driver overlay --attachable <name>
docker network ls
docker network inspect <name>
docker network connect <network> <container>      # attach a 2nd network
docker network disconnect <network> <container>
docker network rm <name>

# containers on specific networks
docker run -d --name <n> --network <net> <image>
docker run -d --name <n> --network host <image>   # host networking

# volumes and mounts
docker run -v /host/path:/container/path <image>  # bind mount
docker run -v <volume-name>:/container/path <image>
docker volume create / ls / inspect / rm

# connectivity checks
docker exec <c> ping -c 3 <other-container>
docker exec <c> wget -qO- http://<other-container>
docker exec <c> nc -z -w 3 <host> <port>

# swarm (needed for overlay)
docker swarm init --advertise-addr <ip>
```

---

## Summary

| Task | Status |
|---|---|
| Task 1 — 3 containers (frontend/backend/database), 3 networks, backend on 2 networks, connectivity verified in both the working and the isolated direction | Done |
| Task 2 — Apache2 pulled and run with `--network host`, accessed directly on port 80, confirmed with `netstat` that the container's process holds the host's port | Done |
| Task 3 — Host folder bind-mounted into nginx, "Hello students" served, file modified on the host and change reflected with no restart (proven via identical `StartedAt` and matching inodes) | Done |
| Task 4 — Overlay networks researched, plus a real overlay network created and container-to-container communication over it verified | Done |
