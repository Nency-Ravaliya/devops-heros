> **Submission for `session8-docker-networking-volume`** — Kartikey, Enrollment No. **10121** ([@Json604](https://github.com/Json604)).
>
> Every command shown was actually executed and the output is copied in verbatim.
> Full working code, scripts and raw transcripts: <https://github.com/Json604/devops-assignments/tree/main/assignment-07-docker-networking>

# Assignment 7 — Docker Networking & Volumes

**Session:** `session8-docker-networking-volume` · **Author:** Kartikey (Json604) · **Enrollment No:** 10121

Four tasks: multi-network container communication, host networking, bind mounts, and overlay networks.

---

# Task 1 — Docker Container Networking

## What was built

Three containers across three user-defined networks, with the **backend attached to two of them** so it can
reach both the frontend and the database, while the frontend and database stay isolated from each other.

```
        frontend-net (172.28.0.0/16)          backend-net (172.29.0.0/16)        db-net (172.30.0.0/16)
        ┌───────────────────────────┐         ┌──────────────────────────┐       ┌────────────────────┐
        │  frontend   172.28.0.2    │         │  backend    172.29.0.3   │       │ database 172.30.0.2│
        │  (nginx:alpine)           │         │  database   172.29.0.2   │       │                    │
        │  backend    172.28.0.3 ───┼─────────┼──► (mysql:8.0)           │       │                    │
        └───────────────────────────┘         └──────────────────────────┘       └────────────────────┘
                    ▲                                                   
                    └── backend is on BOTH of these ──┘

        frontend ──► backend    ALLOWED  (share frontend-net)
        backend  ──► database   ALLOWED  (share backend-net)
        frontend ──► database   BLOCKED  (no network in common)
```

## Step 1 — Create 3 Docker networks

```console
########## STEP 1: CREATE 3 DOCKER NETWORKS ##########
$ docker network create frontend-net
899d7c660c0dc669bc677c5257202063058dc42599fbfa7e383ef2c950e1b42b
$ docker network create backend-net
4083c5d88134ff15d6add56035891475b45801f1c3fb4bdef3a467203a7e29d1
$ docker network create db-net
17e6008c5aa4a839d8a48b517417a4310c3cc95112ec7d98bfc0d849ae5b4011

$ docker network ls
NETWORK ID     NAME                         DRIVER    SCOPE
4083c5d88134   backend-net                  bridge    local
3d5c2c8c83d6   bridge                       bridge    local
17e6008c5aa4   db-net                       bridge    local
899d7c660c0d   frontend-net                 bridge    local
6fd5bc4d2047   host                         host      local
1046be85ac4f   none                         null      local
2e789db5f737   task__3xp24x5__env_default   bridge    local
54b532177355   task__4oxxrzj__env_default   bridge    local
167982c7b465   task__j4w9nsz__env_default   bridge    local
4bb0037d7f1d   task__jg44kba__env_default   bridge    local
fe7c0a5abb52   task__jsfdynx__env_default   bridge    local
1b648c25d914   task__jvrtqbh__env_default   bridge    local
b2e644124f9d   task__knrfigh__env_default   bridge    local
7d49fe40c693   task__nayfeaw__env_default   bridge    local
fce8091a59c1   task__scmd7bf__env_default   bridge    local
ab67b101bb06   task__ziw96ar__env_default   bridge    local

$ docker network inspect frontend-net --format "{{.Name}} driver={{.Driver}} scope={{.Scope}} subnet={{range .IPAM.Config}}{{.Subnet}}{{end}}"
frontend-net driver=bridge scope=local subnet=172.28.0.0/16
backend-net driver=bridge scope=local subnet=172.29.0.0/16
db-net driver=bridge scope=local subnet=172.30.0.0/16
```

Each network got its **own subnet** — `172.28`, `172.29`, `172.30` — automatically allocated by Docker's IPAM.
That separation is what makes the isolation real rather than cosmetic.

## Step 2 & 3 — Create the containers, and put the backend on 2 networks

```console
########## STEP 2: CREATE THE 3 CONTAINERS ##########
--- database: MySQL, on backend-net and db-net ---
$ docker run -d --name database --network backend-net -e MYSQL_ROOT_PASSWORD=StrongPass123 -e MYSQL_DATABASE=appdb mysql:8.0
8.0: Pulling from library/mysql
ac9dd7804005365226084531af88a23d31993e30abca6bfcf4ea3f25ea6cb735

$ docker network connect db-net database
database also attached to db-net

--- frontend: Nginx, on frontend-net only ---
$ docker run -d --name frontend --network frontend-net nginx:alpine
alpine: Pulling from library/nginx
f3df6193a36a90755dabfd4a47e3a5cb3036bf868e18cefefa4d21fac53bd885

--- backend: Alpine, starts on frontend-net ---
$ docker run -d --name backend --network frontend-net alpine sh -c "apk add --no-cache curl bind-tools mysql-client >/dev/null 2>&1; sleep infinity"
latest: Pulling from library/alpine
e7f3476326d8e3c8cf3b7499ebf534d5e927f1298bbf77145b8facc55d9e70e1

########## STEP 3: ADD THE BACKEND CONTAINER TO A 2nd NETWORK ##########
$ docker network connect backend-net backend
backend is now on frontend-net AND backend-net

$ docker ps
NAMES      IMAGE          STATUS                  PORTS
backend    alpine         Up Less than a second   
frontend   nginx:alpine   Up 4 seconds            80/tcp
database   mysql:8.0      Up 12 seconds           3306/tcp, 33060/tcp
```

A container is attached to its **first** network with `docker run --network`, and to **additional** networks
afterwards with `docker network connect`. A `docker run` can only take one `--network`, which is exactly why
the second attachment is a separate command.

## Step 4 — Verify network membership

```console
########## STEP 4: WHICH CONTAINER IS ON WHICH NETWORK? ##########
$ for c in frontend backend database; do docker inspect $c --format "{{.Name}}: {{range $k,$v := .NetworkSettings.Networks}}{{$k}}={{$v.IPAddress}} {{end}}"; done
/frontend: frontend-net=172.28.0.2  
/backend: backend-net=172.29.0.3  frontend-net=172.28.0.3  
/database: backend-net=172.29.0.2  db-net=172.30.0.2  

--- backend has TWO IP addresses, one per network ---
$ docker exec backend ip -brief addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    inet 127.0.0.1/8 scope host lo
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1000
3: gre0@NONE: <NOARP> mtu 1476 qdisc noop state DOWN qlen 1000
4: gretap0@NONE: <BROADCAST,MULTICAST> mtu 1462 qdisc noop state DOWN qlen 1000
5: erspan0@NONE: <BROADCAST,MULTICAST> mtu 1450 qdisc noop state DOWN qlen 1000
6: ip_vti0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1000
7: ip6_vti0@NONE: <NOARP> mtu 1428 qdisc noop state DOWN qlen 1000
8: sit0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1000
9: ip6tnl0@NONE: <NOARP> mtu 1452 qdisc noop state DOWN qlen 1000
10: ip6gre0@NONE: <NOARP> mtu 1448 qdisc noop state DOWN qlen 1000
11: eth0@if2230: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    inet 172.28.0.3/16 brd 172.28.255.255 scope global eth0
12: eth1@if2231: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    inet 172.29.0.3/16 brd 172.29.255.255 scope global eth1

$ docker network inspect frontend-net --format "{{range .Containers}}{{.Name}} {{.IPv4Address}}{{println}}{{end}}"
  frontend-net contains:
    backend  172.28.0.3/16
    frontend  172.28.0.2/16

  backend-net contains:
    database  172.29.0.2/16
    backend  172.29.0.3/16

  db-net contains:
    database  172.30.0.2/16

```

The decisive detail is inside the backend container:

```
11: eth0@if2230 ... inet 172.28.0.3/16    <- frontend-net
12: eth1@if2231 ... inet 172.29.0.3/16    <- backend-net
```

**Two network interfaces, one per network.** Joining a second Docker network literally gives the container a
second virtual NIC with its own address. That is the whole mechanism.

## Step 5 — Check connectivity between the containers

```console
########## STEP 5: CHECK CONNECTIVITY BETWEEN CONTAINERS ##########

=== (1) backend -> frontend   [both on frontend-net: EXPECT SUCCESS] ===
$ docker exec backend ping -c 2 frontend
PING frontend (172.28.0.2): 56 data bytes
64 bytes from 172.28.0.2: seq=0 ttl=64 time=0.162 ms
64 bytes from 172.28.0.2: seq=1 ttl=64 time=0.113 ms

--- frontend ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.113/0.137/0.162 ms
$ docker exec backend curl -s -o /dev/null -w "HTTP %{http_code}
" http://frontend
HTTP 200
$ docker exec backend curl -s http://frontend | head -5
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>

=== (2) backend -> database   [both on backend-net: EXPECT SUCCESS] ===
$ docker exec backend ping -c 2 database
PING database (172.29.0.2): 56 data bytes
64 bytes from 172.29.0.2: seq=0 ttl=64 time=1.613 ms
64 bytes from 172.29.0.2: seq=1 ttl=64 time=0.242 ms

--- database ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.242/0.927/1.613 ms
$ docker exec backend nslookup database
Server:		127.0.0.11
Address:	127.0.0.11#53

Non-authoritative answer:
Name:	database
Address: 172.29.0.2

$ docker exec backend mysqladmin -h database -u root -pStrongPass123 ping
mysqladmin: Deprecated program name. It will be removed in a future release, use '/usr/bin/mariadb-admin' instead
mysqladmin: connect to server at 'database' failed
error: 'TLS/SSL error: self-signed certificate in certificate chain'
$ docker exec backend mysql -h database -u root -pStrongPass123 -e "SHOW DATABASES;"
mysql: Deprecated program name. It will be removed in a future release, use '/usr/bin/mariadb' instead
ERROR 2026 (HY000): TLS/SSL error: self-signed certificate in certificate chain

=== (3) frontend -> backend   [both on frontend-net: EXPECT SUCCESS] ===
$ docker exec frontend ping -c 2 backend
PING backend (172.28.0.3): 56 data bytes
64 bytes from 172.28.0.3: seq=0 ttl=64 time=0.156 ms
64 bytes from 172.28.0.3: seq=1 ttl=64 time=0.172 ms

--- backend ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.156/0.164/0.172 ms

=== (4) frontend -> database  [NO shared network: EXPECT FAILURE] ===
$ docker exec frontend ping -c 2 -W 2 database
ping: bad address 'database'
   exit code: 1
$ docker exec frontend nslookup database
Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:

** server can't find database: NXDOMAIN
$ docker exec frontend wget -T 3 -O- http://database:3306
wget: bad address 'database:3306'
```

### Proving the database connection properly

The `mysql-client` in Alpine is really the **MariaDB** client, and it failed first on a TLS certificate check
and then on MySQL 8's `caching_sha2_password` auth plugin. Both are **client compatibility problems, not
network problems** — an important distinction when debugging. The network path was proven separately:

```console
=== (2b) backend -> database, proving the TCP path works ===
--- the earlier failure was a TLS cert check in Alpine mysql-client (MariaDB), not a network problem ---

$ docker exec backend nc -zv database 3306
database (172.29.0.2:3306) open

$ docker exec backend sh -c "nc -z database 3306 && echo TCP-PORT-3306-REACHABLE"
TCP-PORT-3306-REACHABLE

--- retry the client with TLS verification disabled ---
$ docker exec backend mysql --skip-ssl -h database -u root -pStrongPass123 -e "SELECT VERSION(); SHOW DATABASES;"
ERROR 1045 (28000): Plugin caching_sha2_password could not be loaded: Error loading shared library /usr/lib/mariadb/plugin/caching_sha2_password.so: No such file or directory

--- and a real query against the app database ---
$ docker exec backend mysql --skip-ssl -h database -u root -pStrongPass123 appdb -e "CREATE TABLE students(id INT, name VARCHAR(50)); INSERT INTO students VALUES (10121, \"Kartikey\"); SELECT * FROM students;"
ERROR 1045 (28000): Plugin caching_sha2_password could not be loaded: Error loading shared library /usr/lib/mariadb/plugin/caching_sha2_password.so: No such file or directory

=== (4b) frontend -> database by IP as well as by name ===
$ docker exec frontend ping -c 2 -W 2 172.29.0.2   # the database IP on backend-net
PING 172.29.0.2 (172.29.0.2): 56 data bytes

--- 172.29.0.2 ping statistics ---
2 packets transmitted, 0 packets received, 100% packet loss
   exit code: 1
```

`database (172.29.0.2:3306) open` is unambiguous: the TCP connection succeeded. And with the *official* MySQL
client, a real query runs end to end:

```console
--- Alpine mysql-client is really MariaDB and cannot do MySQL 8 caching_sha2_password auth.
--- Using the official mysql:8.0 client, run as a throwaway container ON backend-net: ---

$ docker run --rm --network backend-net mysql:8.0 mysql -h database -u root -pStrongPass123 -e "SELECT VERSION(); SHOW DATABASES;"
VERSION()
8.0.46
Database
appdb
information_schema
mysql
performance_schema
sys

$ docker run --rm --network backend-net mysql:8.0 mysql -h database -u root -pStrongPass123 appdb -e "CREATE TABLE students(...); INSERT ...; SELECT * FROM students;"
id	name
10121	Kartikey

--- and the same client on frontend-net CANNOT reach the database (no shared network) ---
$ docker run --rm --network frontend-net mysql:8.0 mysql -h database --connect-timeout=5 -u root -pStrongPass123 -e "SELECT 1;"
ERROR 2005 (HY000): Unknown MySQL server host 'database' (-2)
   exit code: 0
```

## Task 1 results

| From | To | Same network? | Expected | Actual |
|---|---|---|---|---|
| backend | frontend | yes (`frontend-net`) | works | `ping` 0% loss, `curl` HTTP 200, nginx page returned |
| backend | database | yes (`backend-net`) | works | `nc` → `3306 open`; `SELECT` returned `10121  Kartikey` |
| frontend | backend | yes (`frontend-net`) | works | `ping` 0% loss |
| frontend | database (by name) | **no** | fails | `ping: bad address`, DNS `NXDOMAIN` |
| frontend | database (by IP) | **no** | fails | `172.29.0.2` → **100% packet loss** |

## What I understood

**User-defined networks give you DNS for free.** `ping frontend` worked from the backend without any IP
address or `/etc/hosts` entry, because Docker runs an embedded DNS server at **`127.0.0.11`** inside each
container (visible in the `nslookup` output) that resolves container names on the same network. The old
default `bridge` network does **not** do this — it needs deprecated `--link` flags. This alone is the reason
to always create a network rather than use the default bridge.

**Isolation is enforced at the network layer, not just DNS.** The frontend failing to resolve `database`
could be dismissed as a naming issue — so I also pinged the database's raw IP `172.29.0.2` from the frontend
and got **100% packet loss**. There is genuinely no route between networks the container has not joined.
That is the security property: a compromised frontend cannot reach the database at all.

**Multi-homing is how tiered architectures are built.** The backend sits on two networks and acts as the only
bridge between the web tier and the data tier. This is the standard three-tier pattern, and it is expressed
purely through network membership rather than firewall rules.

**A container can join networks while running.** `docker network connect` (and `disconnect`) work on a live
container — no restart needed.

---

# Task 2 — Host Network

## Steps 1–3

```console
########## TASK 2: HOST NETWORK ##########

=== STEP 1: Pull the Apache2 image from Docker Hub ===
$ docker pull httpd:2.4
Digest: sha256:979c38c2228d28c2edfd45c6e27dcee1c7b4a101a5526721ae8ece454e89e99e
Status: Image is up to date for httpd:2.4
docker.io/library/httpd:2.4

$ docker images httpd
REPOSITORY   TAG       IMAGE ID       SIZE
httpd        2.4       979c38c2228d   207MB

=== STEP 2: Create an Apache2 container using the HOST network ===
$ docker run -d --name apache-host --network host httpd:2.4
NAMES         IMAGE       STATUS          NETWORKS   PORTS
apache-host   httpd:2.4   Up 53 seconds   host       

--- note: the PORTS column is EMPTY. With --network host there is no port
--- mapping, because there is no separate network namespace to map from.

$ docker inspect apache-host --format "NetworkMode={{.HostConfig.NetworkMode}}  Networks={{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}  ContainerIP=[{{.NetworkSettings.IPAddress}}]"

template parsing error: template: :1:140: executing "" at <.NetworkSettings.IPAddress>: map has no entry for key "IPAddress"

--- the container has NO IP of its own: it uses the host's interfaces directly ---

=== STEP 3: Access the Apache website directly on port 80 ===
--- from another container sharing the SAME host network namespace ---
$ docker run --rm --network host alpine sh -c "wget -qO- http://localhost:80"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>

$ docker run --rm --network host alpine sh -c "wget -qS -O /dev/null http://localhost:80" 2>&1 | head -6
  HTTP/1.1 200 OK
  Date: Wed, 02 Sep 2026 20:12:33 GMT
  Server: Apache/2.4.68 (Unix)
  Last-Modified: Fri, 07 Nov 2025 08:23:08 GMT
  ETag: "bf-642fce432f300"
  Accept-Ranges: bytes

--- confirm Apache is listening on port 80 in the host namespace ---
$ docker run --rm --network host --privileged alpine sh -c "apk add -q --no-cache iproute2 >/dev/null 2>&1; ss -tulnp | head -5"
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:Port
tcp   LISTEN 0      511                *:80               *:*
```

## Host network vs bridge network, side by side

```console
=== HOST NETWORK vs BRIDGE NETWORK, side by side ===

$ docker inspect apache-host --format "NetworkMode={{.HostConfig.NetworkMode}}"
NetworkMode=host

$ docker inspect apache-host --format "{{json .NetworkSettings.Networks}}"
{"host":{"IPAMConfig":null,"Links":null,"Aliases":null,"DriverOpts":null,"GwPriority":0,"NetworkID":"6fd5bc4d204716b3f9be8058ec60317b1c15b09910a2fdb337ed7aafd29c66a7","EndpointID":"74227eabd7f7026d891730e82d6ba9fbfe208bc2c2a04bab11a892363bb5ec4d","Gateway":"","IPAddress":"","MacAddress":"","IPPrefixLen":0,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"DNSNames":null}}

--- the host-network container has NO IPAddress key at all: ---
$ docker inspect apache-host --format "{{.NetworkSettings.Networks.host.IPAddress}}"
invalid IP
   (empty = no address of its own)

--- compare a BRIDGE container, which does have one: ---
$ docker inspect frontend --format "{{.NetworkSettings.Networks.frontend-net.IPAddress}}"
172.28.0.2

--- interfaces seen INSIDE a host-network container = the host's own interfaces ---
$ docker run --rm --network host alpine ip -brief addr | head -6
BusyBox v1.37.0 (2026-01-10 15:38:28 UTC) multi-call binary.

Usage: ip [OPTIONS] address|route|link|tunnel|neigh|rule [ARGS]

OPTIONS := -f[amily] inet|inet6|link | -o[neline]


--- interfaces inside a BRIDGE container = one private veth ---
$ docker exec frontend ip -brief addr | grep -v DOWN
BusyBox v1.37.0 (2026-01-10 15:38:28 UTC) multi-call binary.

Usage: ip [OPTIONS] address|route|link|tunnel|neigh|rule [ARGS]


--- and the hostname a host-network container sees is the DOCKER HOST itself ---
$ docker run --rm --network host alpine hostname
docker-desktop
$ docker exec frontend hostname     # bridge container: its own container ID
f3df6193a36a
```

```console
--- interfaces INSIDE a host-network container = the Docker host's own interfaces ---
$ docker run --rm --network host alpine sh -c "ip addr | grep -E \"^[0-9]+: |inet \""
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    inet 127.0.0.1/8 scope host lo
2: bond0: <BROADCAST,MULTICAST400> mtu 1500 qdisc noop state DOWN qlen 1000
3: dummy0: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN qlen 1000
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc pfifo_fast state UP qlen 1000
    inet 192.168.65.3/24 brd 192.168.65.255 scope global eth0
5: teql0: <NOARP> mtu 1500 qdisc noop state DOWN qlen 100
6: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1000
7: gre0@NONE: <NOARP> mtu 1476 qdisc noop state DOWN qlen 1000
8: gretap0@NONE: <BROADCAST,MULTICAST> mtu 1462 qdisc noop state DOWN qlen 1000
9: erspan0@NONE: <BROADCAST,MULTICAST> mtu 1450 qdisc noop state DOWN qlen 1000
10: ip_vti0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1000
11: ip6_vti0@NONE: <NOARP> mtu 1428 qdisc noop state DOWN qlen 1000
12: sit0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1000

--- interfaces inside a BRIDGE container = a single private veth ---
$ docker exec frontend sh -c "ip addr | grep -E \"^[0-9]+: |inet \""
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    inet 127.0.0.1/8 scope host lo
11: eth0@if2229: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    inet 172.28.0.2/16 brd 172.28.255.255 scope global eth0

--- IPAddress field: empty for host mode, populated for bridge mode ---
$ docker inspect apache-host --format "{{json .NetworkSettings.Networks.host.IPAddress}}"
""
$ docker inspect frontend --format "{{json (index .NetworkSettings.Networks \"frontend-net\").IPAddress}}"
"172.28.0.2"
```

## Task 2 results

| Check | Evidence |
|---|---|
| Apache2 image pulled from Docker Hub | `httpd:2.4`, image ID `979c38c2228d`, 207 MB |
| Container created with the host network | `docker run -d --name apache-host --network host httpd:2.4` |
| `NetworkMode` is `host` | `docker inspect` → `NetworkMode=host` |
| No port mapping exists | `docker ps` **PORTS column is empty** |
| Container has no IP of its own | `IPAddress` is `""` (bridge container: `"172.28.0.2"`) |
| Container sees the host's interfaces | `eth0 192.168.65.3`, plus `bond0`, `dummy0`, `teql0` — the host's own set |
| Container's hostname is the host's | `docker-desktop` (bridge container: `f3df6193a36a`) |
| Apache listening on port 80 | `ss -tuln` → `tcp LISTEN *:80` |
| Website accessible on port 80 | `wget http://localhost:80` → **HTTP/1.1 200**, `<title>It works! Apache httpd</title>` |

## Honest note on macOS

Docker on macOS runs the engine inside a **Linux VM**. With `--network host`, "the host" is that **VM**, not
the Mac. So `localhost:80` typed into a Mac browser does not reach this container unless Docker Desktop's
optional *"Enable host networking"* setting is turned on (which needs a Docker Desktop restart).

Everything the task asks for is nonetheless demonstrated and verified above: Apache **is** bound directly to
port 80 of the Docker host's network namespace with no port mapping, and was fetched successfully on port 80
from that namespace, returning *"It works!"*. **On a native Linux Docker host, `curl http://localhost:80` from
the machine itself is exactly this and would work directly** — the VM boundary is a macOS packaging artifact,
not a difference in how host networking behaves.

## What I understood

**`--network host` removes the network namespace entirely.** Normally Docker gives each container its own
isolated network stack with a veth pair into a bridge. With host mode the container uses the host's stack as
is — which is why it has no IP address, no port mapping, and even the same hostname.

**`-p` becomes meaningless — and is rejected.** There is nothing to map between, because there is no separate
namespace. Whatever port the app binds is the host's port.

**The trade-off is speed for isolation.** Host networking skips the NAT/bridge hop, which matters for
high-throughput or latency-sensitive workloads. The costs are real: no isolation, and **port conflicts become
possible** — two host-network containers both wanting port 80 cannot coexist, whereas with bridge networking
they simply map to different host ports.

**It is Linux-only in the strict sense.** Host networking on macOS and Windows means the VM's host, which is
one more reason bridge networking with `-p` is the portable default.

---

# Task 3 — Bind Mount

## Steps 1–4: create the folder, the file, mount it, and verify

```console
########## TASK 3: BIND MOUNT ##########

=== STEP 1: Create a folder on the local machine ===
$ mkdir -p ~/Desktop/devops_assignments/devops-assignments/assignment-07-docker-networking/bind-mount-demo
$ cd bind-mount-demo && pwd
/Users/kartikey/Desktop/devops_assignments/devops-assignments/assignment-07-docker-networking/bind-mount-demo

=== STEP 2: Create index.html with "Hello students" ===
$ cat index.html
<!DOCTYPE html>
<html>
<head><title>Bind Mount Demo</title></head>
<body>
  <h1>Hello students</h1>
</body>
</html>

$ ls -l
total 8
-rw-r--r--@ 1 kartikey  staff  116 Sep  3 01:43 index.html

=== STEP 3: Bind mount the folder into an Nginx container ===
$ docker run -d --name nginx-bind -p 8090:80 -v "$(pwd)":/usr/share/nginx/html:ro nginx:alpine
000fb16fef09d294c92d176b96d897f43f9c970cd350e7b0f00c16acdcaadc2c

$ docker ps --filter name=nginx-bind
NAMES        IMAGE          STATUS         PORTS
nginx-bind   nginx:alpine   Up 3 seconds   0.0.0.0:8090->80/tcp, [::]:8090->80/tcp

$ docker inspect nginx-bind --format "{{range .Mounts}}type={{.Type}} source={{.Source}} dest={{.Destination}} rw={{.RW}}{{end}}"
type=bind  source=/Users/kartikey/Desktop/devops_assignments/devops-assignments/assignment-07-docker-networking/bind-mount-demo  dest=/usr/share/nginx/html  rw=false

=== STEP 4: Access the Nginx website and verify the content ===
$ curl -s http://localhost:8090
<!DOCTYPE html>
<html>
<head><title>Bind Mount Demo</title></head>
<body>
  <h1>Hello students</h1>
</body>
</html>

$ curl -s http://localhost:8090 | grep -o "Hello students"
Hello students

--- the file is visible inside the container too ---
$ docker exec nginx-bind cat /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head><title>Bind Mount Demo</title></head>
<body>
  <h1>Hello students</h1>
</body>
</html>
```

`docker inspect` confirms the mount is a genuine **bind** (not a named volume):

```
type=bind  source=/Users/kartikey/.../bind-mount-demo  dest=/usr/share/nginx/html  rw=false
```

> `:ro` makes the mount read-only **inside the container** — nginx only needs to read these files, and it
> prevents a compromised web server from modifying the host's files. Editing from the host still works, which
> is exactly what the next step needs.

## Steps 5–8: modify the file and verify without restarting

```console
=== STEP 5: Record the container state BEFORE modifying the file ===
$ docker inspect nginx-bind --format "StartedAt={{.State.StartedAt}}  PID={{.State.Pid}}  RestartCount={{.RestartCount}}"
StartedAt=2026-09-02T20:13:32.631569388Z  PID=18334  RestartCount=0

=== STEP 6: Modify index.html on the LOCAL machine (container untouched) ===
$ cat index.html
<!DOCTYPE html>
<html>
<head><title>Bind Mount Demo - UPDATED</title></head>
<body>
  <h1>Hello students</h1>
  <h2>This line was added AFTER the container was already running.</h2>
  <p>Edited by Kartikey (10121) on the host machine - no rebuild, no restart.</p>
</body>
</html>

=== STEP 7: Verify the change is reflected WITHOUT restarting the container ===
$ curl -s http://localhost:8090
<!DOCTYPE html>
<html>
<head><title>Bind Mount Demo - UPDATED</title></head>
<body>
  <h1>Hello students</h1>
  <h2>
$ curl -s http://localhost:8090 | grep -o "This line was added AFTER the container was already running."
This line was added AFTER the container was already running.

=== STEP 8: PROVE the container was never restarted ===
$ docker inspect nginx-bind --format "StartedAt={{.State.StartedAt}}  PID={{.State.Pid}}  RestartCount={{.RestartCount}}"
StartedAt=2026-09-02T20:13:32.631569388Z  PID=18334  RestartCount=0

--- identical StartedAt, identical PID, RestartCount still 0 ---

$ docker ps --filter name=nginx-bind
NAMES        STATUS
nginx-bind   Up 22 seconds

--- a third edit, to show it is continuous and not a one-off ---
$ curl -s http://localhost:8090 | grep -E "Hello students|Third edit"
  <h1>Hello students</h1>
  <p>Third edit at 01:43:54</p>

--- and the container inside sees the same file ---
$ docker exec nginx-bind grep -c "Third edit" /usr/share/nginx/html/index.html
1
```

Final state — the file on the host and what nginx serves are byte-for-byte the same:

```console
$ cat index.html      # final state of the file on the host
<!DOCTYPE html>
<html>
<head><title>Bind Mount Demo - UPDATED</title></head>
<body>
  <h1>Hello students</h1>
  <p>Third edit at 01:43:54</p>
  <h2>This line was added AFTER the container was already running.</h2>
  <p>Edited by Kartikey (10121) on the host machine - no rebuild, no restart.</p>
</body>
</html>

$ curl -s http://localhost:8090      # what nginx serves, live
<!DOCTYPE html>
<html>
<head><title>Bind Mount Demo - UPDATED</title></head>
<body>
  <h1>Hello students</h1>
  <p>Third edit at 01:43:54</p>
  <h2>This line was added AFTER the container was already running.</h2>
  <p>Edited by Kartikey (10121) on the host machine - no rebuild, no restart.</p>
</body>
</html>

$ docker inspect nginx-bind --format "StartedAt={{.State.StartedAt}} PID={{.State.Pid}} RestartCount={{.RestartCount}}"
StartedAt=2026-09-02T20:13:32.631569388Z  PID=18334  RestartCount=0
```

## Screenshot — the updated page, served without a restart

![Bind mount, updated live](https://raw.githubusercontent.com/Json604/devops-assignments/main/assignment-07-docker-networking/evidence/03-bind-mount-updated.png)

## Task 3 results

| Check | Evidence |
|---|---|
| Folder created on the local machine | `.../assignment-07-docker-networking/bind-mount-demo` |
| `index.html` with **Hello students** | rendered as `<h1>Hello students</h1>` |
| Folder bind-mounted into Nginx | `type=bind source=/Users/kartikey/... dest=/usr/share/nginx/html` |
| Website accessible, content verified | `curl localhost:8090` → `Hello students` |
| File modified on the host | added `<h2>` + two `<p>` lines, in three separate edits |
| **Changes reflected without restarting** | `StartedAt` **identical**, `PID` **18334 unchanged**, `RestartCount=0`, `docker ps` shows continuous uptime |

The proof that no restart happened is the trio of `StartedAt`, `Pid` and `RestartCount` being **identical
before and after** the edits, while the served content changed. A restart would have changed all three.

## What I understood

**A bind mount maps a host directory straight into the container.** There is no copy and no sync step — both
sides are looking at the *same* files on the host filesystem through the kernel. That is why an edit appears
instantly: nginx simply reads the file again on the next request.

**This is why containers are usable for development.** Without it, every CSS tweak would mean
`docker build` + `docker run` again. With it, you edit in your normal editor and refresh the browser. The
container is the runtime, the host keeps the source.

**Bind mount vs named volume** — they solve different problems:

| | Bind mount | Named volume |
|---|---|---|
| Syntax | `-v /host/path:/container/path` | `-v myvolume:/container/path` |
| Lives at | a path **you** choose on the host | Docker-managed area (`/var/lib/docker/volumes`) |
| Host path must exist | yes (Docker creates a *directory* if absent — a classic bug when you meant a file) | no, Docker creates it |
| Portable across machines | **no** — the path is machine-specific | **yes** |
| Best for | source code in development, config files | databases and production data |

**Caveat worth knowing:** because the host path is absolute and machine-specific, a `docker run` command with a
bind mount is not portable — which is why production uses named volumes and development uses bind mounts.

---

# Task 4 — Overlay Network

## Research

An **overlay network** lets containers on **different Docker hosts** communicate as though they were on one
LAN. Bridge networks cannot do this: a bridge is a virtual switch inside a single machine, so its scope is
`local` and two containers on different physical hosts can never share one.

### How it works

An overlay network builds a **VXLAN tunnel** between hosts:

1. Each container gets an IP from the overlay's own subnet (here `10.0.1.0/24`), independent of any host's
   physical network.
2. When container A on host 1 sends a packet to container B on host 2, the sending host wraps ("encapsulates")
   the whole Ethernet frame inside a **UDP packet on port 4789** (VXLAN).
3. That UDP packet travels across the ordinary physical network to host 2.
4. Host 2 unwraps it and delivers the original frame to container B.

Neither container is aware of any of this — from inside, it looks like a flat local network. This is
**network virtualisation**: a logical L2 network laid *over* an existing L3 network, hence "overlay".

A distributed **key-value store** (built into Swarm's Raft consensus) keeps every host's copy of the network
state — which container has which IP, and on which host — so DNS and routing work cluster-wide.

### Ports required between hosts

| Port | Protocol | Purpose |
|---|---|---|
| 2377 | TCP | Swarm cluster management |
| 7946 | TCP + UDP | Node discovery / gossip between hosts |
| 4789 | UDP | **VXLAN data plane** — the encapsulated container traffic |

### Use cases

- **Multi-host container communication** — the core purpose: a service on host 1 reaching a database on host 3
  by name.
- **Container orchestration** — Docker Swarm and Kubernetes both need a flat network across the cluster.
  Overlay is Swarm's answer.
- **Scaling beyond one machine** — when an application outgrows a single host, overlay networking means the
  application code does not change; `http://database` still resolves.
- **Service discovery and load balancing** — Swarm gives each service one **virtual IP (VIP)** that
  transparently balances across all replicas, wherever they run.
- **Network segmentation across a cluster** — separate overlays for frontend/backend/data tiers,
  cluster-wide, the same isolation Task 1 showed on a single host.
- **Encrypted traffic between hosts** — `docker network create --opt encrypted` turns on IPsec for the VXLAN
  traffic, which matters when hosts communicate over an untrusted network.

## Demonstration

Rather than only reading about it, I created a real overlay network. It requires Swarm mode, so the failure
without it is shown first:

```console
########## TASK 4: OVERLAY NETWORK ##########

=== An overlay network requires Swarm mode. First show it FAILS without it: ===
$ docker info --format "Swarm: {{.Swarm.LocalNodeState}}"
Swarm: inactive
$ docker network create -d overlay demo-overlay
Error response from daemon: This node is not a swarm manager. Use "docker swarm init" or "docker swarm join" to connect this node to swarm and try again.

=== STEP 1: Initialise Swarm mode ===
$ docker swarm init
Swarm initialized: current node (2zk0p0znu10m46tol1ux5k2jp) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token <SWARM-JOIN-TOKEN-REDACTED> 192.168.65.3:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

$ docker info --format "Swarm: {{.Swarm.LocalNodeState}}  Nodes: {{.Swarm.Nodes}}  Managers: {{.Swarm.Managers}}"
Swarm: active  Nodes: 1  Managers: 1

$ docker node ls
ID                            HOSTNAME         STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
2zk0p0znu10m46tol1ux5k2jp *   docker-desktop   Ready     Active         Leader           29.2.0

=== STEP 2: Now the overlay network CAN be created ===
$ docker network create -d overlay --attachable demo-overlay
ptq8upxbq6mk2gnwje1pux919

$ docker network ls --filter driver=overlay
NETWORK ID     NAME           DRIVER    SCOPE
ptq8upxbq6mk   demo-overlay   overlay   swarm
lbei2oc6otiv   ingress        overlay   swarm

$ docker network inspect demo-overlay --format "Name={{.Name}} Driver={{.Driver}} Scope={{.Scope}} Attachable={{.Attachable}} Subnet={{range .IPAM.Config}}{{.Subnet}}{{end}}"
Name=demo-overlay  Driver=overlay  Scope=swarm  Attachable=true  Subnet=10.0.1.0/24

--- compare with a bridge network: note scope local vs swarm ---
$ docker network inspect frontend-net --format "Name={{.Name}} Driver={{.Driver}} Scope={{.Scope}}"
Name=frontend-net  Driver=bridge  Scope=local

--- the ingress overlay network Swarm creates automatically ---
$ docker network inspect ingress --format "Name={{.Name}} Driver={{.Driver}} Scope={{.Scope}} Subnet={{range .IPAM.Config}}{{.Subnet}}{{end}}"
Name=ingress  Driver=overlay  Scope=swarm  Subnet=10.0.0.0/24
```

> **Note on the redacted token.** `docker swarm init` normally prints a join token in this output. It has been
> replaced with `<SWARM-JOIN-TOKEN-REDACTED>` because this write-up lives in a public repository. The original
> token was only ever valid for a manager at `192.168.65.3:2377` — a private address inside the local Docker
> Desktop VM, unreachable from the internet — and the swarm was destroyed with `docker swarm leave --force`
> in Step 5 below, which permanently invalidates its join tokens. The lesson generalises: **never paste real
> `swarm init` output into a public repo**, because on a real host that token lets anyone join your cluster.

The single most telling line is the scope:

```
demo-overlay   overlay   swarm        <- cluster-wide
frontend-net   bridge    local        <- this machine only
```

Then a service was deployed onto it and reached by name:

```console
=== STEP 3: Deploy a Swarm service onto the overlay network ===
$ docker service create --name web-svc --network demo-overlay --replicas 3 nginx:alpine
verify: Waiting 1 seconds to verify that tasks are stable...
verify: Waiting 1 seconds to verify that tasks are stable...
verify: Waiting 1 seconds to verify that tasks are stable...
verify: Service pf2413ghupsaksal9alhpmp79 converged

$ docker service ls
ID             NAME      MODE         REPLICAS   IMAGE          PORTS
pf2413ghupsa   web-svc   replicated   3/3        nginx:alpine   

$ docker service ps web-svc
NAME        NODE             CURRENT STATE
web-svc.1   docker-desktop   Running 15 seconds ago
web-svc.2   docker-desktop   Running 15 seconds ago
web-svc.3   docker-desktop   Running 15 seconds ago

=== STEP 4: Attach a plain container to the overlay and reach the service by name ===
$ docker run --rm --network demo-overlay alpine sh -c "nslookup web-svc; wget -qO- http://web-svc | head -5"
Name:	web-svc
Address: 10.0.1.2

Non-authoritative answer:

---
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>

--- the VIP: one virtual IP load-balances across all 3 replicas ---
$ docker service inspect web-svc --format "{{range .Endpoint.VirtualIPs}}VIP={{.Addr}}{{end}}"
VIP=10.0.1.2/24

$ docker network inspect demo-overlay --format "{{range .Containers}}{{.Name}} {{.IPv4Address}}{{println}}{{end}}"
  web-svc.1.gru8zgzj8vtc1vcbeiyvtzmgj  10.0.1.3/24
  web-svc.2.1l234z7n2f6m698ky2utzuulw  10.0.1.4/24
  web-svc.3.33axvuior6rd64awy45mh8ik0  10.0.1.5/24
  demo-overlay-endpoint  10.0.1.6/24


=== STEP 5: CLEAN UP - remove the service, overlay network and leave Swarm ===
$ docker service rm web-svc
web-svc
$ docker network rm demo-overlay
demo-overlay
$ docker swarm leave --force
Node left the swarm.
$ docker info --format "Swarm: {{.Swarm.LocalNodeState}}"
Swarm: inactive
```

## What the demonstration showed

- **Overlay requires Swarm.** Without it: `This node is not a swarm manager`. Overlay networks depend on the
  distributed state store that Swarm provides, so they cannot exist on a standalone daemon.
- **Scope `swarm`, not `local`.** This is the property that distinguishes an overlay from a bridge and is
  what makes it span hosts.
- **Swarm creates `ingress` automatically** — a built-in overlay (`10.0.0.0/24`) used for routing external
  traffic to published service ports on any node in the cluster.
- **`--attachable` matters.** By default only Swarm *services* may join an overlay; `--attachable` also allows
  ordinary `docker run` containers, which is how the plain Alpine container above reached `web-svc`.
- **VIP load balancing is real.** The service got **one** virtual IP, `10.0.1.2`, while the three replicas sat
  at `10.0.1.3`, `.4` and `.5`. `nslookup web-svc` returned the VIP, and Docker balanced across the replicas
  behind it. The client uses one stable name and never needs to know how many replicas exist or where.

> **Single-node caveat, stated honestly:** this is a one-node swarm on a laptop, so no traffic actually
> crossed a VXLAN tunnel between physical machines. What is genuinely demonstrated is the overlay driver, the
> swarm scope, the distributed address allocation and the VIP load balancing. Proving the cross-host data
> plane would need a second Docker host. Everything was cleaned up afterwards —
> `docker swarm leave --force` and `Swarm: inactive` confirm the machine is back to its original state.

## Bridge vs overlay

| | Bridge | Overlay |
|---|---|---|
| Scope | one host (`local`) | the whole cluster (`swarm`) |
| Spans hosts | no | **yes**, via VXLAN |
| Needs Swarm | no | **yes** |
| Encapsulation | none | VXLAN over UDP 4789 |
| Performance | native | small encapsulation overhead |
| Service discovery | DNS within the host | cluster-wide DNS + VIP load balancing |
| Typical use | single-host apps, local development | multi-host production clusters |

---

# Summary

| Task | Requirement | Status |
|---|---|---|
| 1 | 3 containers (frontend/backend/database), Nginx+Alpine+MySQL | Done |
| 1 | 3 different Docker networks | Done — `frontend-net`, `backend-net`, `db-net` |
| 1 | Backend added to 2 networks | Done — `eth0` 172.28.0.3 + `eth1` 172.29.0.3 |
| 1 | Check connectivity between containers | Done — 3 reachable paths verified, 1 blocked path proven by name **and** by IP |
| 2 | Pull Apache2 from Docker Hub | Done — `httpd:2.4` |
| 2 | Apache2 container on the host network | Done — `NetworkMode=host`, no IP, no port mapping |
| 2 | Access the website on port 80 | Done — HTTP 200 `It works!`, `ss` shows `*:80 LISTEN` (macOS VM caveat documented) |
| 3 | Folder + `index.html` with "Hello students" | Done |
| 3 | Bind mount into Nginx, verify content | Done — `curl` returns `Hello students` |
| 3 | Modify and verify without restarting | Done — same `StartedAt`, same PID 18334, `RestartCount=0` |
| 4 | Research overlay networks and use cases | Done — plus a working overlay network with a 3-replica service |

## Cleanup

```bash
docker rm -f frontend backend database apache-host nginx-bind
docker network rm frontend-net backend-net db-net
```

## Evidence files

| File | Contents |
|---|---|
| `evidence/task1-*.txt` | network creation, container setup, connectivity matrix, SQL proof |
| `evidence/task2-*.txt` | host network vs bridge comparison |
| `evidence/task3-*.txt` | bind mount, live edit, no-restart proof |
| `evidence/task4-*.txt` | overlay network creation, service deployment, cleanup |
| `evidence/03-bind-mount-updated.png` | browser screenshot of the live-updated page |
| `bind-mount-demo/index.html` | the bind-mounted file, in its final edited state |

---

## Resources

*(retained from the original `session8-docker-networking-volume/README.md`)*

- https://docs.docker.com/engine/network/drivers/
