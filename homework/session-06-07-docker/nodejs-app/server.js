const express = require("express");

const app = express();
const port = process.env.PORT || 3000;

app.get("/", (_req, res) => {
  res.type("html").send("<h1>Hello World</h1><p>Node.js application running in Docker.</p>");
});

app.listen(port, "0.0.0.0", () => {
  console.log(`nodejs-app listening on ${port}`);
});
