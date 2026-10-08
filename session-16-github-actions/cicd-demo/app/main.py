import os

from flask import Flask, jsonify, request

from app.calculator import add, divide, multiply, subtract

OPERATIONS = {"add": add, "subtract": subtract, "multiply": multiply, "divide": divide}

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(
        service="calculator-api",
        version=os.environ.get("APP_VERSION", "dev"),
        environment=os.environ.get("APP_ENV", "local"),
    )


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/calc/<operation>")
def calc(operation):
    if operation not in OPERATIONS:
        return jsonify(error=f"unknown operation '{operation}'"), 404
    try:
        a = float(request.args["a"])
        b = float(request.args["b"])
        result = OPERATIONS[operation](a, b)
    except KeyError:
        return jsonify(error="query parameters 'a' and 'b' are required"), 400
    except ValueError as exc:
        return jsonify(error=str(exc)), 400
    return jsonify(operation=operation, a=a, b=b, result=result)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
