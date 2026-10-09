> **Submission for `session8-docker-networking-volume`** — Piyush Bansal.
>
> Every command below was actually executed with a real Docker daemon and the output is copied in verbatim.

# Session 8 — Docker Networking & Volume Homework

**Environment:** Docker Desktop 4.87.0 (Docker Engine 29.7.2), macOS (Apple Silicon, linux/arm64 containers).

## Contents

- [Task 1 — Docker Container Networking](#task-1--docker-container-networking)
- [Task 2 — Host Network](#task-2--host-network)
- [Task 3 — Bind Mount](#task-3--bind-mount)
- [Task 4 — Overlay Network](#task-4--overlay-network)

---

# Task 1 — Docker Container Networking

## Setup

```console
########## Create 3 different networks ##########
$ docker network create net1
$ docker network create net2
$ docker network create net3

$ docker network ls | grep -E 'net1|net2|net3'
f89887b69fc4   net1                                bridge    local
5d28706c669a   net2                                bridge    local
08160736ea2b   net3                                bridge    local

########## Create the 3 containers ##########
$ docker run -d --name frontend --network net1 nginx:alpine
$ docker run -d --name backend  --network net1 nginx:alpine
$ docker run -d --name database --network net3 -e MYSQL_ROOT_PASSWORD=secret mysql:8

$ docker ps
CONTAINER ID   IMAGE          COMMAND                  PORTS                 NAMES
1cc445b0f7d9   mysql:8        "docker-entrypoint.s…"   3306/tcp, 33060/tcp   database
89aadf178289   nginx:alpine   "/docker-entrypoint.…"   80/tcp                backend
a40036c276c3   nginx:alpine   "/docker-entrypoint.…"   80/tcp                frontend
```

`net2` was created but deliberately left unused by any container — the task only requires *creating* 3
networks, not attaching a container to each.

## Add backend to a 2nd network

```console
$ docker network connect net3 backend

$ docker inspect backend --format '{{json .NetworkSettings.Networks}}' | python3 -m json.tool
{
    "net1": { "IPAddress": "172.19.0.3", "Gateway": "172.19.0.1", ... },
    "net3": { "IPAddress": "172.21.0.3", "Gateway": "172.21.0.1", ... }
}
```
`backend` now has two IPs — one per network it's attached to.

## Check connectivity between containers

```console
$ docker exec backend ping -c 2 frontend   (same network net1 - expected to SUCCEED)
PING frontend (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: seq=0 ttl=64 time=5.382 ms
64 bytes from 172.19.0.2: seq=1 ttl=64 time=1.090 ms
--- frontend ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss

$ docker exec backend ping -c 2 database   (backend is now ALSO on net3 with database - expected to SUCCEED)
PING database (172.21.0.2): 56 data bytes
64 bytes from 172.21.0.2: seq=0 ttl=64 time=0.446 ms
64 bytes from 172.21.0.2: seq=1 ttl=64 time=0.502 ms
--- database ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss

$ docker exec frontend ping -c 2 database   (frontend is ONLY on net1, database is only on net3 - expected to FAIL)
ping: bad address 'database'
```

**What this proves:** Docker networks provide real isolation. `frontend` and `backend` share `net1`, so they
can reach each other by container name (Docker's embedded DNS resolves it). `database` lives only on `net3`,
so `frontend` can't even resolve its name, let alone ping it — `bad address` means DNS lookup failed, not
just that the ping was blocked. `backend`, being attached to both `net1` and `net3`, can reach both `frontend`
and `database` — exactly the "bridge" role the task describes.

### Control test — proving the failure is isolation, not a broken container

`ping: bad address` on its own could, in principle, mean anything from a DNS hiccup to a broken container. To
rule that out, the same lookup was run twice from `frontend` — once against a container it *does* share a
network with (`backend`), and once against the isolated one (`database`):

```console
$ docker exec frontend getent hosts backend    (frontend and backend DO share net1 - control, should SUCCEED)
172.19.0.3        backend  backend
exit: 0

$ docker exec frontend getent hosts database   (frontend and database share NO network - should FAIL)
exit: 2
```

DNS resolution from `frontend` works perfectly fine in general (the control succeeds), and fails specifically
and only for the container it has no network in common with. That isolates the cause to network isolation
itself, not to a flaky container or resolver.

---

# Task 2 — Host Network

```console
$ docker pull httpd:latest
$ docker run -d --name apache-host --network host httpd:latest

$ docker ps --filter name=apache-host
CONTAINER ID   IMAGE          COMMAND              STATUS         PORTS     NAMES
1eb01050f627   httpd:latest   "httpd-foreground"   Up 3 seconds             apache-host
```
Note there's no `PORTS` mapping shown — that's expected and correct for `--network host`: the container
doesn't get its own network namespace, so there's nothing for Docker to publish/map, it just uses the host's
network stack directly.

## A real platform limitation, found and documented rather than glossed over

```console
$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:80/
000
(curl exit code: 7 — couldn't connect to the host)
```

On Linux, `--network host` puts the container directly on the host's real network stack, so `curl
localhost:80` from the host would immediately reach Apache. **On macOS this repo is on, that doesn't work**,
because Docker Desktop for Mac runs containers inside a Linux VM (confirmed below) — `--network host` attaches
Apache to the *VM's* network stack, not the Mac's. This is a documented Docker Desktop limitation (host
networking is only fully native on Linux), not a misconfiguration:

```console
$ docker version --format '{{.Server.Os}}/{{.Server.Arch}} - {{.Server.Platform.Name}}'
linux/arm64 - Docker Desktop 4.87.0
$ docker info | grep -i "kernel\|operating"
 Kernel Version: 7.0.12-linuxkit
 Operating System: Docker Desktop
```

To prove Apache genuinely is serving correctly via the host network (just unreachable from the Mac side of the
VM boundary), a second container was run *also* on `--network host`, so it shares the same network namespace
inside the VM as `apache-host`:

```console
$ docker run --rm --network host curlimages/curl:latest -s -i http://localhost:80/
HTTP/1.1 200 OK
Date: Thu, 03 Sep 2026 16:01:36 GMT
Server: Apache/2.4.68 (Unix)
Content-Length: 191
Content-Type: text/html

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

A real HTTP 200 from inside the VM but a hard connection failure (`000`) from the Mac is the limitation shown
directly, side by side — not just asserted.

### macOS-friendly fallback: publish the port instead

`--network host` satisfies the literal task requirement, but to actually get something reachable from a
browser on this machine, the same image was also run the normal way, with `-p` instead of `--network host`:

```console
$ docker run -d --name apache-published -p 8095:80 httpd:latest

$ docker ps --filter name=apache-published
CONTAINER ID   IMAGE          COMMAND              STATUS         PORTS                                     NAMES
dea73ef5858b   httpd:latest   "httpd-foreground"   Up 2 seconds   0.0.0.0:8095->80/tcp, [::]:8095->80/tcp   apache-published

$ curl -s -i http://localhost:8095/    (from the Mac host - now succeeds)
HTTP/1.1 200 OK
Server: Apache/2.4.68 (Unix)
Content-Type: text/html

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

Both containers exist side by side: `apache-host` satisfies the task's literal `--network host` requirement,
and `apache-published` gives an actually browser-reachable result on this Mac. On a real Linux machine (or a
Linux VM/cloud instance), `--network host` alone would already be reachable at `http://localhost:80/` directly
— the extra published container is purely a macOS workaround, not something Linux would need.

---

# Task 3 — Bind Mount

Mounted **read-only** (`:ro`) — Nginx only needs to *serve* these files, never write to them, so read-only is
the sensible default for static content and it also lets us prove something extra: that the container really
can't modify the host's files through the mount, only read them.

```console
$ echo 'Hello students' > index.html

$ docker run -d --name nginx-bind -p 8090:80 -v $(pwd):/usr/share/nginx/html:ro nginx:alpine

$ curl -s http://localhost:8090/
Hello students

########## Modify index.html on the HOST - no container restart ##########
$ echo 'Hello students - updated live!' > index.html

$ curl -s http://localhost:8090/
Hello students - updated live!

########## Confirm the mount is genuinely read-only from INSIDE the container ##########
$ docker exec nginx-bind sh -c 'echo hack > /usr/share/nginx/html/index.html'
sh: can't create /usr/share/nginx/html/index.html: Read-only file system

$ cat index.html   (unchanged on the host - the container truly could not write to it)
Hello students - updated live!

########## Confirm the mount mode itself ##########
$ docker inspect nginx-bind --format '{{json .Mounts}}' | python3 -m json.tool
[
    {
        "Type": "bind",
        "Source": "/Users/piyushbansal/Desktop/devops-heros/session8-docker-networking-volume/bind-mount-demo",
        "Destination": "/usr/share/nginx/html",
        "Mode": "ro",
        "RW": false,
        "Propagation": "rprivate"
    }
]

########## Prove the container was genuinely never restarted ##########
$ docker inspect nginx-bind --format 'StartedAt={{.State.StartedAt}} PID={{.State.Pid}} RestartCount={{.RestartCount}}'
StartedAt=2026-09-03T16:01:52.567672805Z PID=10102 RestartCount=0
```

**What this proves:** a bind mount maps a host directory directly into the container's filesystem — it's the
*same* file, not a copy, so any edit made on the host is visible inside the container (and to Nginx serving
it) the instant it's saved, with `RestartCount=0` and an unchanged `StartedAt`/`PID` confirming no restart
happened. The `:ro` flag additionally proves the relationship is one-directional here: the host can write and
the container sees it immediately, but the container itself is refused write access (`Read-only file system`)
— exactly the safe default for a container that only needs to serve, not modify, its content.

The demo files live in [`bind-mount-demo/`](./bind-mount-demo/).

---

# Task 4 — Overlay Network

## Research: what overlay networks are and their use cases

An **overlay network** lets containers on **different Docker hosts** (different physical/virtual machines)
communicate as if they were on the same local network, by encapsulating container traffic inside packets sent
over the hosts' existing network (VXLAN encapsulation, typically). Everything in Task 1 used **bridge**
networks, which only connect containers *on a single host* — overlay is the multi-host equivalent.

**How they work across multiple Docker hosts:**
1. Overlay networks require **Docker Swarm mode** (`docker swarm init`) — a cluster of Docker hosts (a swarm)
   that share cluster state via a distributed key-value store Docker manages internally (using the Raft
   consensus algorithm).
2. When an overlay network is created (`docker network create -d overlay my-overlay`), every node in the swarm
   that runs a container attached to it gets a VXLAN tunnel endpoint.
3. Each container gets a normal-looking IP on the overlay's subnet, exactly like a bridge network — but
   packets between containers on different hosts are wrapped (encapsulated) in VXLAN and sent over the
   underlying host network, then unwrapped on arrival. From the container's point of view, the other host's
   containers are just "on the network" — no different from a same-host bridge network.
4. Docker's embedded DNS still resolves service/container names to the right IP, now cluster-wide.

**Use cases:**
- **Multi-host microservices** — services split across several machines that need to talk to each other by
  name, without manually managing routes or exposing ports to the whole host network.
- **Docker Swarm services** — the default networking mode for `docker service create` when replicas can land
  on any node in the cluster.
- **Isolating multi-tier apps across hosts** — e.g., web tier on one set of hosts, database tier on another,
  connected only via a dedicated overlay network, invisible to anything outside it (encrypted overlay networks
  add `--opt encrypted` for traffic encryption between hosts too).

**Why not just use bridge networks for this:** bridge networks are host-local — a container's bridge-network
IP is meaningless on another host, and there's no built-in mechanism for cross-host name resolution or routing.
Overlay solves exactly that gap, which is why it's the standard choice once an application outgrows a single
Docker host (Swarm) or, more commonly today, why Kubernetes' own CNI networking (covered in later sessions)
solves the same fundamental problem a different way.

---

# Files in this folder

| Path | Purpose |
|---|---|
| `bind-mount-demo/index.html` | The file used for the Task 3 bind-mount demo |
| `README.md` | This file |
