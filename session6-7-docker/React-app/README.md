# React Hello World Docker App

## Build Image
```bash
docker build -t react-hello-world .
```

## Run Container
```bash
docker run -d -p 8082:80 --name react-container react-hello-world
```

## Verify
Access `http://localhost:8082` in your browser or run:
```bash
curl http://localhost:8082
```
