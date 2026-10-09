# Python Web App

Hello World web application built on a Flask app bound to 0.0.0.0 so it is reachable from outside the container.

## Image

![Python container serving Hello World in the browser](image.png)

## Dockerfile

```dockerfile
FROM python:3.12

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./

EXPOSE 8080

CMD ["python", "app.py"]
```

## Commands

Build the image from the Dockerfile:

```bash
docker build -t python-webapp .
```

Run the container and map host port `8080` to container port `8080`:

```bash
docker run -d --name python-container -p 8080:8080 python-webapp
```

### Terminal Output

![docker build, docker run, docker ps and curl for the Python app](commands.png)
