const express = require("express");

const app = express();
const PORT = 3000;

app.get("/", (req, res) => {
  res.send("<h1>Hello World from Docker Multi-Stage Build! Kavya Dhyani: 24BCS10216 </h1>");
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});