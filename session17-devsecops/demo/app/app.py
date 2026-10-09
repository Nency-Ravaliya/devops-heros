from flask import Flask, jsonify, request, render_template
import platform
import datetime
import sys
import os
import random
import math

app = Flask(__name__)

# --- In-memory storage for demo ---
_request_count = 0
_start_time = datetime.datetime.utcnow()


def _increment_requests():
    global _request_count
    _request_count += 1


# ─────────────────────────────────────────────────────────
#  Pages
# ─────────────────────────────────────────────────────────

@app.route("/")
def home():
    _increment_requests()
    return render_template("index.html")


# ─────────────────────────────────────────────────────────
#  Health & Status API
# ─────────────────────────────────────────────────────────

@app.route("/health")
def health():
    _increment_requests()
    uptime_seconds = (datetime.datetime.utcnow() - _start_time).total_seconds()
    return jsonify({
        "status": "healthy",
        "uptime_seconds": round(uptime_seconds, 2),
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    })


@app.route("/api/status")
def status():
    _increment_requests()
    uptime = datetime.datetime.utcnow() - _start_time
    hours, remainder = divmod(int(uptime.total_seconds()), 3600)
    minutes, seconds = divmod(remainder, 60)
    return jsonify({
        "app": "DevSecOps Dashboard",
        "version": "2.0.0",
        "status": "running",
        "python_version": sys.version.split()[0],
        "platform": platform.system(),
        "uptime": f"{hours:02d}h {minutes:02d}m {seconds:02d}s",
        "total_requests": _request_count,
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    })


# ─────────────────────────────────────────────────────────
#  Greeting API
# ─────────────────────────────────────────────────────────

@app.route("/api/greet/<name>")
def greet(name):
    _increment_requests()
    greetings = [
        f"Hello, {name}! 👋",
        f"Hey {name}, welcome aboard! 🚀",
        f"Greetings, {name}! You rock! 🌟",
        f"What's up, {name}! Happy coding! 💻",
        f"Hi {name}! May your pipelines always pass! ✅",
    ]
    return jsonify({
        "message": random.choice(greetings),
        "name": name,
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    })


# ─────────────────────────────────────────────────────────
#  Math API
# ─────────────────────────────────────────────────────────

@app.route("/api/add", methods=["POST"])
def add_numbers():
    _increment_requests()
    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON body provided"}), 400

    number1 = data.get("number1")
    number2 = data.get("number2")

    if number1 is None or number2 is None:
        return jsonify({"error": "Both number1 and number2 are required"}), 400

    try:
        n1, n2 = float(number1), float(number2)
    except (TypeError, ValueError):
        return jsonify({"error": "Values must be numbers"}), 400

    return jsonify({
        "number1": n1,
        "number2": n2,
        "operation": "addition",
        "result": n1 + n2,
    })


@app.route("/api/calculate", methods=["POST"])
def calculate():
    """Multi-operation calculator."""
    _increment_requests()
    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON body provided"}), 400

    a = data.get("a")
    b = data.get("b")
    op = data.get("operation", "add")

    if a is None or b is None:
        return jsonify({"error": "Fields 'a' and 'b' are required"}), 400

    try:
        a, b = float(a), float(b)
    except (TypeError, ValueError):
        return jsonify({"error": "Values must be numbers"}), 400

    ops = {
        "add":      (a + b,        "+"),
        "subtract": (a - b,        "-"),
        "multiply": (a * b,        "×"),
        "divide":   (a / b if b != 0 else None, "÷"),
        "power":    (a ** b,       "^"),
        "modulo":   (a % b if b != 0 else None, "%"),
    }

    if op not in ops:
        return jsonify({"error": f"Unknown operation '{op}'. Valid: {list(ops.keys())}"}), 400

    result, symbol = ops[op]
    if result is None:
        return jsonify({"error": "Division by zero"}), 400

    return jsonify({
        "a": a, "b": b,
        "operation": op,
        "symbol": symbol,
        "result": round(result, 10),
        "expression": f"{a} {symbol} {b} = {round(result, 10)}",
    })


# ─────────────────────────────────────────────────────────
#  Pipeline Simulator API
# ─────────────────────────────────────────────────────────

PIPELINE_STAGES = [
    {"name": "Code Checkout",      "icon": "📦"},
    {"name": "Install Deps",       "icon": "📥"},
    {"name": "Lint & Format",      "icon": "🔍"},
    {"name": "Unit Tests",         "icon": "🧪"},
    {"name": "Security Scan",      "icon": "🔒"},
    {"name": "Build Docker Image", "icon": "🐳"},
    {"name": "Push to Registry",   "icon": "📤"},
    {"name": "Deploy to K8s",      "icon": "☸️"},
]


@app.route("/api/pipeline/run", methods=["POST"])
def run_pipeline():
    """Simulates a CI/CD pipeline run."""
    _increment_requests()
    data = request.get_json() or {}
    branch = data.get("branch", "main")
    fail_chance = data.get("fail_chance", 0.1)   # 0–1 probability

    stages = []
    failed = False
    for stage in PIPELINE_STAGES:
        if failed:
            status = "skipped"
            duration = 0
        elif random.random() < float(fail_chance):
            status = "failed"
            duration = round(random.uniform(0.5, 5.0), 2)
            failed = True
        else:
            status = "passed"
            duration = round(random.uniform(0.5, 15.0), 2)

        stages.append({
            "name": stage["name"],
            "icon": stage["icon"],
            "status": status,
            "duration_s": duration,
        })

    overall = "failed" if failed else "passed"
    total_time = round(sum(s["duration_s"] for s in stages), 2)
    run_id = f"run-{random.randint(1000, 9999)}"

    return jsonify({
        "run_id": run_id,
        "branch": branch,
        "overall_status": overall,
        "total_time_s": total_time,
        "stages": stages,
        "triggered_at": datetime.datetime.utcnow().isoformat() + "Z",
    })


# ─────────────────────────────────────────────────────────
#  Error handlers
# ─────────────────────────────────────────────────────────

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Route not found", "code": 404}), 404


@app.errorhandler(500)
def server_error(e):
    return jsonify({"error": "Internal server error", "code": 500}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)