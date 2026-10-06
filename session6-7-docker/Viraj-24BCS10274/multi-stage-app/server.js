const http = require("http");

const body = "<h1>Hello World from Docker multi-stage build</h1><p>Viraj Bhanage, 24BCS10274</p>";
const server = http.createServer((_req, res) => {
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(body);
});

server.listen(8080, "0.0.0.0", () => {
  console.log("multi-stage app listening on 8080");
});
