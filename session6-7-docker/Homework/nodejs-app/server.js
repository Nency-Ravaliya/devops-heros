const http = require("http");

const PORT = 3001;

const server = http.createServer((req, res) => {
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end("<h1>Hello World from Node.js!</h1>");
});

server.listen(PORT, "0.0.0.0", () => {
    console.log(`Node.js server running on port ${PORT}`);
});