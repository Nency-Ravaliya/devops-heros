const http = require('node:http');
http.createServer((req,res) => {res.writeHead(200, {'Content-Type':'text/html'});res.end('<h1>Hello World from Node.js</h1>');}).listen(Number(process.env.PORT || 3000), '0.0.0.0');
