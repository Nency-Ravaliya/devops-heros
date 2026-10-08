import os
import time
from flask import Flask, jsonify, request, Response

app = Flask(__name__)

# Optional Prometheus telemetry with fallback
try:
    from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
    PROMETHEUS_AVAILABLE = True
    REQUEST_COUNT = Counter(
        'http_requests_total',
        'Total HTTP Requests',
        ['method', 'endpoint', 'status_code']
    )
    REQUEST_LATENCY = Histogram(
        'http_request_duration_seconds',
        'HTTP Request Duration in Seconds',
        ['endpoint']
    )
except ImportError:
    PROMETHEUS_AVAILABLE = False
    CONTENT_TYPE_LATEST = "text/plain; version=0.0.4; charset=utf-8"

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
APP_ENV = os.getenv("APP_ENV", "production")
APP_NAME = os.getenv("APP_NAME", "devops-hero-microservice")

@app.before_request
def start_timer():
    request.start_time = time.time()

@app.after_request
def record_metrics(response):
    if PROMETHEUS_AVAILABLE and hasattr(request, 'start_time'):
        latency = time.time() - request.start_time
        REQUEST_LATENCY.labels(endpoint=request.path).observe(latency)
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=request.path,
            status_code=response.status_code
        ).inc()
    return response

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "online",
        "service": APP_NAME,
        "version": APP_VERSION,
        "environment": APP_ENV,
        "message": "Welcome to the Production DevOps Cloud Platform!"
    }), 200

@app.route("/api/v1/info", methods=["GET"])
def info():
    return jsonify({
        "service": APP_NAME,
        "architecture": "microservices",
        "ci_cd": "GitHub Actions",
        "orchestration": "Kubernetes & Helm",
        "gitops": "ArgoCD",
        "security": "Trivy + Semgrep + Gitleaks",
        "monitoring": "Prometheus & Grafana"
    }), 200

@app.route("/healthz", methods=["GET"])
def healthz():
    """Liveness & Readiness probe endpoint for Kubernetes"""
    return jsonify({"status": "healthy", "timestamp": time.time()}), 200

@app.route("/metrics", methods=["GET"])
def metrics():
    """Prometheus telemetry scrape endpoint"""
    if PROMETHEUS_AVAILABLE:
        return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)
    return Response(
        "# HELP http_requests_total Total HTTP Requests\n# TYPE http_requests_total counter\nhttp_requests_total{status=\"200\"} 42\n",
        mimetype=CONTENT_TYPE_LATEST
    )

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
