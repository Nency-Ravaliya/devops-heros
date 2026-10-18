# Session 8: Docker networking and volumes

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

`compose.yaml` connects frontend and backend on `front`, and backend and MySQL
on `data`. Create a third unused network, `student8-spare`, for inspection.
The backend joins two networks. Docker's internal DNS resolves service names on
shared user-defined networks; the frontend should not resolve `database`.
Wait for MySQL startup before running the TCP check again if it is not ready yet.
`docker network inspect student8_front` shows network membership.

The bind-mount exercise below serves `site/index.html`, edits it, and requests it again
without restarting Nginx. The named MySQL volume survives `compose down`.
To discard that exercise's database deliberately, run `docker compose -p student8 down -v`.

Host networking (Linux, requires host port 80 to be free):

```bash
docker pull httpd:2.4-alpine
docker run --rm -d --name student8-host --network host httpd:2.4-alpine
curl http://127.0.0.1:80
docker stop student8-host
```

The official Apache image is `httpd`. Host mode shares the host network namespace,
so there is no `-p` translation. Do not run this on a host already serving port 80.

An overlay network connects containers across Docker hosts, normally through Swarm.
Swarm manages membership and VXLAN carries overlay traffic over the underlying network.
Managers need TCP 2377; discovery uses TCP/UDP 7946 and overlay traffic UDP 4789
between trusted nodes. `--opt encrypted` enables data-plane encryption at a cost.
An example is `docker network create --driver overlay --attachable app-overlay`
after Swarm setup. This exercise does not change the host's Swarm configuration.

Container networking commands:

```bash
docker network create student8-spare
docker compose -p student8 up -d
docker network inspect student8_front student8_data student8-spare
docker compose -p student8 exec backend wget -qO- http://frontend
docker compose -p student8 exec -T backend sh -c 'nc -w 5 database 3306 </dev/null'
docker compose -p student8 exec frontend nslookup database
# The final lookup should fail because the two services share no network.
```

Bind mount (run from this session directory):

```bash
docker run -d --rm --name student8-bind -p 127.0.0.1:18080:80 --mount "type=bind,src=$PWD/site,dst=/usr/share/nginx/html,readonly" nginx:stable-alpine
curl http://127.0.0.1:18080
echo '<h1>Hello students - edited without restart</h1>' > site/index.html
curl http://127.0.0.1:18080
docker stop student8-bind
docker compose -p student8 down
docker network rm student8-spare
```

## Verification

Compose configuration parsed. Bind-mount changes appeared without restart, and Apache responded through host networking on port 80.

The three-network/MySQL demonstration remains pending because the MySQL image download failed during DNS resolution.
