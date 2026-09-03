# Task 2: Host Network

Pull the Apache2 image and run it directly on the host's network stack
(no port mapping needed/possible — it shares the host's ports directly):

```bash
docker pull httpd:2.4
docker run -d --name apache-host --network host httpd:2.4
```

Access it directly on port 80:
```bash
curl http://localhost:80/
# or open http://localhost in a browser
```

**Note:** `--network host` only works this way on Linux — on Docker
Desktop for macOS/Windows the Docker VM's "host" isn't literally your
machine's host network, so `localhost` may not map 1:1 the way it does on a
native Linux Docker install. On Linux, the container has no network
isolation from the host at all: no `-p` mapping is needed (or possible) —
whatever port Apache listens on (80) is directly the host's port 80.

## Honesty note
Docker isn't installed in the environment this was prepared in, so this
wasn't actually run — the commands above are exactly what's needed; run
them on a Linux host (or Docker Desktop, with the macOS/Windows caveat
above) to verify and capture output for submission.
