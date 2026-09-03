const http = require('http');

const server = http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.end('<h1>Hello from Node.js + Docker!</h1>');
});

server.listen(3000, '0.0.0.0', () => {
    console.log('Server running on port 3000');
});
