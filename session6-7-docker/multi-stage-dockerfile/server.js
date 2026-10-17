const http = require("http");

const server = http.createServer((req, res) => {
    res.writeHead(200, { "Content-Type": "text/html" });

    res.end(`
        <h1>Hello World from Docker Multi-Stage Build!</h1>
        <p><strong>Name:</strong> Sakshi</p>
        <p><strong>Roll No:</strong> 24bcs10034</p>
    `);
});

server.listen(8080, () => {
    console.log("Server running on port 8080");
});