# Session 8 — Docker networking and volumes

Student: Viraj Bhanage, roll 24BCS10274

Run everything with Docker Desktop open:

```bash
chmod +x run-labs.sh
./run-labs.sh
```

## Task 1 — Three containers, three networks

`docker-compose.yml` creates:

- `hw-frontend` on `hw-frontend-net` only
- `hw-backend` on `hw-frontend-net` and `hw-backend-net`
- `hw-database` (MySQL) on `hw-backend-net` and `hw-db-net`

The backend is the only container on two networks, so it can ping both the frontend and the database. The frontend cannot resolve or ping the database. That is the point of splitting networks: a container only reaches the networks you attach.

The MySQL password in the compose file is `lab-example-only`. It is a local lab value, not a credential for a shared system.

## Task 2 — Host network

```bash
docker run -d --name hw-apache-host --network host httpd:2.4-alpine
```

`--network host` skips the bridge NAT. Apache binds to port 80 on the machine itself. Open `http://localhost`. On Docker Desktop for Mac the host network is the Linux VM network, so if port 80 is not visible on the Mac, publish `-p 80:80` on the default bridge and note that in the screenshot caption.

## Task 3 — Bind mount

`bind-mount/index.html` says **Hello students**. The script mounts that folder onto an Nginx container at `/usr/share/nginx/html` and publishes port `8088`.

Edit the HTML and refresh `http://localhost:8088`. The new text appears without a container restart because Nginx reads the file from the host path on each request.

## Task 4 — Overlay networks

An overlay network is a Swarm (or Kubernetes CNI) network that spans more than one Docker host. Each host has a VXLAN interface. Packets between containers on different machines are encapsulated in UDP and sent to the other host, then delivered to the destination container. Use an overlay when a service on node A must reach a service on node B by container name. A single-host lab uses bridge networks instead. Overlay needs a Swarm manager (`docker swarm init`) and is the model Kubernetes CNI plugins also solve, with different implementations.

These checks were run on this machine:

```text
networks: hw-frontend-net, hw-backend-net, hw-db-net

backend -> database: 2 packets received, 0% packet loss
backend -> frontend: 2 packets received, 0% packet loss
frontend -> database: ping: bad address 'database'

bind mount http://localhost:8088 before edit:
  Hello students
bind mount after editing index.html, container not restarted:
  Edited without a restart.
```

The lab containers were removed after the capture. Run `./run-labs.sh` if you want the same output in a screenshot.
