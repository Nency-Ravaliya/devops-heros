# Docker Multi-Stage Build - Node.js Application

## Overview

This practical demonstrates how to use a multi-stage Dockerfile to build and run a Node.js web application.

The Dockerfile contains two stages:

1. **Builder stage** - Installs the application dependencies and prepares the application files.
2. **Production stage** - Creates a clean runtime image with only the files and dependencies needed to run the application.

The application displays a Hello World webpage with the user's name and roll number.

---

## Application Code

The application uses Node.js's built-in `http` module to create a web server on port `8080`.

```javascript
const http = require("http");

const server = http.createServer((req, res) => {
	res.writeHead(200, { "Content-Type": "text/html" });

	res.end(`
		<h1>Hello World from Docker Multi-Stage Build!</h1>
		<p><strong>Name:</strong> Sakshi</p>
		<p><strong>Roll No:</strong> 24bcs10034</p>
	`);
});

server.listen(8080, () => {
	console.log("Server running on port 8080");
});
```

## Package Configuration

```json
{
	"name": "docker-hello-world",
	"version": "1.0.0",
	"main": "server.js",
	"scripts": {
		"start": "node server.js"
	},
	"dependencies": {
		"express": "^5.1.0"
	}
}
```

The project uses the `npm start` script to launch the server.

---

## Multi-Stage Dockerfile

```dockerfile
# -------------------------
# Stage 1: Build
# -------------------------
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# -------------------------
# Stage 2: Production
# -------------------------
FROM node:24-alpine AS production
WORKDIR /app
COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev
COPY --from=builder /app/server.js ./

EXPOSE 8080

CMD ["npm", "start"]
```

## Explanation of the Stages

### Stage 1: Builder

The builder stage:

- Uses the `node:24-alpine` base image.
- Sets `/app` as the working directory.
- Copies the package files into the image.
- Installs the project dependencies.
- Copies the application source code.

This stage contains everything required during the build process.

### Stage 2: Production

The production stage:

- Starts from a fresh `node:24-alpine` image.
- Copies the package files from the builder stage.
- Installs only production dependencies using `npm install --omit=dev`.
- Copies only `server.js` from the builder stage.
- Exposes port `8080`.
- Starts the application with `npm start`.

Using a separate production stage keeps build-only files out of the final runtime image.

---

## Build the Docker Image

Run the following commands from the `multi-stage-dockerfile` directory:

```bash
docker build -t multi-stage-hello-world .
```

This command builds the image using the final `production` stage.

## Run the Container

The application listens on port `8080` inside the container. Host port `8083` was mapped to it:

```bash
docker run -d --name multi-stage-hello-world -p 8083:8080 multi-stage-hello-world
```

The application was accessed at:

```text
http://localhost:8083
```

![Multi-stage Docker application](screenshots/multi-stage.png)

## Output

The container successfully displayed:

```text
Hello World from Docker Multi-Stage Build!
Name: Sakshi
Roll No: 24bcs10034
```

![Task screenshot](screenshots/task.png)

---

## Docker Concepts Practiced

| Concept | Purpose |
| --- | --- |
| Multi-stage build | Separates build dependencies from runtime files. |
| `FROM ... AS` | Names a Docker build stage. |
| `COPY --from` | Copies files from an earlier stage. |
| `npm install --omit=dev` | Installs production dependencies only. |
| Port mapping | Connects a host port to a container port. |
| Alpine image | Provides a lightweight Linux-based Node.js image. |

## Verification

View the built image with:

```bash
docker images
```

View the running container with:

```bash
docker ps
```

View the container logs with:

```bash
docker logs multi-stage-hello-world
```

## Directory Structure

```text
multi-stage-dockerfile/
├── Dockerfile
├── package.json
├── server.js
├── screenshots/
│   ├── multi-stage.png
│   └── task.png
└── README.md
```

## Result

The Node.js Hello World application was successfully built and run using a multi-stage Dockerfile. The production image contains only the runtime files and dependencies required to serve the application.

## Author

**Sakshi**  
**Roll No: 24BCS10034**
