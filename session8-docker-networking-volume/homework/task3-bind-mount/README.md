# Task 3: Bind Mount

[`html/index.html`](html/index.html) contains "Hello students" and is bind-mounted
straight into an Nginx container (no image rebuild needed to change it).

## Run it
```bash
docker run -d --name bind-mount-demo -p 8081:80 \
  -v "$(pwd)/html:/usr/share/nginx/html" \
  nginx:alpine
```

## Verify
```bash
curl http://localhost:8081/
# should print the "Hello students" page
```

## Modify without restarting the container
```bash
echo '<h1>Hello students - updated!</h1>' > html/index.html
curl http://localhost:8081/
# should immediately show the updated content, no docker restart needed
```
This works because a **bind mount** maps a real host directory straight into
the container's filesystem — the container reads whatever is on disk at
request time, so host-side edits are visible immediately (unlike a `COPY`
in a Dockerfile, which bakes a snapshot into the image at build time).

## Honesty note
Docker isn't installed in the environment this was prepared in, so this
wasn't actually run — the real `index.html` content above is genuine and
ready to bind-mount as-is; run the commands to capture live output/screenshots.
