# Apache Hello World Docker App

## Build Image
```bash
docker build -t apache-hello-world .
```

## Run Container
```bash
docker run -d -p 8081:80 --name apache-container apache-hello-world
```

## Verify
Access `http://localhost:8081` in your browser or run:
```bash
curl http://localhost:8081
```
