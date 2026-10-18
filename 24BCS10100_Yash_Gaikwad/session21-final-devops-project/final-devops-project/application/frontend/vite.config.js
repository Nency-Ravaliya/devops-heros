import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// In `npm run dev` the browser talks to Vite, which forwards /api to a local backend.
// In containers the same /api path is handled by Nginx / the Kubernetes Ingress instead.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api": process.env.VITE_BACKEND_URL || "http://localhost:8000",
    },
  },
});
