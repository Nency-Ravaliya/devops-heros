import dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import connect_DB from "./config/MongoDB.js";
import monastery_routes from "./routes/Monastery.routes.js";
import event_routes from "./routes/Event.routes.js";
import booking_routes from "./routes/Booking.routes.js";
import image_routes from "./routes/Image.routes.js";
import archive_routes from "./routes/Archive.routes.js";

const app = express();
const PORT = process.env.PORT || 8000;

console.log("Allowed origin: ", process.env.CLIENT_URL);
app.use(
  cors({
    origin: process.env.CLIENT_URL || "http://localhost:5173",
    credentials: true,
  })
);
app.use(express.json());

connect_DB();

app.get("/", (req, res) => {
  res.send("Home Page");
});

app.use("/api/monasteries", monastery_routes);
app.use("/api/events", event_routes);
app.use("/api/bookings", booking_routes);
app.use("/api/images", image_routes);
app.use("/api/archives", archive_routes);

app.listen(PORT, () => {
  console.log(`server is running on port ${PORT}`);
});
