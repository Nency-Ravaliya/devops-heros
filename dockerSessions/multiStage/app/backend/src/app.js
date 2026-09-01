import express from "express";
import cors from "cors";
import apiRoutes from "./routes/api.routes.js";

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Root route
app.get("/", (req, res) => {
  res.json({
    name: "Biolume API Gateway",
    version: "1.0.0",
    description: "Deep sea night diving platform API",
    endpoints: {
      hello: "/api/hello",
      health: "/api/health"
    }
  });
});

// Mount modular API routes
app.use("/api", apiRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    status: "error",
    message: `Endpoint ${req.originalUrl} not found on Biolume server`
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({
    status: "error",
    message: "An unexpected server error occurred",
    error: process.env.NODE_ENV === "production" ? undefined : err.message
  });
});

export default app;
