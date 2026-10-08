# Python Flask Hello World Docker App

## Build Image
```bash
docker build -t python-hello-world .
```

## Run Container
```bash
docker run -d -p 5000:5000 --name python-container python-hello-world
```

## Verify
Access `http://localhost:5000` in your browser or run:
```bash
curl http://localhost:5000
```
