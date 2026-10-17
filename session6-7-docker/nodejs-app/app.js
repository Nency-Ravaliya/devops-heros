const http = require('http');

const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
        <h1>Hello World from Node.js + Docker!</h1>
        <h3>Name: Sakshi</h3>
        <h3>Roll No: 24bcs10034</h3>
    `);
});

server.listen(3000, () => {
    console.log('Server running on port 3000');
});