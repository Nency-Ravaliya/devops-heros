const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send("<h1>Hello World from Node.js (Express) in Docker!</h1>");
});

app.listen(PORT, () => console.log(`Node app listening on port ${PORT}`));
