from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 5000

class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        html_content = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Hello World - Python</title>
  <style>
    body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #1e293b; color: #facc15; }
    h1 { font-size: 2.5rem; text-align: center; }
  </style>
</head>
<body>
  <h1>Hello World from Python Docker App!</h1>
</body>
</html>"""
        self.wfile.write(html_content.encode("utf-8"))

def run():
    server_address = ("0.0.0.0", PORT)
    httpd = HTTPServer(server_address, HelloHandler)
    print(f"Python web server running on port {PORT}...")
    httpd.serve_forever()

if __name__ == "__main__":
    run()