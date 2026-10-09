from http.server import HTTPServer, BaseHTTPRequestHandler

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(b"<h1>Hello World from Python Application!</h1>")

def run(server_class=HTTPServer, handler_class=SimpleHTTPRequestHandler):
    server_address = ('', 5000)
    httpd = server_class(server_address, handler_class)
    print("Python HTTP Server running on port 5000...")
    httpd.serve_forever()

if __name__ == '__main__':
    run()