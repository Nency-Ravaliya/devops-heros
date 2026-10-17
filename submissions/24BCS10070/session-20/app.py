from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import time

requests = 0
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        global requests
        requests += 1
        if self.path == "/metrics":
            body = f"# HELP study_requests_total Requests handled\n# TYPE study_requests_total counter\nstudy_requests_total {requests}\n"
            content_type = "text/plain; version=0.0.4"
        elif self.path in ("/", "/health"):
            body = json.dumps({"healthy": True, "message": "Monitoring practice"})
            content_type = "application/json"
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.end_headers()
        self.wfile.write(body.encode())
        print(json.dumps({"path": self.path, "time": time.time(), "status": 200}), flush=True)

if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
