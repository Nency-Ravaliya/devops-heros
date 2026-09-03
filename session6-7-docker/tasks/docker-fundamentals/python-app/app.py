from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello():
    return "<h1>Hello World from Python + Docker!</h1>"


if __name__ == "__main__":
    # 0.0.0.0 binds every interface. Binding 127.0.0.1 would make the app
    # unreachable from outside the container no matter how the port is mapped.
    app.run(host="0.0.0.0", port=8080)
