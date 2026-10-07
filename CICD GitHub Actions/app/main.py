"""Small Flask API in front of the calculator."""
import os

from flask import Flask, jsonify, request

from app.calculator import OPERATIONS

app = Flask(__name__)
APP_VERSION = os.getenv("APP_VERSION", "dev")


@app.get("/")
def index():
    return jsonify(app="session16-calculator", version=APP_VERSION,
                   operations=sorted(OPERATIONS))


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/api/<op>")
def calculate(op):
    if op not in OPERATIONS:
        return jsonify(error=f"unknown operation '{op}'"), 404
    try:
        a = float(request.args["a"])
        b = float(request.args["b"])
    except (KeyError, ValueError):
        return jsonify(error="query params a and b must be numbers"), 400
    try:
        result = OPERATIONS[op](a, b)
    except ValueError as exc:
        return jsonify(error=str(exc)), 400
    return jsonify(operation=op, a=a, b=b, result=result)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
