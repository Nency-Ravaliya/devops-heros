# Flask DevSecOps Demo

I used this Flask application to exercise the Session 17 pipeline. It provides a dashboard, health and status endpoints, a greeting route, calculator endpoints, and a pipeline simulator.

## Run with Python

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -q
python app/app.py
```

The application listens on `http://localhost:5001`.

```bash
curl -fsS http://localhost:5001/health
curl -fsS http://localhost:5001/api/status
curl -fsS http://localhost:5001/api/greet/Anshal
curl -fsS -X POST http://localhost:5001/api/add \
  -H 'Content-Type: application/json' \
  -d '{"number1":10,"number2":20}'
```

## Run with Docker

```bash
docker build -t session17-devsecops:local .
docker run --rm -p 5001:5001 session17-devsecops:local
```

The Dockerfile installs only the runtime dependency and runs the application as a non-root user.

## Kubernetes

The files in [`k8s/`](k8s/) create a two-replica Deployment and ClusterIP Service. The Deployment has resource limits, readiness, and liveness checks against `/health`.

The repository-level workflow builds this image, scans it, loads it into a temporary Kind cluster, applies both manifests, waits for the rollout, and performs an HTTP health check. See the [Session 17 README](../README.md) for the complete pipeline and security gates.
