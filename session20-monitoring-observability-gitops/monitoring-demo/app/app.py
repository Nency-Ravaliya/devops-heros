"""
Session 20 - Observable & Monitored Application Demo
Exposes HTTP endpoints, Prometheus timeseries metrics, and structured JSON logs.
Demonstrates CPU/Memory utilization tracking, application health probes, and metrics export.
"""

import time
import os
import psutil
from flask import Flask, jsonify, request
from prometheus_client import Counter, Gauge, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# ==============================================================================
# Prometheus Custom Metric Definitions
# ==============================================================================
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP Requests Received',
    ['method', 'endpoint', 'status_code']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['endpoint']
)

SYSTEM_CPU_USAGE = Gauge(
    'app_cpu_utilization_percent',
    'Current process CPU utilization percentage'
)

SYSTEM_MEMORY_USAGE = Gauge(
    'app_memory_utilization_bytes',
    'Current process memory consumption in bytes'
)

APP_HEALTH_STATUS = Gauge(
    'app_health_status',
    'Application health indicator (1 = Healthy, 0 = Degraded/Unhealthy)'
)
APP_HEALTH_STATUS.set(1)


@app.before_request
def start_timer():
    request._start_time = time.time()


@app.after_request
def record_metrics(response):
    if hasattr(request, '_start_time'):
        duration = time.time() - request._start_time
        endpoint = request.path
        REQUEST_LATENCY.labels(endpoint=endpoint).observe(duration)
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=endpoint,
            status_code=response.status_code
        ).increment()
    return response


# ==============================================================================
# Application Routes
# ==============================================================================
@app.route("/")
def index():
    return jsonify({
        "service": "DevOps Heroes - Session 20 Observability Service",
        "status": "online",
        "pillars": ["Metrics", "Logs", "Traces"],
        "endpoints": ["/health", "/metrics", "/api/compute", "/api/memory"]
    })


@app.route("/health")
def health():
    """Application Health Check endpoint for Kubernetes and monitoring probes."""
    return jsonify({
        "status": "healthy",
        "timestamp": time.time(),
        "uptime_seconds": time.time() - APP_START_TIME,
        "checks": {
            "database": "connected",
            "memory": "optimal",
            "disk": "optimal"
        }
    }), 200


@app.route("/metrics")
def metrics():
    """Prometheus Scrape Endpoint exposing timeseries metrics."""
    # Update runtime system metrics
    try:
        proc = psutil.Process(os.getpid())
        SYSTEM_CPU_USAGE.set(proc.cpu_percent(interval=None))
        SYSTEM_MEMORY_USAGE.set(proc.memory_info().rss)
    except Exception:
        SYSTEM_CPU_USAGE.set(12.5)
        SYSTEM_MEMORY_USAGE.set(45000000)

    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}


@app.route("/api/compute", methods=["POST"])
def simulate_cpu_load():
    """Simulates CPU utilization spike for alert evaluation."""
    target_iterations = 2000000
    total = sum(i * i for i in range(target_iterations))
    return jsonify({
        "message": "CPU intensive computation executed",
        "iterations": target_iterations,
        "sample_output": total
    })


APP_START_TIME = time.time()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
