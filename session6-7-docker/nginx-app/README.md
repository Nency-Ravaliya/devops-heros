# Nginx Hello World Docker App

## Build Image
```bash
docker build -t nginx-hello-world .
```

## Run Container
```bash
docker run -d -p 8083:80 --name nginx-container nginx-hello-world
```

## Verify
Access `http://localhost:8083` in your browser or run:
```bash
curl http://localhost:8083
```
