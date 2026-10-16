# Session 08 - Docker Networking & Volumes

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 08 - Docker Networking & Volumes |

## Task checklist

- [x] **Task 1** - 3 user-defined networks, a frontend (nginx:alpine), a backend (alpine) on 2 networks, and a MySQL 8 database. Showed frontend↔backend ✅, backend↔db ✅ and frontend↔db ❌, plus `docker network inspect`
- [x] **Task 2** - `httpd` with `--network host` on port 80. It works inside the Docker Desktop VM, but **not** from the macOS host (explained below)
- [x] **Task 3** - Bind-mounted a local folder with `index.html` ("Hello students") into nginx, edited the file on the host, and the change showed up with **no restart**
- [x] **Task 4** - Overlay network write-up, plus a live single-node `docker swarm` + encrypted overlay demo (swarm left afterwards)

Environment: Docker Desktop on macOS (Apple Silicon), Docker Engine `29.7.2 linux/arm64`. All output is real and copied from the terminal (terminal captures are used instead of screenshots). `[exit=N]` is the command's exit code.

---

## Task 1 - Multi-network isolation

### Design

```
 frontend  ==[frontend-net]==  backend  ==[backend-net]==  database  ==[db-net, internal]==  db-backup
nginx:alpine                  alpine:3.22                 mysql:8.4.1                         alpine:3.22
```

| Network | Members | Purpose |
|---|---|---|
| `frontend-net` | frontend, backend | Web tier talks to the API tier |
| `backend-net` | backend, database | API tier talks to the database |
| `db-net` (`--internal`) | database, db-backup | Data tier only (e.g. backup/admin jobs). No internet and no route to other tiers |

- **backend** is attached to **2 networks** (`frontend-net` + `backend-net`), so it is the only container that can reach both the frontend and the database.
- **frontend** and **database** share no network, so they cannot talk to each other at all, not even by IP.
- The database image is `mysql:8.4.1`, which is MySQL 8 (that tag was already available locally).

### Commands

```bash
docker network create frontend-net
docker network create backend-net
docker network create --internal db-net

docker run -d --name database --network backend-net \
  -e MYSQL_ROOT_PASSWORD=Student@123 -e MYSQL_DATABASE=appdb mysql:8.4.1
docker network connect db-net database

docker run -d --name backend --network frontend-net alpine:3.22 sleep infinity
docker network connect backend-net backend          # backend now on 2 networks

docker run -d --name frontend  --network frontend-net nginx:alpine
docker run -d --name db-backup --network db-net       alpine:3.22 sleep infinity
```

```
$ docker ps --filter name=frontend --filter name=backend --filter name=database --filter name=db-backup --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Networks}}'
NAMES       IMAGE          STATUS                  NETWORKS
db-backup   alpine:3.22    Up Less than a second   db-net
frontend    nginx:alpine   Up Less than a second   frontend-net
backend     alpine:3.22    Up 15 seconds           backend-net,frontend-net
database    mysql:8.4.1    Up 31 seconds           backend-net,db-net
```

IP addresses (from `docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}={{$v.IPAddress}} {{end}}' <name>`):

```
frontend: frontend-net=172.19.0.3
backend: backend-net=172.20.0.3 frontend-net=172.19.0.2
database: backend-net=172.20.0.2 db-net=172.21.0.2
db-backup: db-net=172.21.0.3
```

### `docker network inspect`

```
$ docker network ls --filter name=-net
NETWORK ID     NAME           DRIVER    SCOPE
c67ff9ba6b10   backend-net    bridge    local
5be54e0639e0   db-net         bridge    local
18edf902a32e   frontend-net   bridge    local

$ docker network inspect <net> --format '{{.Name}} driver={{.Driver}} internal={{.Internal}} subnet=... {{range .Containers}}...{{end}}'
frontend-net  driver=bridge  internal=false  subnet=172.19.0.0/16  gateway=172.19.0.1
    - frontend  172.19.0.3/16
    - backend  172.19.0.2/16
backend-net  driver=bridge  internal=false  subnet=172.20.0.0/16  gateway=172.20.0.1
    - database  172.20.0.2/16
    - backend  172.20.0.3/16
db-net  driver=bridge  internal=true  subnet=172.21.0.0/16  gateway=172.21.0.1
    - database  172.21.0.2/16
    - db-backup  172.21.0.3/16
```

<details>
<summary>Full <code>docker network inspect backend-net</code></summary>

