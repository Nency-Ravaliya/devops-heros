/**
 * Message & status controller for Biolume Core API
 */

export const getHelloMessage = (req, res) => {
  try {
    return res.status(200).json({
      status: "success",
      service: "Biolume Deep-Sea Exploration API",
      message: "Hello from Biolume Core Backend - Dive Systems Initialized.",
      timestamp: new Date().toISOString(),
      expeditionMetrics: {
        depthRange: "200m - 11,000m (Abyssal & Hadal Zones)",
        bioluminescenceLevel: "Optimal",
        activeDives: 3,
        submersibleStatus: "Nominal"
      }
    });
  } catch (error) {
    return res.status(500).json({
      status: "error",
      message: "Internal server error in message controller",
      error: error.message
    });
  }
};

export const getHealthStatus = (req, res) => {
  return res.status(200).json({
    status: "healthy",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || "development"
  });
};
