const http = require("http");
const os = require("os");

const PORT = process.env.PORT || 3000;

const page = `<!doctype html>
<html><head><meta charset="utf-8"><title>Node.js Hello World</title></head>
<body style="font-family:system-ui;text-align:center;margin-top:15vh">
  <h1>Hello World</h1>
  <p>from <strong>Node.js ${process.version}</strong> running in a Docker container</p>
  <p><small>container hostname: ${os.hostname()}</small></p>
</body></html>`;

http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(page);
}).listen(PORT, "0.0.0.0", () => console.log(`nodejs-app listening on ${PORT}`));
