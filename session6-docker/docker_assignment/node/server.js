const http = require('http');

http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end('<h1>Hello world from Node js server</h1>');
}).listen(3000, () => console.log('Node server running on 3000'));