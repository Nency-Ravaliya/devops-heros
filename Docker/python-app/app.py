from http.server import HTTPServer, BaseHTTPRequestHandler

class Server(BaseHTTPRequestHandler):
    def do_GET(self):
        message = "Hello from Python!"

        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()

        self.wfile.write(message.encode())

server = HTTPServer(("0.0.0.0", 80), Server)

print("Python server running on port 80")
server.serve_forever()