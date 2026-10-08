from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return '''
    <!DOCTYPE html>
    <html>
      <head>
        <title>Python Docker Demo</title>
        <style>
          body { font-family: sans-serif; background: #064e3b; color: #ecfdf5; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
          .card { background: #065f46; padding: 2.5rem; border-radius: 1rem; box-shadow: 0 10px 25px rgba(0,0,0,0.5); text-align: center; border: 1px solid #047857; }
          h1 { color: #34d399; margin-bottom: 0.5rem; }
          p { color: #a7f3d0; font-size: 1.1rem; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>Hello World from Python Flask!</h1>
          <p>Running inside Docker Container</p>
        </div>
      </body>
    </html>
    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
