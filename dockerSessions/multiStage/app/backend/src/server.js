import dotenv from "dotenv";
import app from "./app.js";

dotenv.config();

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`[Biolume API] Server active on port ${PORT}`);
  console.log(`[Biolume API] Health check at http://localhost:${PORT}/api/health`);
  console.log(`[Biolume API] Hello endpoint at http://localhost:${PORT}/api/hello`);
});
