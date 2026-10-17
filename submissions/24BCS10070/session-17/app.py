from http.server import BaseHTTPRequestHandler, HTTPServer
import json

def message():
    return {"message": "Hello from my DevOps pipeline", "healthy": True}

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ("/", "/health"):
            self.send_error(404)
            return
        payload = json.dumps(message()).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
