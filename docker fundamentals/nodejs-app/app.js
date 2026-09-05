const http = require('http');

const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end('<h1>Hello World from Node.js!</h1>');
});

server.listen(3000, '0.0.0.0', () => {
    console.log('Node.js application running on port 3000');
});
