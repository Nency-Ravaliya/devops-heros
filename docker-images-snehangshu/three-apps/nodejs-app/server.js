const http = require('http');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`<!doctype html>
<html>
  <head><title>Node.js on Docker</title></head>
  <body>
    <h1>Hello World from Node.js!</h1>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
    <p>Served by Node ${process.version} in container ${require('os').hostname()}</p>
  </body>
</html>`);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Node.js app listening on port ${PORT}`);
});
