from http.server import SimpleHTTPRequestHandler, HTTPServer

class HelloHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(b"<h1>Hello World from Python!</h1>")

server = HTTPServer(('0.0.0.0', 5000), HelloHandler)
print("Serving on port 5000...")
server.serve_forever()