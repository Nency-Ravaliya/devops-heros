# Session 8 - Docker Networking and Volumes

Dhruv Bansal - 24BCS10114

The Compose file uses three services. The frontend is on `frontend_net`; the backend connects `frontend_net` and `backend_net`; the MySQL database is only on `backend_net`. The database data is stored in the named `db_data` volume.

```bash
docker compose up -d
docker compose exec backend getent hosts database
curl http://localhost:8082
docker compose down
```

The frontend page is bind-mounted from `frontend/index.html`. Editing that file updates the page without rebuilding the image.