```json
[
    {
        "Name": "backend-net",
        "Id": "c67ff9ba6b10cc1a5a784239e00220f509672a0c9a21665a1c52592998caa18b",
        "Created": "2026-10-06T11:11:26.758228709Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.20.0.0/16",
                    "Gateway": "172.20.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Options": {
            "com.docker.network.enable_ipv4": "true",
            "com.docker.network.enable_ipv6": "false"
        },
        "Labels": {},
        "Containers": {
            "4d758061f37e8d44ab417222cd83f87ddd233dddb7f9a73ed62d714a480f24a9": {
                "Name": "database",
                "EndpointID": "40e2ecb79de866b9f25ce20f6b064f32add810effb49fc4f8ce823ec2ffabf8c",
                "MacAddress": "b2:10:2e:b2:af:3b",
                "IPv4Address": "172.20.0.2/16",
                "IPv6Address": ""
            },
            "fc1ffdf66dd103f6d8f704a3249df75ae608df5b28a1f5024dfbc9b171be1c34": {
                "Name": "backend",
                "EndpointID": "96ca65be8e657917a586763cdfe1bb0323ac8dd4526737c15daf6420da953eed",
                "MacAddress": "d6:dc:fc:ee:21:5e",
                "IPv4Address": "172.20.0.3/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.20.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
```
</details>

### ✅ frontend ↔ backend works (shared `frontend-net`)

```
$ docker exec frontend getent hosts backend
172.19.0.2        backend  backend
[exit=0]

$ docker exec frontend ping -c 2 backend
PING backend (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.072 ms
64 bytes from 172.19.0.2: seq=1 ttl=64 time=0.078 ms

--- backend ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.072/0.075/0.078 ms
[exit=0]

$ docker exec backend ping -c 2 frontend
PING frontend (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.073 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.055 ms

--- frontend ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.055/0.064/0.073 ms
[exit=0]

$ docker exec backend wget -qO- http://frontend
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<h1>Welcome to nginx!</h1>
...
[exit=0]
```

### ✅ backend ↔ database works (shared `backend-net`)

```
$ docker exec backend getent hosts database
172.20.0.2        database  database
[exit=0]

$ docker exec backend ping -c 2 database
PING database (172.20.0.2): 56 data bytes
64 bytes from 172.20.0.2: seq=0 ttl=64 time=0.167 ms
64 bytes from 172.20.0.2: seq=1 ttl=64 time=0.097 ms

--- database ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.097/0.132/0.167 ms
[exit=0]

$ docker exec backend nc -zv -w 3 database 3306
database (172.20.0.2:3306) open
[exit=0]
```

A real SQL query from the backend. Alpine's `mysql-client` is really the MariaDB client, which also needs `mariadb-connector-c` for MySQL 8's `caching_sha2_password` auth plugin. My first attempt without it failed:

```
$ docker exec backend apk add --no-cache -q mysql-client
[exit=0]
$ docker exec backend mysql -h database -uroot -pStudent@123 --skip-ssl -e "SELECT VERSION() ..."
mysql: Deprecated program name. It will be removed in a future release, use '/usr/bin/mariadb' instead
ERROR 1045 (28000): Plugin caching_sha2_password could not be loaded: Error loading shared library /usr/lib/mariadb/plugin/caching_sha2_password.so: No such file or directory
[exit=1]

$ docker exec backend apk add --no-cache -q mariadb-connector-c
[exit=0]
$ docker exec backend mysql -h database -uroot -pStudent@123 --skip-ssl -e "SELECT VERSION() AS mysql_version; SHOW DATABASES LIKE 'appdb';"
mysql: Deprecated program name. It will be removed in a future release, use '/usr/bin/mariadb' instead
mysql_version
8.4.1
Database (appdb)
appdb
[exit=0]
```

### ❌ frontend ↔ database fails (no shared network)

```
$ docker exec frontend getent hosts database
[exit=2]

$ docker exec frontend ping -c 2 -W 2 database
ping: bad address 'database'
[exit=1]

$ docker exec frontend nc -zv -w 3 database 3306
nc: bad address 'database'
[exit=1]
```

DNS fails because Docker's embedded DNS only resolves containers on the same network. Using the database's IP directly fails too, so this is real network isolation, not just a missing name:

```
$ docker exec frontend ping -c 2 -W 2 172.20.0.2
PING 172.20.0.2 (172.20.0.2): 56 data bytes

--- 172.20.0.2 ping statistics ---
2 packets transmitted, 0 packets received, 100% packet loss
[exit=1]

$ docker exec frontend nc -zv -w 3 172.20.0.2 3306
nc: 172.20.0.2 (172.20.0.2:3306): Operation timed out
[exit=1]

$ docker exec database getent hosts frontend
[exit=2]
```

