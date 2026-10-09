from flask import Flask

app = Flask(__name__)


@app.get("/")
def hello_world():
    return "<h1>Hello World from Docker Python App!</h1>"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)