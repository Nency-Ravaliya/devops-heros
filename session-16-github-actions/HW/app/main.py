"""Small Flask API around the calculator so it can run as a container."""
import os

from flask import Flask, jsonify, request

from app.calculator import OPERATIONS

app = Flask(__name__)

APP_VERSION = os.environ.get("APP_VERSION", "dev")


@app.get("/")
def index():
    return jsonify(
        app="session16-calculator",
        version=APP_VERSION,
        operations=sorted(OPERATIONS),
    )


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/api/<operation>")
def calculate(operation):
    func = OPERATIONS.get(operation)
    if func is None:
        return jsonify(error=f"unknown operation '{operation}'"), 404
    try:
        a = float(request.args["a"])
        b = float(request.args["b"])
    except (KeyError, ValueError):
        return jsonify(error="query params 'a' and 'b' must be numbers"), 400
    try:
        result = func(a, b)
    except ValueError as exc:
        return jsonify(error=str(exc)), 400
    return jsonify(operation=operation, a=a, b=b, result=result)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