### Bonus: `--internal` db-net

```
$ docker exec db-backup nc -zv -w 3 database 3306      # same network -> OK
database (172.21.0.2:3306) open
[exit=0]

$ docker exec db-backup ping -c 2 -W 2 backend          # different network -> no DNS
ping: bad address 'backend'
[exit=1]

$ docker exec db-backup ping -c 2 -W 2 172.20.0.3       # internal network has no route out
PING 172.20.0.3 (172.20.0.3): 56 data bytes
ping: sendto: Network unreachable
[exit=1]

$ docker exec db-backup wget -q -T 3 -O- http://example.com   # no internet either
wget: bad address 'example.com'
[exit=1]
```

### Cleanup

```bash
docker rm -f frontend backend database db-backup
docker network rm frontend-net backend-net db-net
```

---

## Task 2 - `httpd` on the host network

```
$ docker run -d --name s08-httpd-host --network host httpd:2.4-alpine
14f4ce1de165a099ec2d5d366a48962608b390dd2e4e7a2ed40378201ce4adeb
[exit=0]

$ docker ps --filter name=s08-httpd-host --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Networks}}'
NAMES            IMAGE              STATUS         PORTS     NETWORKS
s08-httpd-host   httpd:2.4-alpine   Up 3 seconds             host

$ docker inspect -f 'NetworkMode={{.HostConfig.NetworkMode}} PortBindings={{.HostConfig.PortBindings}}' s08-httpd-host
NetworkMode=host PortBindings=map[]

$ docker logs s08-httpd-host
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 192.168.65.3. Set the 'ServerName' directive globally to suppress this message
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 192.168.65.3. Set the 'ServerName' directive globally to suppress this message
[Tue Oct 06 11:13:28.571949 2026] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache/2.4.69 (Unix) configured -- resuming normal operations
[Tue Oct 06 11:13:28.571978 2026] [core:notice] [pid 1:tid 1] AH00094: Command line: 'httpd -D FOREGROUND'
```

There is no `-p` flag and the `PORTS` column is empty. With `--network host` the container has no network namespace of its own: httpd binds port 80 directly on the host's network stack, so port mapping doesn't apply.

### Result from the macOS host: does NOT work

```
$ curl -sS -m 5 http://localhost:80
curl: (7) Failed to connect to localhost port 80 after 0 ms: Couldn't connect to server
[exit=7]
```

### Result from inside the Docker host (Docker Desktop's Linux VM): works

```
$ docker run --rm --network host curlimages/curl -s -i http://localhost:80
HTTP/1.1 200 OK
Date: Tue, 06 Oct 2026 11:13:43 GMT
Server: Apache/2.4.69 (Unix)
Last-Modified: Fri, 07 Nov 2025 08:23:08 GMT
ETag: "bf-642fce432f300"
Accept-Ranges: bytes
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
[exit=0]

$ docker run --rm --network host alpine:3.22 sh -c 'netstat -tln | grep -E "Proto|:80 "'
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 :::80                   :::*                    LISTEN

$ docker run --rm --network host alpine:3.22 sh -c 'hostname; ip -4 addr show eth0 | grep inet'
docker-desktop
    inet 192.168.65.3/24 brd 192.168.65.255 scope global eth0
```

### Why it fails from macOS

On macOS, Docker Engine runs inside a Linux VM (hostname `docker-desktop`, IP `192.168.65.3`). The "host" in `--network host` is **that VM**, not the Mac. httpd is listening on `:::80` in the VM's network namespace, as `netstat` shows, and any other host-network container can reach it. Docker Desktop forwards ports to macOS only for **published** ports (`-p`). Host-networked containers have no published ports, so nothing forwards Mac port 80 into the VM.

