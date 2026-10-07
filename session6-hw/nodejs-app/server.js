const http = require('http');
const port = 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end('<h1>Hello World from Node.js!</h1>');
});

server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});