from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1 style='font-family: sans-serif; text-align: center; margin-top: 50px;'>Hello World from Python (Flask) & Docker!</h1>"

if __name__ == "__main__":
    # Host 0.0.0.0 is mandatory to allow traffic from outside the container
    app.run(host="0.0.0.0", port=5001)