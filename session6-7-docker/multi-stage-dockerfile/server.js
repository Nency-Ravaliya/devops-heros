const http = require('http');
const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Multi-Stage Docker Build</title>
        <style>
          body { font-family: 'Segoe UI', system-ui, sans-serif; background: #0f172a; color: #f8fafc; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
          .card { background: #1e293b; padding: 3rem; border-radius: 1.5rem; border: 2px solid #3b82f6; box-shadow: 0 25px 50px -12px rgba(59, 130, 246, 0.25); text-align: center; max-width: 500px; }
          h1 { color: #60a5fa; font-size: 2rem; margin-bottom: 1rem; }
          .badge { background: #2563eb; color: white; padding: 0.5rem 1rem; border-radius: 9999px; font-weight: bold; display: inline-block; margin-top: 1rem; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>Hello World from Docker multi-stage build</h1>
          <p>Optimized Lightweight Production Container</p>
          <div class="badge">Running on Port ${PORT}</div>
        </div>
      </body>
    </html>
  `);
});

server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
