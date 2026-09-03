from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = 5000


class HelloWorldHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(b"<h1>Hello World from Docker (Python)!</h1>")

    def log_message(self, format, *args):
        # keep container logs quiet/clean
        print("%s - %s" % (self.address_string(), format % args))


if __name__ == "__main__":
    print(f"Server running on port {PORT}")
    HTTPServer(("0.0.0.0", PORT), HelloWorldHandler).serve_forever()
