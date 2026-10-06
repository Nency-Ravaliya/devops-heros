// Re-implementation of the Kubernetes Basics tutorial "kubernetes-bootcamp" app.
// The upstream image is amd64-only; this one is built natively for arm64 (Apple Silicon kind nodes).
var http = require('http');
var requests = 0;
var version = process.env.APP_VERSION || '1';
var startTime;
var host;

var handleRequest = function (request, response) {
  response.setHeader('Content-Type', 'text/plain');
  response.writeHead(200);
  response.write('Hello Kubernetes bootcamp! | Running on: ');
  response.write(host);
  response.end(' | v=' + version + '\n');
  console.log('Running On:', host, '| Total Requests:', ++requests,
    '| App Uptime:', (new Date() - startTime) / 1000, 'seconds', '| Log Time:', new Date());
};

// node as PID 1 ignores SIGTERM by default -> pod would wait the full 30s grace period.
process.on('SIGTERM', function () { console.log('SIGTERM received, shutting down'); process.exit(0); });

var www = http.createServer(handleRequest);
www.listen(8080, function () {
  startTime = new Date();
  host = process.env.HOSTNAME;
  console.log('Kubernetes Bootcamp App Started At:', startTime, '| Running On: ', host, '\n');
});
