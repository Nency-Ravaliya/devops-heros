"""Small demo application that exposes everything a monitoring stack needs:
metrics (/metrics), health (/healthz) and structured JSON logs on stdout."""
import json
import logging
import sys
import time

from flask import Flask, Response, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest

app = Flask(__name__)

REQUESTS = Counter("app_http_requests_total", "HTTP requests handled", ["path", "status"])
LATENCY = Histogram("app_request_duration_seconds", "Request latency in seconds", ["path"])
HEALTHY = Gauge("app_healthy", "1 when the application considers itself healthy, 0 otherwise")
HEALTHY.set(1)


class JsonFormatter(logging.Formatter):
    def format(self, record):
        return json.dumps(
            {
                "time": self.formatTime(record, "%Y-%m-%dT%H:%M:%S"),
                "level": record.levelname,
                "message": record.getMessage(),
            }
        )


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
log = logging.getLogger("demo")
log.setLevel(logging.INFO)
log.addHandler(handler)


@app.before_request
def start_timer():
    request.start = time.time()


@app.after_request
def record(response):
    if request.path != "/metrics":
        path = request.path
        LATENCY.labels(path).observe(time.time() - request.start)
        REQUESTS.labels(path, str(response.status_code)).inc()
        level = logging.ERROR if response.status_code >= 500 else logging.INFO
        log.log(level, f"{request.method} {path} -> {response.status_code}")
    return response


@app.route("/")
def index():
    return jsonify(message="Hello from the monitoring demo")


@app.route("/work")
def work():
    """Burn CPU for ?ms milliseconds (default 200) to make CPU graphs move."""
    ms = int(request.args.get("ms", 200))
    end = time.time() + ms / 1000
    while time.time() < end:
        pass
    return jsonify(burned_ms=ms)


@app.route("/error")
def error():
    return jsonify(error="simulated failure"), 500


@app.route("/healthz")
def healthz():
    if HEALTHY._value.get() == 1:
        return jsonify(status="ok")
    return jsonify(status="unhealthy"), 503


@app.route("/break")
def break_it():
    HEALTHY.set(0)
    log.error("health check switched to failing")
    return jsonify(status="now unhealthy")


@app.route("/fix")
def fix_it():
    HEALTHY.set(1)
    log.info("health check switched back to ok")
    return jsonify(status="healthy again")


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)
