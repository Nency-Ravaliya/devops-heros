"""Hello World web server using only the Python standard library."""
import platform
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = 5000

PAGE = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Python Hello World</title></head>
<body style="font-family:system-ui;text-align:center;margin-top:15vh">
  <h1>Hello World</h1>
  <p>from <strong>Python {platform.python_version()}</strong> running in a Docker container</p>
  <p><small>container hostname: {socket.gethostname()}</small></p>
</body></html>"""


class Hello(BaseHTTPRequestHandler):
    def do_GET(self):
        body = PAGE.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} - {fmt % args}", flush=True)


if __name__ == "__main__":
    print(f"python-app listening on {PORT}", flush=True)
    HTTPServer(("0.0.0.0", PORT), Hello).serve_forever()
