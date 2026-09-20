# Session 8 - Docker Networking and Volumes

Dhruv Bansal - 24BCS10114

I made a small three-container setup with NGINX, a Python backend, and MySQL.

- The frontend is connected only to `frontend_net`.
- The database is connected only to `backend_net`.
- The backend joins both networks, so it is the only service that can talk to both sides.
- MySQL data is kept in the named volume `db_data`.

## Run it

```bash
docker compose up -d --build
docker compose ps
curl http://localhost:8082
curl http://localhost:8082/api
```

The `/api` response shows `"status": "connected"` after the backend reaches the MySQL database. I used the service name `database` instead of an IP address because Compose provides DNS inside each network.

These commands show the networks and volume:

```bash
docker network ls
docker network inspect dhruv-bansal-24bcs10114_frontend_net
docker network inspect dhruv-bansal-24bcs10114_backend_net
docker volume inspect dhruv-bansal-24bcs10114_db_data
```

The frontend files are bind-mounted, so I can edit the page without rebuilding it. The database volume remains after `docker compose down`; `docker compose down -v` also removes the stored data.

## Clean up

```bash
docker compose down
```
