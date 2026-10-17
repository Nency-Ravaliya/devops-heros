# Java Hello World Docker App

## Build Image
```bash
docker build -t java-hello-world .
```

## Run Container
```bash
docker run -d -p 8080:8080 --name java-container java-hello-world
```

## Verify
Access `http://localhost:8080` in your browser or run:
```bash
curl http://localhost:8080
```
