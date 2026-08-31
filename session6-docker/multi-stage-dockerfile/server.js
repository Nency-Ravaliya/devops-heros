const express = require("express");

const app = express();
const PORT = 3000;

app.get("/", (req, res) => {
  res.send("<h1>Narendra , RollNO : 24bcs10225!</h1>");
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});