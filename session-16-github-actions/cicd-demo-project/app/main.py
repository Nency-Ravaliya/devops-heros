"""Calculator REST API served by Flask.

Endpoints
  GET /                         -> service banner
  GET /health                   -> liveness check used by the CD smoke test
  GET /info                     -> build/deploy metadata injected by the pipeline
  GET /calc/<op>?a=<n>&b=<n>    -> op is add | subtract | multiply | divide
"""
import os

from flask import Flask, jsonify, request

from app.calculator import OPERATIONS

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(service="session16-calculator-api", status="running")


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/info")
def info():
    # Values come from Docker build args / container env set by the pipeline.
    # The secret's value is never returned, only whether it was provided.
    return jsonify(
        version=os.getenv("APP_VERSION", "dev"),
        git_sha=os.getenv("GIT_SHA", "local"),
        environment=os.getenv("APP_ENV", "local"),
        secret_configured=bool(os.getenv("APP_SECRET_KEY")),
    )


@app.get("/calc/<op>")
def calc(op):
    if op not in OPERATIONS:
        return jsonify(error=f"Unknown operation '{op}'"), 404
    try:
        a = float(request.args["a"])
        b = float(request.args["b"])
    except (KeyError, ValueError):
        return jsonify(error="Query params 'a' and 'b' must be numbers"), 400
    try:
        result = OPERATIONS[op](a, b)
    except ValueError as e:
        return jsonify(error=str(e)), 400
    return jsonify(operation=op, a=a, b=b, result=result)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
