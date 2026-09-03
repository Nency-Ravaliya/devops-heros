# Session 8 - Docker Network & Volumes Assignment

All commands below were actually run with a local Docker Engine; full transcripts are in each task
folder.

## Task 1: Docker Container Networking (3 containers, 3 networks)

Full transcript: [`task1-container-networking/`](task1-container-networking/)

- Created 3 networks: `net-frontend`, `net-backend`, `net-database` (`docker network create ...`).
- Created 3 containers:
  - `net-frontend-c` - `nginx:alpine` - on `net-frontend`
  - `net-backend-c` - `nginx:alpine` - on **2 networks**: `net-frontend` + `net-database` (connected to
    the 2nd via `docker network connect net-database net-backend-c`)
  - `net-database-c` - `mysql:8.0` - on `net-database`

  `net-backend` (the 3rd network created) is left unattached to any container here - it satisfies the
  "create 3 networks" requirement and represents a network a real backend tier could use for a
  cache/queue sidecar; the backend container itself only needs to straddle 2 networks
  (`net-frontend` + `net-database`) to act as the bridge between the frontend and database tiers.

- **Connectivity check** (`docker exec <c> ping -c 2 <other-c>`):

  | From → To | Shared network? | Result |
  |---|---|---|
  | frontend → backend | Yes (`net-frontend`) | ✅ 0% packet loss |
  | frontend → database | No | ❌ `ping: bad address 'net-database-c'` (no shared network, no DNS resolution) |
  | backend → frontend | Yes (`net-frontend`) | ✅ 0% packet loss |
  | backend → database | Yes (`net-database`) | ✅ 0% packet loss |

  This demonstrates Docker's user-defined bridge networks: containers get automatic DNS resolution by
  container name **only within networks they share**, and are otherwise fully isolated from each other -
  exactly the 3-tier pattern (frontend ↔ backend ↔ database, frontend never talks to the database
  directly) that connecting a container to multiple networks is used for in practice.

## Task 2: Host Network

Full transcript: [`task2-host-network/`](task2-host-network/)

```bash
docker pull httpd                                    # the "Apache2" image
docker run -d --name apache-host-c --network host httpd
curl http://localhost:80
```

**Result:** `httpd` logs confirm Apache actually started and bound successfully
(`Apache/2.4.68 (Unix) configured -- resuming normal operations`), but `curl http://localhost:80` from the
Mac itself returned connection refused (`curl exit code: 7`).

**Why:** on Docker Desktop for macOS, Docker Engine runs inside a Linux VM. `--network host` attaches the
container to *that VM's* network namespace, not to the Mac's own `localhost` - so "host networking" here
means "host of the VM", not "host of your Mac". This is a well-known Docker Desktop limitation (host
networking only behaves as expected on native Linux hosts, or requires Docker Desktop's separate
"Host Networking" beta feature to bridge the VM boundary). On a real Linux server, the exact same commands
would make Apache immediately reachable at `http://localhost:80`.

## Task 3: Bind Mount

Full transcript: [`task3-bind-mount/`](task3-bind-mount/) · files: [`task3-bind-mount/site/`](task3-bind-mount/site/)

```bash
echo "<h1>Hello students</h1>" > site/index.html
docker run -d --name bindmount-nginx-c -p 8090:80 -v "$(pwd)/site:/usr/share/nginx/html" nginx:alpine
curl http://localhost:8090
# <h1>Hello students</h1>

echo "<h1>Hello students - updated live!</h1>" > site/index.html   # edit on the HOST, container still running
curl http://localhost:8090
# <h1>Hello students - updated live!</h1>
```

`docker ps` confirms the container's `CREATED`/uptime never reset - the content change was picked up
immediately because a bind mount maps the host directory directly into the container's filesystem; nginx
reads the file fresh on every request, no container restart needed.

## Task 4: Overlay Network

Full transcript: [`task4-overlay-network/`](task4-overlay-network/)

Overlay networks let containers on **different Docker hosts** communicate as if they were on the same
network - Docker Swarm (or a similar orchestrator) handles routing traffic between hosts, encapsulating it
over VXLAN. This only really makes sense in a multi-host cluster, which isn't available in this
environment, but the network itself can still be created and inspected on a single-node swarm:

```bash
docker swarm init                              # required - overlay networks need swarm mode
docker network create -d overlay demo-overlay
docker network inspect demo-overlay --format "Driver={{.Driver}} Scope={{.Scope}}"
# Driver=overlay Scope=swarm
```

**Use cases:** multi-host microservice deployments (e.g. a Swarm or Kubernetes cluster spread across
several VMs/machines) where a service on Host A needs to reach a service on Host B by name, without
manually managing routing rules; service discovery and load balancing across nodes; keeping
cross-host traffic encrypted (overlay networks support IPSec encryption between nodes).

**Multi-host mechanics, in short:** each Docker host runs its own network daemon that maintains a
distributed key-value store (Swarm's internal Raft log, or an external store like etcd/Consul for other
orchestrators) tracking which container lives on which node/IP. Traffic between containers on different
hosts is encapsulated in VXLAN packets and sent over the hosts' normal underlay network, then
de-encapsulated on the receiving host and delivered to the target container - so containers see a flat,
single network even though the traffic actually crosses the real network between machines.

(Bridge networks, used in Task 1, are the single-host equivalent - no VXLAN encapsulation needed since
everything is on one machine's kernel.)

---

## Reference

[`Docker network drivers`](https://docs.docker.com/engine/network/drivers/) (bridge, host, overlay, macvlan, none).
