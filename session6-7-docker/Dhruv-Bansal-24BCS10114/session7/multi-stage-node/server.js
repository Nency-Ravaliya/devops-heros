const http = require('http');

http.createServer((_request, response) => {
  response.writeHead(200, {'Content-Type': 'text/plain; charset=utf-8'});
  response.end('Hello from a multi-stage Docker image.\n');
}).listen(8081, '0.0.0.0');
