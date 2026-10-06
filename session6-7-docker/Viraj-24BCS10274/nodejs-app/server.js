const express = require("express");

const app = express();
const port = process.env.PORT || 3000;

app.get("/", (_req, res) => {
  res.type("html").send("<h1>Viraj Bhanage</h1><p>Roll 24BCS10274. Node lab page.</p>");
});

app.listen(port, "0.0.0.0", () => {
  console.log(`nodejs-app listening on ${port}`);
});
