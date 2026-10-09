const express = require("express");
const app = express();
const port = 3000;

app.get("/", (req, res) => {
    res.send("<h1>Hello World from Node.js Docker Application!</h1>");
})

app.listen(port, () => {
    console.log(`Server is running at port ${port}`);
})