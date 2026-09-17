# Session 8 – Docker Networking & Volumes

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Environment:** Docker Desktop 29.0.1 on macOS (Apple Silicon). Docker's "host" here is the Linux VM that Docker Desktop runs, which matters for Task 2.

```text
kushal-24bcs10123/
├── README.md            # this write-up
├── scripts/             # exactly what I ran, one script per task (+ cleanup.sh)
├── logs/                # unedited command output for each task
├── bind-mount/site/     # the folder mounted into nginx in Task 3
└── screenshots/
```

## Task 1 – three containers, three networks

Design: the backend is the only container that lives on two networks, so it can talk to both ends while the frontend and the database can never see each other.

```text
        ui-net (172.18.0.0/16)                 data-net (172.20.0.0/16)
   ┌───────────────────────────┐          ┌────────────────────────────┐
   │ web-ui   (nginx:alpine)   │          │ db-mysql (mysql:8.0)       │
   │ 172.18.0.2                │          │ 172.20.0.3                 │
   │        ▲                  │          │        ▲                   │
   │        │                  │          │        │                   │
   │ api-svc (alpine) 172.18.0.3 ◀──────▶ api-svc 172.20.0.2          │
   └───────────────────────────┘          └────────────────────────────┘
                     api-net (172.19.0.0/16) – third network, created as required,
                     used to show hot-plugging a running container
```

Script: [scripts/task1-networks.sh](scripts/task1-networks.sh) · Log: [logs/task1-networking.txt](logs/task1-networking.txt)

```bash
docker network create ui-net && docker network create api-net && docker network create data-net
docker run -d --name web-ui   --network ui-net   nginx:alpine
docker run -d --name api-svc  --network ui-net   alpine:3.20 sleep infinity
docker network connect data-net api-svc                      # <- backend joins the 2nd network
docker run -d --name db-mysql --network data-net -e MYSQL_ROOT_PASSWORD=secret mysql:8.0
```

```text
$ docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Networks}}'
NAMES      IMAGE          STATUS          NETWORKS
db-mysql   mysql:8.0      Up 25 seconds   data-net
api-svc    alpine:3.20    Up 26 seconds   data-net,ui-net       <- two networks
web-ui     nginx:alpine   Up 26 seconds   ui-net

$ docker inspect -f '{{.Name}}: {{range $k,$v := .NetworkSettings.Networks}}{{$k}}={{$v.IPAddress}} {{end}}' web-ui api-svc db-mysql
/web-ui: ui-net=172.18.0.2
/api-svc: data-net=172.20.0.2 ui-net=172.18.0.3                <- one IP per network
/db-mysql: data-net=172.20.0.3
```

Connectivity checks:

| From | To | Result |
|---|---|---|
| `api-svc` | `web-ui` | `ping` 0 % loss, `wget http://web-ui` → `Welcome to nginx!` |
| `api-svc` | `db-mysql` | `ping` 0 % loss, `nc -zv db-mysql 3306` → **open** |
| `web-ui` | `api-svc` | `ping` OK (same network) |
| `web-ui` | `db-mysql` | `ping: bad address 'db-mysql'`, `nslookup` → **NXDOMAIN** |
| `db-mysql` | `api-svc` | resolves to `172.20.0.2` |
| `db-mysql` | `web-ui` | **not resolvable** |

```text
$ docker exec api-svc nc -zv -w 3 db-mysql 3306
db-mysql (172.20.0.3:3306) open

$ docker exec web-ui nslookup db-mysql
Server:   127.0.0.11
** server can't find db-mysql: NXDOMAIN
```

What I understood: every user-defined bridge network has its own subnet, its own Linux bridge and its own embedded DNS server (`127.0.0.11`) that only knows the containers attached to *that* network. Name resolution therefore doubles as access control: a container that is not on your network is not even a name. `docker network connect` can attach a running container to another network at any time (I did this with `web-ui` on `api-net` and disconnected it again).

## Task 2 – Apache on the host network

Script: [scripts/task2-host-network.sh](scripts/task2-host-network.sh) · Log: [logs/task2-host-network.txt](logs/task2-host-network.txt)

```bash
docker pull httpd:2.4
docker run -d --name apache-host --network host httpd:2.4      # no -p: it binds straight to the host's :80
```

```text
$ docker ps --filter name=apache-host
NAMES         IMAGE       STATUS         PORTS     NETWORKS
apache-host   httpd:2.4   Up 3 seconds             host        <- PORTS column is empty

$ docker inspect -f 'NetworkMode={{.HostConfig.NetworkMode}} PortBindings={{.HostConfig.PortBindings}} ContainerIP="{{.NetworkSettings.IPAddress}}"' apache-host
NetworkMode=host  PortBindings=map[]  ContainerIP=""            <- no veth, no own IP, no NAT

$ docker run --rm --network host alpine:3.20 sh -c 'hostname; netstat -ltn | grep ":80 "; wget -qO- http://localhost:80'
docker-desktop
tcp        0      0 :::80                   :::*                    LISTEN
<html><head><title>It works! Apache httpd</title></head><body><p>It works!</p></body></html>
```

Apache is listening on port 80 of the host network namespace and is reachable at `http://localhost:80` **from that namespace** with no port mapping at all.

Docker Desktop caveat, seen honestly in the log: from the macOS terminal `curl http://localhost:80` fails (`exit code 7`), because on a Mac the "host" is the hidden Linux VM (`hostname` → `docker-desktop`), not macOS itself. On a Linux machine the same `curl` from the terminal works directly. Docker Desktop has an opt-in "Enable host networking" setting that forwards this, which I did not turn on so the default behaviour is documented.

