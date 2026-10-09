"""orders service - called by `frontend`.

POST /orders {"item": "...", "qty": 1}

Inside one request it creates child spans:
  validate-order -> db.query (simulated with sleep) -> compute-price

Behaviour knobs (to make interesting traces):
  item == "slow"   -> db.query sleeps ~1.2s  (latency problem)
  item == "fail"   -> db.query raises         (error)
  ERROR_RATE env   -> random fraction of requests that fail anyway
"""
import json
import logging
import os
import random
import time

from flask import Flask, jsonify, request
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.trace import Status, StatusCode

SERVICE = os.getenv("OTEL_SERVICE_NAME", "orders")
ERROR_RATE = float(os.getenv("ERROR_RATE", "0.1"))

provider = TracerProvider(resource=Resource.create({"service.name": SERVICE}))
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(SERVICE)


class JsonFormatter(logging.Formatter):
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
logging.getLogger("werkzeug").setLevel(logging.WARNING)

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app, excluded_urls="health")


class DBError(Exception):
    pass


def db_query(item):
    """Pretend database call - a CLIENT span with db.* semantic attributes."""
    with tracer.start_as_current_span("db.query", kind=trace.SpanKind.CLIENT) as span:
        span.set_attribute("db.system", "postgresql")
        span.set_attribute("db.statement", "SELECT price FROM products WHERE name = $1")
        span.set_attribute("order.item", item)
        if item == "slow":
            time.sleep(1.2)                      # missing index / lock wait
        else:
            time.sleep(random.uniform(0.02, 0.08))
        if item == "fail" or random.random() < ERROR_RATE:
            err = DBError("connection reset by peer (db-primary:5432)")
            span.record_exception(err)
            span.set_status(Status(StatusCode.ERROR, str(err)))
            raise err
        return 499.0


@app.post("/orders")
def create_order():
    data = request.get_json(force=True)
    item = data.get("item", "book")
    with tracer.start_as_current_span("validate-order") as span:
        span.set_attribute("order.qty", data.get("qty", 1))
        time.sleep(0.005)
    try:
        price = db_query(item)
    except DBError as exc:
        trace.get_current_span().set_status(Status(StatusCode.ERROR, str(exc)))
        log.error("db query failed", extra={"extra_fields": {"item": item, "error": str(exc)}})
        return jsonify({"error": "database unavailable"}), 500
    with tracer.start_as_current_span("compute-price"):
        total = price * data.get("qty", 1)
        time.sleep(0.003)
    log.info("order stored", extra={"extra_fields": {"item": item, "total": total}})
    return jsonify({"item": item, "total": total, "status": "created"}), 201


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
