# Node.js Hello World Docker App

## Build Image
```bash
docker build -t nodejs-hello-world .
```

## Run Container
```bash
docker run -d -p 3000:3000 --name nodejs-container nodejs-hello-world
```

## Verify
Access `http://localhost:3000` in your web browser or run:
```bash
curl http://localhost:3000
```
