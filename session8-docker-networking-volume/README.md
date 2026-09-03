Resources:

- https://docs.docker.com/engine/network/drivers/

## Homework — Docker Networking & Volume

| Task | Folder | Summary |
|---|---|---|
| Task 1: Container Networking | [`homework/task1-container-networking/`](homework/task1-container-networking/) | 3 containers, 3 Docker networks, backend joined to 2 of them, connectivity checked with `docker exec ... ping`. |
| Task 2: Host Network | [`homework/task2-host-network/`](homework/task2-host-network/) | Apache2 container run with `--network host`, accessed directly on port 80. |
| Task 3: Bind Mount | [`homework/task3-bind-mount/`](homework/task3-bind-mount/) | Local folder with `index.html` ("Hello students") bind-mounted into Nginx; edits reflect live, no restart needed. |
| Task 4: Overlay Network | [`homework/task4-overlay-network.md`](homework/task4-overlay-network.md) | Research notes on overlay networks and multi-host container communication. |

The pre-existing [`demo/`](demo/) and [`docker-compose-app/`](docker-compose-app/)
folders (3-tier nginx + Flask + MySQL app) were already here from earlier
practice and are left as-is.

### Honesty note
Docker isn't installed on the machine this homework was prepared on
(`command -v docker` finds nothing), so none of the above was actually run —
every compose file, Dockerfile and command was written to be correct and
ready to run as-is. Each task folder's README has the exact commands to
execute; run them locally to capture the real output/screenshots this
homework asks for.
