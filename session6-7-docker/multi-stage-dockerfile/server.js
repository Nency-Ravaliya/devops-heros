const express = require("express");

const app = express();
const PORT = 8080;

app.get("/", (req, res) => {
  res.send("Hello World from Docker multi-stage build");
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});