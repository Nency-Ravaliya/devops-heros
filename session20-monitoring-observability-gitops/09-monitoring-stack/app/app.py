"""Tiny demo app for the Session 20 monitoring stack.

Endpoints
  /               hello
  /health         application health (status + uptime)
  /metrics        Prometheus metrics (prometheus_client)
  /work?ms=200    burn CPU for N milliseconds
  /error          always returns HTTP 500
  /memory?mb=50   allocate and hold N MB (simulates a leak)
  /memory/release free everything held by /memory
Every request is logged to stdout as one JSON line.
"""
import json
import logging
import os
import random
import socket
import sys
import time
from datetime import datetime, timezone

from flask import Flask, Response, g, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest

APP_NAME = "demo-app"
VERSION = os.getenv("APP_VERSION", "1.0.0")
START_TIME = time.time()

app = Flask(__name__)
logging.getLogger("werkzeug").setLevel(logging.ERROR)  # we write our own access logs

REQUESTS = Counter("http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"])
LATENCY = Histogram(
    "http_request_duration_seconds", "HTTP request latency", ["endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5),
)
IN_PROGRESS = Gauge("http_requests_in_progress", "Requests currently being served")
UP_SINCE = Gauge("app_start_time_seconds", "Unix time the app started")
HELD_MB = Gauge("app_memory_held_megabytes", "MB intentionally held by /memory")
INFO = Gauge("app_info", "App build info", ["version"])
UP_SINCE.set(START_TIME)
INFO.labels(version=VERSION).set(1)

_held = []  # memory ballast for /memory


def log(level, msg, **fields):
    rec = {"ts": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
           "level": level, "service": APP_NAME, "msg": msg, **fields}
    sys.stdout.write(json.dumps(rec) + "\n")
    sys.stdout.flush()


@app.before_request
def _start():
    g.start = time.perf_counter()
    IN_PROGRESS.inc()


@app.after_request
def _record(resp):
    IN_PROGRESS.dec()
    endpoint = request.url_rule.rule if request.url_rule else "unknown"
    dur = time.perf_counter() - g.start
    if endpoint != "/metrics":  # don't let the scraper dominate the numbers/logs
        REQUESTS.labels(request.method, endpoint, str(resp.status_code)).inc()
        LATENCY.labels(endpoint).observe(dur)
        level = "ERROR" if resp.status_code >= 500 else "WARN" if resp.status_code >= 400 else "INFO"
        log(level, "request", method=request.method, path=request.full_path.rstrip("?"),
            status=resp.status_code, duration_ms=round(dur * 1000, 2),
            client=request.remote_addr)
    return resp


@app.get("/")
def index():
    return jsonify(service=APP_NAME, version=VERSION, host=socket.gethostname(),
                   endpoints=["/health", "/metrics", "/work?ms=200", "/error", "/memory?mb=50"])


@app.get("/health")
def health():
    return jsonify(status="UP", service=APP_NAME, version=VERSION,
                   uptime_seconds=round(time.time() - START_TIME, 1),
                   memory_held_mb=len(_held))


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.get("/work")
def work():
    ms = min(int(request.args.get("ms", 200)), 5000)
    end = time.perf_counter() + ms / 1000
    n = 0
    while time.perf_counter() < end:  # busy loop = real CPU usage
        n += random.random() * random.random()
    return jsonify(burned_ms=ms, iterations=int(n))


@app.get("/error")
def error():
    log("ERROR", "simulated failure", error="database connection refused")
    return jsonify(error="simulated failure"), 500


@app.get("/memory")
def memory():
    mb = min(int(request.args.get("mb", 50)), 300)
    for _ in range(mb):
        _held.append(bytearray(os.urandom(1024 * 1024)))
    HELD_MB.set(len(_held))
    return jsonify(held_mb=len(_held))


@app.get("/memory/release")
def release():
    _held.clear()
    HELD_MB.set(0)
    return jsonify(held_mb=0)


if __name__ == "__main__":
    log("INFO", "starting", version=VERSION, port=8000)
    app.run(host="0.0.0.0", port=8000, threaded=True)
