"""Session 17 DevSecOps demo API - Antara Utane (24BCS10106).

Small Flask service that is built, tested, scanned (SAST, SCA, secrets,
image) and deployed by the 24BCS10106-session17-devsecops workflow.
"""

import os
import platform
from datetime import datetime, timezone

from flask import Flask, jsonify, request
from markupsafe import escape

app = Flask(__name__)

START_TIME = datetime.now(timezone.utc)
OPERATIONS = {
    "add": lambda a, b: a + b,
    "subtract": lambda a, b: a - b,
    "multiply": lambda a, b: a * b,
    "divide": lambda a, b: a / b,
}


@app.after_request
def security_headers(response):
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Content-Security-Policy"] = "default-src 'none'"
    return response


@app.get("/")
def index():
    return jsonify(
        app="s17-devsecops-demo",
        student="Antara Utane (24BCS10106)",
        version=os.getenv("APP_VERSION", "dev"),
    )


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/api/status")
def status():
    uptime = (datetime.now(timezone.utc) - START_TIME).total_seconds()
    return jsonify(
        status="running",
        python=platform.python_version(),
        uptime_seconds=round(uptime, 2),
    )


@app.get("/api/greet/<name>")
def greet(name):
    # escape() prevents reflected XSS if a client renders the message as HTML
    return jsonify(message=f"Hello, {escape(name)}!")


@app.post("/api/calc")
def calc():
    data = request.get_json(silent=True) or {}
    op = data.get("op")
    if op not in OPERATIONS:
        return jsonify(error=f"op must be one of {sorted(OPERATIONS)}"), 400
    try:
        a, b = float(data["a"]), float(data["b"])
    except (KeyError, TypeError, ValueError):
        return jsonify(error="a and b must be numbers"), 400
    if op == "divide" and b == 0:
        return jsonify(error="division by zero"), 400
    return jsonify(op=op, a=a, b=b, result=OPERATIONS[op](a, b))


@app.errorhandler(404)
def not_found(_):
    return jsonify(error="not found"), 404
