from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello():
    return """<!DOCTYPE html>
<html>
  <head><title>Python Hello World</title></head>
  <body style="font-family: sans-serif; text-align: center; margin-top: 60px;">
    <h1>Hello World from Python in Docker!</h1>
    <p>Served by Flask + Gunicorn on port 5000</p>
  </body>
</html>"""


if __name__ == "__main__":
    # only used when running the file directly; the container uses gunicorn
    app.run(host="0.0.0.0", port=5000)
