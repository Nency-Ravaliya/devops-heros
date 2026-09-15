const http = require('http');
const server = http.createServer((req, res) => {
  res.end('Hello from Node.js Docker App!\n');
});
server.listen(4001, () => {
  console.log('Node app running on port 4001');
});
