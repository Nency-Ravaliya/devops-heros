from http.server import BaseHTTPRequestHandler, HTTPServer


class HelloWorldHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(b"Hello World from Python!\n")


if __name__ == "__main__":
    port = 5000
    server = HTTPServer(("0.0.0.0", port), HelloWorldHandler)
    print(f"Python Hello World app listening on port {port}")
    server.serve_forever()
