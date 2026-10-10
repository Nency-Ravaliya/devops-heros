"""Prometheus instrumentation without a third-party FastAPI plugin.

A small ASGI-level middleware records, for every request:
  http_requests_total{method,handler,status}            counter
  http_request_duration_seconds{method,handler}         histogram
plus the process/platform collectors prometheus_client registers by default.
The `handler` label is the route template (/api/entries/{entry_id}), not the raw path,
so the label set stays small no matter how many ids exist.
"""
import time

from fastapi import FastAPI, Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

REQUESTS = Counter(
    "http_requests_total", "HTTP requests handled by the API", ["method", "handler", "status"]
)
LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "handler"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
)

EXCLUDED = {"/metrics", "/health", "/ready"}


def install(app: FastAPI) -> None:
    @app.middleware("http")
    async def record_metrics(request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        route = request.scope.get("route")
        handler = getattr(route, "path", request.url.path)
        if handler not in EXCLUDED:
            REQUESTS.labels(request.method, handler, str(response.status_code)).inc()
            LATENCY.labels(request.method, handler).observe(time.perf_counter() - start)
        return response

    @app.get("/metrics", include_in_schema=False)
    def metrics():
        return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
