"""frontend service - the entry point of the tracing demo.

GET /order?item=<name>  -> calls the `orders` service over HTTP
GET /metrics            -> Prometheus metrics (pillar 1)
GET /healthz            -> liveness

Every request:
  * creates a trace (pillar 3) - the trace context is propagated to `orders`
    automatically via the W3C `traceparent` HTTP header,
  * writes a JSON log line that contains the same trace_id (pillar 2),
  * increments a Prometheus counter / histogram (pillar 1).
"""
import json
import logging
import os
import time

import requests
from flask import Flask, Response, jsonify, request
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

SERVICE = os.getenv("OTEL_SERVICE_NAME", "frontend")
ORDERS_URL = os.getenv("ORDERS_URL", "http://orders:8080")

# ---------------------------------------------------------------- tracing ---
# OTLP/HTTP exporter -> Jaeger :4318 (endpoint from OTEL_EXPORTER_OTLP_ENDPOINT)
provider = TracerProvider(resource=Resource.create({"service.name": SERVICE}))
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(SERVICE)


# ---------------------------------------------------------------- logging ---
class JsonFormatter(logging.Formatter):
    """One JSON object per line, enriched with the current trace/span id."""

    def format(self, record):
        ctx = trace.get_current_span().get_span_context()
        doc = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(record.created)),
            "level": record.levelname,
            "service": SERVICE,
            "msg": record.getMessage(),
            "trace_id": format(ctx.trace_id, "032x") if ctx.is_valid else None,
            "span_id": format(ctx.span_id, "016x") if ctx.is_valid else None,
        }
        doc.update(getattr(record, "extra_fields", {}))
        return json.dumps(doc)


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
log = logging.getLogger(SERVICE)
log.addHandler(handler)
log.setLevel(logging.INFO)
logging.getLogger("werkzeug").setLevel(logging.WARNING)  # hide access-log noise

# ---------------------------------------------------------------- metrics ---
REQS = Counter("frontend_orders_total", "Orders handled by frontend", ["status"])
LAT = Histogram("frontend_order_duration_seconds", "End-to-end /order latency",
                buckets=(0.05, 0.1, 0.25, 0.5, 1, 2.5, 5))

# -------------------------------------------------------------------- app ---
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app, excluded_urls="metrics,health")
RequestsInstrumentor().instrument()


@app.get("/order")
def order():
    item = request.args.get("item", "book")
    start = time.perf_counter()
    with tracer.start_as_current_span("build-order-request") as span:
        span.set_attribute("order.item", item)
        payload = {"item": item, "qty": 1}
    try:
        r = requests.post(f"{ORDERS_URL}/orders", json=payload, timeout=10)
        status = "ok" if r.ok else "error"
        body, code = r.json(), r.status_code
    except requests.RequestException as exc:
        status, body, code = "error", {"error": str(exc)}, 502
    elapsed = time.perf_counter() - start
    REQS.labels(status=status).inc()
    LAT.observe(elapsed)

    trace_id = format(trace.get_current_span().get_span_context().trace_id, "032x")
    extra = {"extra_fields": {"item": item, "status": code,
                              "duration_ms": round(elapsed * 1000, 1)}}
    if status == "ok":
        log.info("order placed", extra=extra)
    else:
        trace.get_current_span().set_status(trace.Status(trace.StatusCode.ERROR))
        log.error("order failed", extra=extra)
    body["trace_id"] = trace_id
    return jsonify(body), code


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
