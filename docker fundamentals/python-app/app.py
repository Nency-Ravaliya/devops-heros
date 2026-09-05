from http.server import BaseHTTPRequestHandler, HTTPServer

class HelloWorldHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

        message = "<h1>Hello World from Python!</h1>"
        self.wfile.write(message.encode())

server = HTTPServer(("0.0.0.0", 8000), HelloWorldHandler)

print("Python application running on port 8000")

server.serve_forever()
