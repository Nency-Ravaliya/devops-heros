from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello_world():
    return """<!DOCTYPE html>
<html>
  <head><title>Python Hello World</title></head>
  <body style="font-family: sans-serif; text-align: center; padding-top: 4rem;">
    <h1>Hello World</h1>
    <p>Served by Python + Flask inside Docker</p>
  </body>
</html>"""


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
