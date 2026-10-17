# Docker Networking & Volume — Session 8

Hands-on practice with Docker container networking, host network mode, bind mounts, and overlay networks.

## Contents

| File / Folder | Description |
|---|---|
| `docker_networking_volumes.md` | Full walkthrough and research notes for all 4 tasks |
| `docker-compose.yml` | Basic 3-tier compose example (frontend / backend / database) |
| `docker-compose-app/` | Alternate compose file |
| `demo/` | Working 3-tier demo app (Flask backend + MySQL + Nginx frontend) |
| `bind_mount_demo/` | Bind mount demo with `index.html` |
| `Submissions/` | Automation scripts and screenshots for all 4 tasks |

## Tasks

1. **Task 1 — Container Networking:** 3 containers, 3 networks, cross-network isolation
2. **Task 2 — Host Network Mode:** Apache on `--network host`, no port mapping needed
3. **Task 3 — Bind Mount:** Live file editing without container restart
4. **Task 4 — Overlay Networks:** Research report on multi-host networking

## Resources

- https://docs.docker.com/engine/network/drivers/
