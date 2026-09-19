const http = require('http');

http.createServer((_request, response) => {
  response.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
  response.end('Hello from the Session 6 Node container.\n');
}).listen(3000, '0.0.0.0');
