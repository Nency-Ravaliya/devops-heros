from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <h1>Hello World from Python + Docker!</h1>
    <h3>Name: Sakshi</h3>
    <h3>Roll No: 24bcs10034</h3>
    """

app.run(host="0.0.0.0", port=5000)