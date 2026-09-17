from http.server import BaseHTTPRequestHandler, HTTPServer
class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'Hello from Python Docker App!\n')
httpd = HTTPServer(('0.0.0.0', 4002), SimpleHTTPRequestHandler)
print("Python app running on port 4002")
httpd.serve_forever()
