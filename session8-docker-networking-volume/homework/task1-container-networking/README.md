# Task 1: Docker Container Networking

3 containers, 3 networks:

| Container | Image | Networks |
|---|---|---|
| `hw-frontend` | `nginx:alpine` | `net-a` |
| `hw-backend`  | `nginx:alpine` | `net-a`, `net-b` (2 networks) |
| `hw-database` | `mysql:8.0`    | `net-b` |

`net-c` is also created (3rd network) but left unattached — see the comment
in [`docker-compose.yml`](docker-compose.yml).

## Run it
```bash
docker compose up -d
docker network ls
docker network inspect task1-container-networking_net-a
docker network inspect task1-container-networking_net-b
```

## Check connectivity
```bash
# frontend and backend share net-a -> should succeed
docker exec hw-frontend ping -c 3 hw-backend

# backend and database share net-b -> should succeed
docker exec hw-backend ping -c 3 hw-database

# frontend and database do NOT share a network -> should fail / time out
docker exec hw-frontend ping -c 3 hw-database
```

**Expected result:** the first two pings succeed (each pair shares a
network); the third fails, because Docker's user-defined bridge networks
isolate containers that aren't on a common network — `hw-backend` is the
only container that can talk to both `hw-frontend` and `hw-database`.

## Honesty note
Docker isn't installed in the environment this was prepared in, so the
commands above were not actually run — the compose file and expected
results are based on how Docker's bridge networking is documented to work.
Run the commands above to capture the real output for submission.