Trade-offs: host networking gives the best performance and no NAT, but the container shares the host's port space (no two containers can use :80), and there is no isolation.

## Task 3 – bind mount

Script: [scripts/task3-bind-mount.sh](scripts/task3-bind-mount.sh) · Log: [logs/task3-bind-mount.txt](logs/task3-bind-mount.txt) · Folder: [bind-mount/site](bind-mount/site)

```bash
mkdir -p site && echo '<h1>Hello students</h1>' > site/index.html
docker run -d --name nginx-bind -p 8085:80 -v "$PWD/site:/usr/share/nginx/html:ro" nginx:alpine
```

```text
$ docker inspect -f '{{range .Mounts}}type={{.Type}} src={{.Source}} dst={{.Destination}} rw={{.RW}}{{end}}' nginx-bind
type=bind src=~/docker-lab/site dst=/usr/share/nginx/html rw=false

$ curl -s http://localhost:8085
<h1>Hello students</h1>
```

![nginx serving the bind-mounted index.html](screenshots/task3-bind-mount-hello-students.png)

Now edit the file **on the host** and read again, without touching the container:

```text
$ printf '<h1>Hello students</h1>\n<p>edited on the host at 21:16:56 - no container restart</p>\n' > site/index.html
$ docker exec nginx-bind cat /usr/share/nginx/html/index.html
<h1>Hello students</h1>
<p>edited on the host at 21:16:56 - no container restart</p>
$ docker ps --filter name=nginx-bind --format '{{.Names}} {{.Status}}'
nginx-bind Up 2 seconds                                        <- same container, never restarted
```

Because I mounted with `:ro`, the container itself cannot change the files:

```text
$ docker exec nginx-bind sh -c 'echo hack > /usr/share/nginx/html/index.html'
sh: can't create /usr/share/nginx/html/index.html: Read-only file system
```

Note: the very first `curl` right after editing still showed the old page for a fraction of a second on macOS (file-sharing sync between macOS and the VM); the `docker exec cat` immediately after showed the new content. On Linux the change is instant because it is literally the same directory.

Bind mount vs named volume: a bind mount points at a host path I choose (great for development, config files, static sites); a named volume (`-v data:/var/lib/mysql`) is managed by Docker under `/var/lib/docker/volumes`, is portable between hosts via backup, and is the right choice for database data.

## Task 4 – overlay networks

Script: [scripts/task4-overlay.sh](scripts/task4-overlay.sh) · Log: [logs/task4-overlay.txt](logs/task4-overlay.txt)

### What I found out

* A **bridge** network lives on one Docker host. An **overlay** network spans **multiple hosts**: containers on different machines get IPs in the same subnet and talk as if they were on one LAN.
* It works by **VXLAN encapsulation**: each packet from a container is wrapped in a UDP packet (port 4789) addressed to the other host's real IP, sent across the physical network, and unwrapped there. A VXLAN Network Identifier (VNI) keeps overlays apart; my network got `vxlan-id=4097`.
* Hosts must be able to reach each other on TCP 2377 (swarm management), TCP/UDP 7946 (gossip/discovery) and UDP 4789 (VXLAN data). The network's state (which container/IP is on which host) is stored in the swarm's Raft-based key-value store, which is why overlays require **swarm mode** (`docker swarm init` / `join`).
* Built-in service discovery and load balancing: a service name resolves to a **virtual IP** that round-robins across replicas on any node; `tasks.<service>` returns every replica's IP. Traffic can also be encrypted with `--opt encrypted` (IPsec).
* Use cases: microservices spread over a cluster, databases and their clients on different nodes, rolling updates with stable service names, Compose stacks deployed with `docker stack deploy`. Kubernetes solves the same problem with CNI plugins (Flannel, Calico, Cilium).

### Hands-on (single node, so the "multi-host" part is simulated on one machine)

```text
$ docker swarm init
Swarm initialized: current node (8d8o31f1...) is now a manager.

$ docker network create -d overlay --attachable app-overlay
$ docker network ls --filter driver=overlay
NAME          DRIVER    SCOPE
app-overlay   overlay   swarm          <- scope is "swarm", not "local"
ingress       overlay   swarm

$ docker network inspect -f 'driver={{.Driver}} scope={{.Scope}} subnet={{(index .IPAM.Config 0).Subnet}} vxlan-id={{index .Options "com.docker.network.driver.overlay.vxlanid_list"}}' app-overlay
driver=overlay scope=swarm subnet=10.0.1.0/24 vxlan-id=4097

$ docker service create -d --name web-svc --network app-overlay --replicas 2 nginx:alpine
$ docker service ls
NAME      MODE         REPLICAS   IMAGE
web-svc   replicated   2/2        nginx:alpine

$ docker run --rm --network app-overlay alpine:3.20 sh -c 'nslookup web-svc | tail -1; nslookup tasks.web-svc | grep Address | tail -2; wget -qO- http://web-svc | grep -o "<h1>.*</h1>"'
Address: 10.0.1.2          <- virtual IP of the service
Address: 10.0.1.3          <- replica 1
Address: 10.0.1.4          <- replica 2
<h1>Welcome to nginx!</h1>
```

Afterwards: `docker service rm web-svc && docker network rm app-overlay && docker swarm leave --force`.

## Cleanup

`scripts/cleanup.sh` removes the Task 1–3 containers and networks.
