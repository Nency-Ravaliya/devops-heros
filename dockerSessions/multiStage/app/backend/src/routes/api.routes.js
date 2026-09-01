import { Router } from "express";
import { getHelloMessage, getHealthStatus } from "../controllers/message.controller.js";

const router = Router();

// Endpoint for frontend hello & status info
router.get("/hello", getHelloMessage);

// Health check endpoint for Docker / orchestration health probes
router.get("/health", getHealthStatus);

export default router;
