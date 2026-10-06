import { createServer } from "node:http";

const PORT = Number(process.env.PORT ?? 3000);

createServer((_req, res) => {
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end("<h1>Hello World from Node.js (TypeScript, multi-stage build)!</h1>");
}).listen(PORT, () => console.log(`Node app listening on port ${PORT}`));
