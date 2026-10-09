import os

from flask import Flask, jsonify, request

from app.calculator import add, divide, multiply, subtract

app = Flask(__name__)

OPERATIONS = {"add": add, "subtract": subtract, "multiply": multiply, "divide": divide}
VERSION = os.getenv("APP_VERSION", "dev")


@app.get("/")
def index():
    return jsonify(app="calculator-api", version=VERSION, operations=sorted(OPERATIONS))


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/calc/<operation>")
def calc(operation):
    func = OPERATIONS.get(operation)
    if func is None:
        return jsonify(error=f"unknown operation '{operation}'"), 404
    try:
        a = float(request.args["a"])
        b = float(request.args["b"])
    except (KeyError, ValueError):
        return jsonify(error="query params 'a' and 'b' must be numbers"), 400
    try:
        return jsonify(operation=operation, a=a, b=b, result=func(a, b))
    except ValueError as exc:
        return jsonify(error=str(exc)), 400


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
