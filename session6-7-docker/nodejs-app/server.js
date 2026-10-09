const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Node.js Docker Demo</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0f172a; color: #f8fafc; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
          .card { background: #1e293b; padding: 2.5rem; border-radius: 1rem; box-shadow: 0 10px 25px rgba(0,0,0,0.5); text-align: center; border: 1px solid #334155; }
          h1 { color: #38bdf8; margin-bottom: 0.5rem; }
          p { color: #94a3b8; font-size: 1.1rem; }
          .badge { background: #0284c7; color: white; padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.875rem; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>Hello World from Node.js!</h1>
          <p>Running inside Docker Container</p>
          <span class="badge">Port: ${PORT}</span>
        </div>
      </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Node.js server listening on port ${PORT}`);
});
