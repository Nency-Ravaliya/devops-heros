# Node.js Web App

Redeployed for Task 3 of this session, from its own image and container.

## Image

![Node.js app running in the browser](image.png)

## Dockerfile

```dockerfile
FROM node:20

WORKDIR /app

COPY package.json ./
RUN npm install

COPY app.js ./

EXPOSE 8080

CMD ["npm", "start"]
```

## Commands

Build the image from the Dockerfile:

```bash
docker build -t node-webapp-v2 .
```

Run the container and map host port `8080` to container port `8080`:

```bash
docker run -it -d --name node-container -p 8080:8080 node-webapp-v2
```

### Terminal Output

![docker build, docker run, docker ps and curl for the Node.js app](commands.png)
