from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello():
    return "<h1>Hello World from Python (Flask + Gunicorn, multi-stage build)!</h1>"
