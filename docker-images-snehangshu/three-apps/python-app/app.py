import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("PORT", 5000))


class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = f"""<!doctype html>
<html>
  <head><title>Python on Docker</title></head>
  <body>
    <h1>Hello World from Python!</h1>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
    <p>Served by Python in container {socket.gethostname()}</p>
  </body>
</html>"""
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(body.encode())

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args))


if __name__ == "__main__":
    print(f"Python app listening on port {PORT}")
    HTTPServer(("0.0.0.0", PORT), HelloHandler).serve_forever()
