"""Notes API - the application of the final DevOps project.

Stateless Flask API; notes are stored in Redis (StatefulSet with a PVC in Kubernetes).
Exposes /health (liveness), /ready (readiness: Redis reachable) and /metrics (Prometheus).
"""
import json
import os
import time
import uuid

import redis
from flask import Flask, Response, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

APP_VERSION = os.getenv("APP_VERSION", "dev")
APP_ENV = os.getenv("APP_ENV", "local")
WELCOME = os.getenv("WELCOME_MESSAGE", "Welcome to the Notes API")

REQUESTS = Counter("notes_http_requests_total", "HTTP requests", ["method", "endpoint", "status"])
LATENCY = Histogram("notes_http_request_duration_seconds", "Request latency", ["endpoint"])
NOTES_CREATED = Counter("notes_created_total", "Notes created")


def create_app(redis_client=None):
    app = Flask(__name__)
    store = redis_client or redis.Redis(
        host=os.getenv("REDIS_HOST", "localhost"),
        port=int(os.getenv("REDIS_PORT", "6379")),
        password=os.getenv("REDIS_PASSWORD") or None,
        socket_connect_timeout=2,
        decode_responses=True,
    )

    @app.before_request
    def _start_timer():
        request._start = time.perf_counter()

    @app.after_request
    def _record(resp):
        endpoint = request.url_rule.rule if request.url_rule else "unknown"
        if endpoint != "/metrics":
            REQUESTS.labels(request.method, endpoint, resp.status_code).inc()
            LATENCY.labels(endpoint).observe(time.perf_counter() - request._start)
        return resp

    @app.get("/")
    def index():
        return jsonify(app="notes-api", version=APP_VERSION, environment=APP_ENV, message=WELCOME)

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    @app.get("/ready")
    def ready():
        try:
            store.ping()
        except redis.RedisError as exc:
            return jsonify(status="not ready", reason=str(exc)), 503
        return jsonify(status="ready")

    @app.get("/api/notes")
    def list_notes():
        try:
            notes = [json.loads(v) for v in store.hvals("notes")]
        except redis.RedisError as exc:
            return jsonify(error=f"storage unavailable: {exc}"), 503
        return jsonify(sorted(notes, key=lambda n: n["created"]))

    @app.post("/api/notes")
    def create_note():
        body = request.get_json(silent=True) or {}
        text = str(body.get("text", "")).strip()
        if not text:
            return jsonify(error="field 'text' is required"), 400
        note = {"id": uuid.uuid4().hex[:8], "text": text[:500], "created": time.time()}
        try:
            store.hset("notes", note["id"], json.dumps(note))
        except redis.RedisError as exc:
            return jsonify(error=f"storage unavailable: {exc}"), 503
        NOTES_CREATED.inc()
        return jsonify(note), 201

    @app.get("/api/burn")
    def burn():
        """CPU work to demonstrate the HorizontalPodAutoscaler."""
        n = min(int(request.args.get("n", "200000")), 2_000_000)
        total = sum(i * i for i in range(n))
        return jsonify(result=total % 1000)

    @app.get("/metrics")
    def metrics():
        return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

    return app


app = create_app()

if __name__ == "__main__":
    app.run(host=os.getenv("HOST", "127.0.0.1"), port=int(os.getenv("PORT", "8000")))
