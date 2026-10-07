const http = require("http");

http.createServer((req, res) => {
  res.end("Hello World from Node.js");
}).listen(3000);