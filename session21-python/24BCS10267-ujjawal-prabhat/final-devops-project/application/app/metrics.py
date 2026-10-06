"""Prometheus metrics exposed on /metrics.

Labels use the *route template* (e.g. /api/items/{item_id}) rather than the raw
URL so that cardinality stays bounded.
"""
from prometheus_client import Counter, Gauge, Histogram, Info

HTTP_REQUESTS = Counter(
    "stockpilot_http_requests_total",
    "Total HTTP requests handled",
    ["method", "route", "status"],
)

HTTP_LATENCY = Histogram(
    "stockpilot_http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "route"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
)

HTTP_IN_PROGRESS = Gauge(
    "stockpilot_http_requests_in_progress",
    "HTTP requests currently being processed",
)

STOCK_ADJUSTMENTS = Counter(
    "stockpilot_stock_adjustments_total",
    "Stock movements recorded",
    ["direction"],
)

LOW_STOCK_ITEMS = Gauge(
    "stockpilot_low_stock_items",
    "Number of SKUs at or below their reorder level (refreshed on each scrape)",
)

BUILD_INFO = Info("stockpilot_build", "Build / runtime information")