Docker Desktop 4.34+ has an opt-in **Settings → Resources → Network → "Enable host networking"** option that forwards host-network ports to the Mac. It is **not enabled** on this machine (no host-networking key is set in Docker Desktop's `settings-store.json`), and I didn't turn it on because this Docker Desktop is shared with other workloads. On a native Linux Docker host, `curl http://localhost:80` would work directly.

**When to use host networking:** for top network performance (no NAT or veth hop), for apps that need many or dynamic ports, and for network tools that must see the host's interfaces. **Downsides:** no isolation, port clashes with host services, and it only works this way on Linux.

```bash
docker rm -f s08-httpd-host
```

---

## Task 3 - Bind mount with live reload

Files: [`bind-mount/index.html`](bind-mount/index.html) (it contains `<h1>Hello students</h1>`).

```
$ cat bind-mount/index.html
<h1>Hello students</h1>

$ docker run -d --name s08-bind -p 9021:80 -v "$(pwd)/bind-mount:/usr/share/nginx/html:ro" nginx:alpine
719fba08f67cd21326c1fffe59f67e6f3a234aa2a1cee2dcbb27b5ae6ca9020f

$ docker ps --filter name=s08-bind --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
NAMES      IMAGE          STATUS         PORTS
s08-bind   nginx:alpine   Up 2 seconds   0.0.0.0:9021->80/tcp, [::]:9021->80/tcp

$ docker inspect -f '{{range .Mounts}}Type={{.Type}} Source={{.Source}} Destination={{.Destination}} RW={{.RW}}{{end}}' s08-bind
Type=bind Source=/Users/ujjawal/SST/devops-heros/.claude/worktrees/agent-a527173b64de439a8/session8-docker-networking-volume/24BCS10267-ujjawal-prabhat/bind-mount Destination=/usr/share/nginx/html RW=false

$ curl -s http://localhost:9021
<h1>Hello students</h1>
```

Next I edited the file **on the host** while the container kept running:

```
$ echo '<p>This line was added on the host while the container was running.</p>' >> bind-mount/index.html

$ curl -s http://localhost:9021
<h1>Hello students</h1>
<p>This line was added on the host while the container was running.</p>

$ docker exec s08-bind cat /usr/share/nginx/html/index.html
<h1>Hello students</h1>
<p>This line was added on the host while the container was running.</p>

$ docker inspect -f 'StartedAt={{.State.StartedAt}} RestartCount={{.RestartCount}}' s08-bind
StartedAt=2026-10-06T11:14:05.019467546Z RestartCount=0
StartedAt before edit: 2026-10-06T11:14:05.019467546Z
```

The new content was served straight away. The `StartedAt` time is unchanged and `RestartCount=0`, so the container was **not** restarted. A bind mount maps the host directory into the container. It is not a copy, so both sides see the same files.

The mount is `:ro`, so the container cannot write back to the host folder:

```
$ docker exec s08-bind sh -c 'echo hack > /usr/share/nginx/html/index.html'
sh: can't create /usr/share/nginx/html/index.html: Read-only file system
[exit=1]
```

(After the demo, the extra line was removed from `bind-mount/index.html` so the committed file holds just "Hello students".)

**Bind mount vs named volume:** a bind mount uses a host path you choose. It suits development (live code reload) and injecting config files, but it depends on the host's directory layout. A named volume (`-v data:/var/lib/mysql`) is managed by Docker under `/var/lib/docker/volumes`, is portable, and is the right choice for persistent data such as databases.

```bash
docker rm -f s08-bind
```

---

## Task 4 - Overlay networks

### What is an overlay network?

An **overlay** network is a virtual Layer-2 network that spans **multiple Docker hosts**. Containers on different machines get IPs in the same subnet (e.g. `10.0.1.0/24`) and talk to each other as if they were on one switch, even though the hosts may sit in different subnets or data centres. It is the `overlay` network driver, and it is the default network type for Docker **Swarm** services.

### How it works: VXLAN

- Docker builds overlays with **VXLAN** (Virtual Extensible LAN, RFC 7348). Each container's Ethernet frame is wrapped in a **UDP packet (port 4789)** and sent over the normal "underlay" network to the destination host, which unwraps it and delivers it to the target container.
- Each overlay gets a **VXLAN Network Identifier (VNI)**, a 24-bit ID that keeps different overlays separate on the same physical network. My demo network got VNI `4097` (`com.docker.network.driver.overlay.vxlanid_list:4097` below).
- On each host, a Linux bridge `br0` inside a dedicated network namespace connects local containers to a `vxlan` interface. A separate `docker_gwbridge` bridge gives the containers outbound internet access.
- **Control plane:** Swarm managers keep the cluster state in Raft and share container-to-host mappings with a gossip protocol, so every host knows which VTEP (host) to send each container's traffic to.

**Ports to open between hosts:** TCP 2377 (swarm management), TCP/UDP 7946 (node gossip/discovery), UDP 4789 (VXLAN data), and IP protocol 50 (ESP) if encryption is enabled.

### Swarm and multi-host networking

- `docker swarm init` creates two networks automatically: `ingress` (an overlay used by the **routing mesh**, so a published service port answers on every node and is load-balanced to any replica) and `docker_gwbridge`.
- User-defined overlays (`docker network create -d overlay`) connect service tasks across nodes. Each service gets a **VIP** plus a DNS name, and `tasks.<service>` returns the IPs of the individual replicas.
- `--attachable` lets plain `docker run` containers (not just services) join the overlay, which is useful for debugging and one-off jobs.
- Without Swarm, overlays need an external key-value store (the old "classic" approach). Kubernetes uses CNI plugins instead (Flannel VXLAN, Calico, Cilium), which are based on the same idea.

### Encryption

- Swarm **control-plane** traffic (between managers and nodes) is always encrypted with mutual TLS.
- **Data-plane** traffic on an overlay is **not** encrypted by default. Creating it with `--opt encrypted` enables **IPsec (ESP, AES-GCM)** tunnels between nodes, with keys that Swarm rotates every 12 hours.
- The trade-off is CPU overhead and lower throughput. It is also not supported on Windows nodes.

### Use cases

- Microservices spread across a cluster that need to reach each other by service name
- High availability: replicas on different hosts behind one VIP or routing mesh
- Isolating tenants or apps with a separate overlay per stack
- Hybrid or multi-datacenter clusters where hosts don't share a Layer-2 segment
- Securing east-west traffic over untrusted networks with `--opt encrypted`

### Live demo (single-node swarm)

```
$ docker info --format 'Swarm={{.Swarm.LocalNodeState}}'
Swarm=inactive

$ docker swarm init --advertise-addr 127.0.0.1
Swarm initialized: current node (qkr4iddsr0fyq2sk4bg2yre9m) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-<redacted> 127.0.0.1:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

$ docker node ls
ID                            HOSTNAME         STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
qkr4iddsr0fyq2sk4bg2yre9m *   docker-desktop   Ready     Active         Leader           29.7.2

$ docker network create --driver overlay --attachable --opt encrypted s08-overlay
glh10cyh32ivb1c0vfziovfd5

$ docker network ls --filter driver=overlay
NETWORK ID     NAME          DRIVER    SCOPE
m8dh8biqc61v   ingress       overlay   swarm
glh10cyh32iv   s08-overlay   overlay   swarm

$ docker network inspect s08-overlay --format 'Name={{.Name}} Driver={{.Driver}} Scope={{.Scope}} Attachable={{.Attachable}} Subnet={{range .IPAM.Config}}{{.Subnet}}{{end}} Options={{.Options}}'
Name=s08-overlay Driver=overlay Scope=swarm Attachable=true Subnet=10.0.1.0/24 Options=map[com.docker.network.driver.overlay.vxlanid_list:4097 encrypted:]

$ docker service create --name s08-web --replicas 2 --network s08-overlay nginx:alpine
gcai9mk6mgi3lsetww1yoqrth
overall progress: 2 out of 2 tasks
...
verify: Service gcai9mk6mgi3lsetww1yoqrth converged

$ docker service ps s08-web --format 'table {{.Name}}\t{{.Image}}\t{{.Node}}\t{{.CurrentState}}'
NAME        IMAGE          NODE             CURRENT STATE
s08-web.1   nginx:alpine   docker-desktop   Running 8 seconds ago
s08-web.2   nginx:alpine   docker-desktop   Running 8 seconds ago

# attachable overlay: a plain container joins, resolves the service VIP + task IPs, and reaches it
$ docker run --rm --network s08-overlay alpine:3.22 sh -c 'nslookup s08-web ...; nslookup tasks.s08-web ...; wget -qO- http://s08-web | grep -o "<title>.*</title>"'
Name:	s08-web
Address: 10.0.1.2
Address: 10.0.1.3
Address: 10.0.1.4
<title>Welcome to nginx!</title>

$ docker service rm s08-web
s08-web
$ docker network rm s08-overlay
s08-overlay
$ docker swarm leave --force
Node left the swarm.
$ docker info --format 'Swarm={{.Swarm.LocalNodeState}}'
Swarm=inactive
```

`s08-web` resolves to the service **VIP** `10.0.1.2`, and `tasks.s08-web` resolves to the two replica IPs `10.0.1.3` and `10.0.1.4`. The network shows its VXLAN ID (`4097`) and the `encrypted` option. The swarm join token is redacted above, and it became invalid anyway once the swarm was left.

**Limitation:** this is a **single-node** swarm (Docker Desktop has one VM), so the VXLAN tunnel between hosts is not actually exercised here. A real multi-host test needs a second machine or VM to run `docker swarm join` and open the ports listed above.
